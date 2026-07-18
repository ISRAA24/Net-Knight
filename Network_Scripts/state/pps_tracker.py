from __future__ import annotations
import threading
import time
from collections import defaultdict


class PpsTracker:
    def __init__(self, window_seconds: float = 5.0):
        self.window_seconds = window_seconds
        self._counters: dict[str, int] = defaultdict(int)
        self._rates: dict[str, float] = {}
        self._lock = threading.Lock()
        self._stop = threading.Event()
        self._thread = threading.Thread(target=self._loop, daemon=True, name="pps-tracker")
        self._thread.start()

    def record(self, ip: str, packet_count: float) -> None:
        if packet_count <= 0:
            return
        with self._lock:
            self._counters[ip] += packet_count

    def _loop(self) -> None:
        while not self._stop.wait(self.window_seconds):
            with self._lock:
                snapshot = dict(self._counters)
                self._counters.clear()
            for ip, count in snapshot.items():
                self._rates[ip] = count / self.window_seconds
            
    def get_rate(self, ip: str) -> float:
        return self._rates.get(ip, 0.0)

    def stop(self) -> None:
        self._stop.set()
