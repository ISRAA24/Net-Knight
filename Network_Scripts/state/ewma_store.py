from __future__ import annotations
import logging
import threading
import time

from state.redis_client import get_client
from state.pps_tracker import PpsTracker
from config import settings

log = logging.getLogger("Net-Knight.ewma")


def _ewma_key(ip: str) -> str:
    return f"ewma:{ip}"


def _attack_flag_key(ip: str) -> str:
    return f"attack_last_seen:{ip}"


def get_baseline(ip: str) -> float | None:
    r = get_client()
    val = r.get(_ewma_key(ip))
    return float(val) if val is not None else None


def is_attack_flag_active(ip: str) -> bool:
    r = get_client()
    last_seen = r.get(_attack_flag_key(ip))
    if last_seen is None:
        return False
    return (time.time() - float(last_seen)) < settings.EWMA_ATTACK_STABILIZE_SEC


def raise_attack_flag(ip: str) -> None:
    r = get_client()
    r.set(_attack_flag_key(ip), time.time(), ex=settings.EWMA_ATTACK_STABILIZE_SEC + 60)


def update(ip: str, current_pps: float) -> float:
    
    r = get_client()
    prev = get_baseline(ip)

    if prev is None:
        
        r.set(_ewma_key(ip), current_pps, ex=settings.EWMA_TTL_SEC)
        return current_pps

    if is_attack_flag_active(ip):
        log.debug(f"EWMA[{ip}]: attack flag active — تخطي التحديث، استخدام آخر قيمة آمنة ({prev})")
        return prev

    if current_pps > settings.EWMA_SPIKE_GUARD_MULTIPLIER * prev:
        log.debug(f"EWMA[{ip}]: spike guard ({current_pps} > 2×{prev}) — تخطي هذه الدورة")
        return prev

    new_val = settings.EWMA_ALPHA * current_pps + (1 - settings.EWMA_ALPHA) * prev
    r.set(_ewma_key(ip), new_val, ex=settings.EWMA_TTL_SEC)
    return new_val


def pressure_ratio(ip: str, current_pps: float) -> float:
    
    baseline = get_baseline(ip)
    if baseline is None or baseline <= 0:
        return 1.0
    return current_pps / baseline


class EwmaUpdater:
    

    def __init__(self, pps_tracker: PpsTracker, tracked_ips_provider):
        
        self._pps = pps_tracker
        self._get_ips = tracked_ips_provider
        self._stop = threading.Event()
        self._thread = threading.Thread(target=self._loop, daemon=True, name="ewma-updater")

    def start(self) -> None:
        self._thread.start()
        log.info(f"✅ EWMA updater started (كل {settings.EWMA_UPDATE_INTERVAL_SEC}s)")

    def _loop(self) -> None:
        while not self._stop.wait(settings.EWMA_UPDATE_INTERVAL_SEC):
            for ip in list(self._get_ips()):
                rate = self._pps.get_rate(ip)
                update(ip, rate)

    def stop(self) -> None:
        self._stop.set()
