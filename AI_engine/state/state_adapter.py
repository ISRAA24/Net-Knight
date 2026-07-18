from __future__ import annotations

from decision.rl_inference import IPHistory, NetworkState, ATTACK_NAMES


# ══════════════════════════════════════════════════════════════════════════════
# IP History
# ══════════════════════════════════════════════════════════════════════════════
def attack_category(attack_type: int, ids_confirmed: bool, anomaly_flag: bool) -> str:
    
    if ids_confirmed:
        return ATTACK_NAMES.get(attack_type, "normal")
    if anomaly_flag:
        return "anomaly"
    return "normal"


def _parse_action(raw) -> int:
    if raw is None:
        return -1
    s = str(raw).strip().lower()
    if s in ("none", "", "null", "n/a"):
        return -1
    if s.startswith("a") and s[1:].isdigit():
        n = int(s[1:])
        return n if 0 <= n <= 4 else -1
    return -1


def build_ip_history(
    history_payload: dict | None,
    current_attack_type: int,
    ids_confirmed: bool,
    anomaly_flag: bool,
) -> IPHistory:
    
    if not history_payload:
        return IPHistory() 

    total = int(history_payload.get("total_appearances", 0))
    counts = history_payload.get("attack_counts", {}) or {}

    key = attack_category(current_attack_type, ids_confirmed, anomaly_flag)
    same_count = int(counts.get(key, 0))

    last_action = _parse_action(history_payload.get("last_action"))

    return IPHistory(
        repeat_count=total,
        same_attack_count=same_count,
        last_attack_type=current_attack_type,   
        was_blocked=(last_action not in (-1, 0)),
        last_action=last_action,
        block_count=0,   
    )


# ══════════════════════════════════════════════════════════════════════════════
# Network State
# ══════════════════════════════════════════════════════════════════════════════
def build_network_state(
    network_payload: dict | None,
    unique_sources: int,
    conns_active_dest: int,
    dest_new_conn_rate: float,
) -> NetworkState:
    
    payload = network_payload or {}
    return NetworkState(
        dest_pressure_ratio=float(payload.get("dest_pressure_ratio", 1.0)),
        dest_new_conn_rate=dest_new_conn_rate,
        conns_active_dest=conns_active_dest,
        unique_sources=unique_sources,
        bandwidth_util=float(payload.get("bandwidth_util", 0.0)),
        cpu_load=float(payload.get("cpu_load", 0.0)),
    )
