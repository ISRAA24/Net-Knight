from __future__ import annotations
import logging

from state.redis_client import get_client
from config import settings

log = logging.getLogger("Net-Knight.ip_history")

_ZERO_RECORD = {f: 0 for f in settings.IP_HISTORY_ATTACK_FIELDS}
_ZERO_RECORD["total_appearances"] = 0
_ZERO_RECORD["last_action"] = "none"


def _key(ip: str) -> str:
    return f"ip_history:{ip}"


def get_for_state(ip: str) -> dict:
    
    r = get_client()
    key = _key(ip)
    if not r.exists(key):
        r.hset(key, mapping=_ZERO_RECORD)
        r.expire(key, settings.IP_HISTORY_TTL_SEC)
        return {
            "total_appearances": 0,
            "attack_counts": {f: 0 for f in settings.IP_HISTORY_ATTACK_FIELDS},
            "last_action": "none",
        }

    raw = r.hgetall(key)
    attack_counts = {f: int(raw.get(f, 0)) for f in settings.IP_HISTORY_ATTACK_FIELDS}
    return {
        "total_appearances": int(raw.get("total_appearances", 0)),
        "attack_counts": attack_counts,
        "last_action": raw.get("last_action", "none"),
    }


def record_decision(ip: str, attack_category: str, action_name: str) -> None:
    
    r = get_client()
    key = _key(ip)

    field = attack_category if attack_category in settings.IP_HISTORY_ATTACK_FIELDS else "anomaly"

    pipe = r.pipeline()
    pipe.hincrby(key, "total_appearances", 1)
    pipe.hincrby(key, field, 1)
    pipe.hset(key, "last_action", action_name)
    pipe.expire(key, settings.IP_HISTORY_TTL_SEC)
    pipe.execute()
    log.debug(f"ip_history updated: {ip} → {field} += 1, last_action={action_name}")


def get_raw(ip: str) -> dict | None:
    r = get_client()
    key = _key(ip)
    if not r.exists(key):
        return None
    return r.hgetall(key)
