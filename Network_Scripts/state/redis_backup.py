from __future__ import annotations
import json
import logging
import os
import threading
import time

from state.redis_client import get_client
from config import settings

log = logging.getLogger("Net-Knight.redis_backup")


def backup_now(path: str = settings.REDIS_BACKUP_FILE) -> int:
    r = get_client()
    snapshot = {"ewma": {}, "ip_history": {}, "saved_at": time.time()}

    for key in r.scan_iter(match="ewma:*"):
        snapshot["ewma"][key] = r.get(key)

    for key in r.scan_iter(match="ip_history:*"):
        snapshot["ip_history"][key] = r.hgetall(key)

    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp_path = path + ".tmp"
    with open(tmp_path, "w") as f:
        json.dump(snapshot, f)
    os.replace(tmp_path, path)  
    n = len(snapshot["ewma"]) + len(snapshot["ip_history"])
    log.info(f"💾 Redis backup saved ({n} keys) → {path}")
    return n


def restore_from_backup(path: str = settings.REDIS_BACKUP_FILE) -> int:
    
    if not os.path.exists(path):
        log.info("لا يوجد ملف backup سابق — بداية نظيفة.")
        return 0

    r = get_client()
    with open(path) as f:
        snapshot = json.load(f)

    restored = 0
    for key, value in snapshot.get("ewma", {}).items():
        if value is not None:
            r.set(key, value)
            restored += 1

    for key, fields in snapshot.get("ip_history", {}).items():
        if fields:
            r.hset(key, mapping=fields)
            r.expire(key, settings.IP_HISTORY_TTL_SEC)  # تجديد TTL بعد الاسترجاع
            restored += 1

    log.info(f"♻️  استرجاع {restored} مفتاح من backup محفوظ في {path}")
    return restored


class RedisBackupScheduler:
    def __init__(self, interval_sec: float = settings.REDIS_BACKUP_INTERVAL_SEC,
                 path: str = settings.REDIS_BACKUP_FILE):
        self.interval = interval_sec
        self.path = path
        self._stop = threading.Event()
        self._thread = threading.Thread(target=self._loop, daemon=True, name="redis-backup")

    def start(self) -> None:
        self._thread.start()
        log.info(f"✅ Redis backup scheduler started (كل {self.interval}s → {self.path})")

    def _loop(self) -> None:
        while not self._stop.wait(self.interval):
            try:
                backup_now(self.path)
            except Exception as e:
                log.error(f"❌ Redis backup failed: {e}")

    def stop(self) -> None:
        self._stop.set()
