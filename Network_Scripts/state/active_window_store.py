from __future__ import annotations
import time

from state.redis_client import get_client
from config import settings

_ATTACK_CATEGORIES = set(settings.IP_HISTORY_ATTACK_FIELDS)  # dos/ddos/brute_force/.../anomaly


def _key(scope_ip: str, attack_category: str) -> str:
    return f"active_window:{scope_ip}:{attack_category}"


def get_window(scope_ip: str, attack_category: str) -> dict | None:
    
    r = get_client()
    raw = r.hgetall(_key(scope_ip, attack_category))
    if not raw:
        return None
    try:
        return {"action_id": int(raw.get("action_id", 0)), "expires_at": float(raw.get("expires_at", 0))}
    except (TypeError, ValueError):
        return None


def set_window(scope_ip: str, attack_category: str, action_id: int, ttl_sec: float) -> None:
    
    ttl_sec = max(1, int(round(ttl_sec)))
    key = _key(scope_ip, attack_category)
    r = get_client()
    pipe = r.pipeline()
    pipe.hset(key, mapping={"action_id": action_id, "expires_at": time.time() + ttl_sec})
    pipe.expire(key, ttl_sec)
    pipe.execute()


def clear_window(scope_ip: str, attack_category: str) -> None:
    get_client().delete(_key(scope_ip, attack_category))


def get_relevant_windows(src_ip: str, dst_ip: str) -> dict:
    
    now = time.time()
    out: dict[str, dict] = {}

    for cat in _ATTACK_CATEGORIES:
        w = get_window(src_ip, cat)
        if w and w["expires_at"] > now:
            out[cat] = w

    ddos_dst_w = get_window(dst_ip, "ddos")
    if ddos_dst_w and ddos_dst_w["expires_at"] > now:
        if "ddos" not in out or ddos_dst_w["expires_at"] > out["ddos"]["expires_at"]:
            out["ddos"] = ddos_dst_w

    return out
