from __future__ import annotations
import logging
import threading
import time
import uuid
from datetime import datetime, timezone

from config import settings
from enforcement.action_executor import ActionExecutor, A0_MONITOR, A3_PERM_BLOCK, A4_A5_DDOS
from gateway import node_client
from state import ip_history_store, ewma_store, active_window_store

log = logging.getLogger("Net-Knight.approval_gateway")

# ── auto_approve — متغير عالمي، يتغير فقط عن طريق /config/auto_approve (enforcement_api.py) ──
_auto_approve_lock = threading.Lock()
_auto_approve = False


def set_auto_approve(value: bool) -> None:
    global _auto_approve
    with _auto_approve_lock:
        _auto_approve = bool(value)
    log.info(f"⚙️  auto_approve = {_auto_approve}")


def get_auto_approve() -> bool:
    with _auto_approve_lock:
        return _auto_approve


# ── (auto_approve=False) ────────────────────────────
_pending: dict[str, dict] = {}
_pending_lock = threading.Lock()



def _window_scope_ip(decision: dict) -> str:
    
    return decision["dst_ip"] if decision["action_id"] == A4_A5_DDOS else decision["src_ip"]


def _window_ttl_sec(decision: dict, enforcement_result: dict | None) -> float:
    
    action_id = decision["action_id"]
    if action_id == A0_MONITOR:
        return settings.MONITOR_ALERT_COOLDOWN_SEC
    if action_id == A3_PERM_BLOCK:
        return settings.PERM_BLOCK_WINDOW_TTL_SEC
    if enforcement_result and enforcement_result.get("duration_sec"):
        return enforcement_result["duration_sec"]
    return settings.MONITOR_ALERT_COOLDOWN_SEC  


def _open_window(decision: dict, enforcement_result: dict | None) -> None:
    active_window_store.set_window(
        _window_scope_ip(decision), decision["attack_category"], decision["action_id"],
        _window_ttl_sec(decision, enforcement_result),
    )


def _cleanup_pending() -> None:
    now = time.time()
    with _pending_lock:
        dead = [rid for rid, c in _pending.items()
                if now - c["created_at"] > settings.PENDING_REQUEST_TTL_SEC]
        for rid in dead:
            del _pending[rid]



def _describe(enforcement_result: dict | None, decision: dict) -> str:
    if enforcement_result is None:
        return f"Monitoring traffic from {decision['src_ip']} — no rule applied (A0)."

    kind = enforcement_result["kind"]
    src = decision["src_ip"]

    if kind == "temp_block":
        mins = enforcement_result["duration_sec"] // 60
        return f"Applying a temporary block on {src} for {mins} minutes"
    if kind == "perm_block":
        return f"Applying a permanent block on {src}"
    if kind == "rate_limit":
        return f"Applying a rate limit on {src} ({enforcement_result['rate']})"
    if kind == "ddos_response":
        return (
            f"Applying DDoS mitigation on destination {enforcement_result['dest_ip']} "
            f"(per-source {enforcement_result['a4_per_source_rate']}, "
            f"SYN limit {enforcement_result['a5_syn_rate']})"
        )
    return f"Applying mitigation on {src}"


def _collect_deletions(enforcement_result: dict | None) -> list[dict]:
    
    if not enforcement_result:
        return []
    items = []
    primary = enforcement_result.get("deletion")
    if primary:
        items.append({"label": enforcement_result.get("kind", "primary"), **primary})
    syn = enforcement_result.get("deletion_syn")
    if syn:
        items.append({"label": "ddos_syn_limit", **syn})
    return items


def _build_alert_payload(ai_response: dict, decision: dict, enforcement_result: dict | None,
                          request_id: str, include_handle: bool) -> dict:
    meta = ai_response["flow_metadata"]
    mitigation = ai_response["mitigation"]
    deletion = (enforcement_result or {}).get("deletion") if enforcement_result else None

    payload = {
        "request_id": request_id,
        "description": _describe(enforcement_result, decision),
        "explanation": ai_response["explanation"]["summary"],   
        "explanation_details": ai_response["explanation"],       
        "attack_type": ai_response["detection"]["attack_type"],
        "confidence": ai_response["detection"]["confidence"],
        "severity": ai_response["severity"],
        "action": mitigation["action_name"],
        "time": meta["timestamp"],
        "rule": {
            "family": settings.NFT_FAMILY,
            "table": settings.NFT_TABLE,
            "chain": (deletion or {}).get("chain"),   
            "set": (deletion or {}).get("set"),        
            "src_ip": decision["src_ip"],
            "dest_ip": decision["dst_ip"],
            "port": decision.get("dst_port"),
            "timeout": (enforcement_result or {}).get("duration_sec"),
            "rate_limit": (enforcement_result or {}).get("rate"),
        },
    }
    if include_handle and deletion is not None:
        payload["rule"]["handle_id"] = deletion.get("handle")     
        payload["rule"]["deletion"] = deletion                     
        payload["rule"]["deletions"] = _collect_deletions(enforcement_result)  
    return payload



def handle_decision(ai_response: dict, executor: ActionExecutor) -> None:
    meta = ai_response["flow_metadata"]
    mitigation = ai_response["mitigation"]
    net_snap = ai_response["network_snapshot"]

    decision = {
        "action_id": mitigation["action_id"],
        "attack_category": mitigation["attack_category"],
        "ids_confirmed": mitigation["ids_confirmed"],
        "anomaly_flag": mitigation["anomaly_flag"],
        "src_ip": meta["src_ip"],
        "dst_ip": meta["dst_ip"],
        "dst_port": meta["dst_port"],
        "unique_sources": net_snap["unique_sources"],
    }

    ip_history_store.record_decision(decision["src_ip"], decision["attack_category"], mitigation["action_name"])

    if decision["action_id"] != 0 and settings.is_internal_ip(decision["dst_ip"]):
        ewma_store.raise_attack_flag(decision["dst_ip"])

    request_id = str(uuid.uuid4())

    if get_auto_approve():
        enforcement_result = executor.execute(decision)
        _open_window(decision, enforcement_result)
        payload = _build_alert_payload(ai_response, decision, enforcement_result, request_id, include_handle=True)
        node_client.send_alert(payload)
        return

    with _pending_lock:
        _pending[request_id] = {
            "ai_response": ai_response,
            "decision": decision,
            "created_at": time.time(),
        }
    _cleanup_pending()

    
    active_window_store.set_window(
        _window_scope_ip(decision), decision["attack_category"], decision["action_id"],
        settings.PENDING_ALERT_COOLDOWN_SEC,
    )

    
    preview = executor.execute(decision, dry_run=True)
    payload = _build_alert_payload(ai_response, decision, preview, request_id, include_handle=False)
    node_client.send_alert(payload)



def handle_approve(request_id: str, executor: ActionExecutor) -> dict | None:
    with _pending_lock:
        case = _pending.pop(request_id, None)
    if case is None:
        log.warning(f"approve لطلب غير موجود/منتهي: {request_id}")
        return None

    enforcement_result = executor.execute(case["decision"])
    _open_window(case["decision"], enforcement_result)
    payload = _build_alert_payload(
        case["ai_response"], case["decision"], enforcement_result, request_id, include_handle=True,
    )
    log.info(f"✅ Approved & applied: {request_id} → {payload['rule'].get('handle_id')}")
    return payload


def handle_reject(request_id: str) -> bool:
    
    with _pending_lock:
        case = _pending.pop(request_id, None)
    existed = case is not None
    if existed:
        active_window_store.set_window(
            _window_scope_ip(case["decision"]), case["decision"]["attack_category"],
            case["decision"]["action_id"], settings.REJECTED_ALERT_COOLDOWN_SEC,
        )
        log.info(f"🚫 Rejected: {request_id} — لم يُطبَّق أي شيء.")
    else:
        log.warning(f"reject لطلب غير موجود/منتهي: {request_id}")
    return existed
