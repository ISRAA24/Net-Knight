from __future__ import annotations
import heapq
import logging
import threading
import time

from enforcement import nft_rules

log = logging.getLogger("Net-Knight.rule_scheduler")


class RuleScheduler:
    def __init__(self):
        self._heap: list[tuple[float, dict]] = []
        self._lock = threading.Lock()
        self._wake = threading.Condition(self._lock)
        self._stop = threading.Event()
        self._thread = threading.Thread(target=self._loop, daemon=True, name="rule-scheduler")

    def start(self) -> None:
        self._thread.start()
        log.info("✅ Rule scheduler started")

    def schedule_deletion(self, deletion: dict, after_sec: float) -> None:
        expire_at = time.time() + after_sec
        with self._wake:
            heapq.heappush(self._heap, (expire_at, deletion))
            self._wake.notify()

    def _loop(self) -> None:
        with self._wake:
            while not self._stop.is_set():
                if not self._heap:
                    self._wake.wait(timeout=5)
                    continue
                expire_at, deletion = self._heap[0]
                now = time.time()
                if expire_at > now:
                    self._wake.wait(timeout=min(expire_at - now, 5))
                    continue
                heapq.heappop(self._heap)
                self._lock.release()
                try:
                    ok = nft_rules.delete_rule(deletion)
                    log.info(f"⏰ Rule expired & removed: {deletion} (ok={ok})")
                except Exception as e:
                    log.error(f"فشل حذف قاعدة منتهية: {deletion} — {e}")
                finally:
                    self._lock.acquire()

    def stop(self) -> None:
        self._stop.set()
        with self._wake:
            self._wake.notify()
