from __future__ import annotations
import asyncio
import json
import logging
import threading
import time
from collections import defaultdict

try:
    import websockets
except ImportError:
    websockets = None  
try:
    import psutil
except ImportError:
    psutil = None

from config import settings
from gateway import node_client

log = logging.getLogger("Net-Knight.ws_monitor")

PROTOCOL_BUCKETS = ["tls", "http", "ftp", "ssh", "tcp", "udp", "icmp", "dns", "dhcp", "other"]


def classify_protocol(l7_name: str, protocol_num: int, dst_port: int, src_port: int) -> str:
    name = (l7_name or "").lower()
    port = dst_port if dst_port not in (0, None) else src_port

    if "tls" in name or "ssl" in name or port == 443:
        return "tls"
    if "http" in name or port in (80, 8080, 8000):
        return "http"
    if "ftp" in name or port in (20, 21):
        return "ftp"
    if "ssh" in name or port == 22:
        return "ssh"
    if "dns" in name or port == 53:
        return "dns"
    if "dhcp" in name or port in (67, 68):
        return "dhcp"
    if protocol_num == 1:
        return "icmp"
    if protocol_num == 6:
        return "tcp"
    if protocol_num == 17:
        return "udp"
    return "other"


def classify_direction(src_ip: str, dst_ip: str) -> str:
    dst_internal = settings.is_internal_ip(dst_ip) or settings.is_gateway_ip(dst_ip)
    return "inbound" if dst_internal else "outbound"


class TrafficStats:
    

    def __init__(self):
        self._lock = threading.Lock()
        self._bytes = {d: defaultdict(int) for d in ("inbound", "outbound")}
        self._packets_total = 0
        self._active_connections = 0

    def record_flow(self, src_ip: str, dst_ip: str, protocol_num: int,
                     src_port: int, dst_port: int, l7_name: str,
                     total_bytes: int, total_packets: int) -> None:
        direction = classify_direction(src_ip, dst_ip)
        bucket = classify_protocol(l7_name, protocol_num, dst_port, src_port)
        with self._lock:
            self._bytes[direction][bucket] += total_bytes
            self._packets_total += total_packets

    def set_active_connections(self, n: int) -> None:
        with self._lock:
            self._active_connections = n

    def snapshot_and_reset(self) -> dict:
        with self._lock:
            snap = {
                "inbound": {k: self._bytes["inbound"].get(k, 0) for k in PROTOCOL_BUCKETS},
                "outbound": {k: self._bytes["outbound"].get(k, 0) for k in PROTOCOL_BUCKETS},
                "packets_per_second": self._packets_total,
                "active_connections": self._active_connections,
            }
            self._bytes = {d: defaultdict(int) for d in ("inbound", "outbound")}
            self._packets_total = 0
            return snap


def _system_usage() -> tuple[float, float]:
    if psutil is None:
        return 0.0, 0.0
    return psutil.cpu_percent(interval=None), psutil.virtual_memory().percent


class WsMonitor:
    def __init__(self, stats: TrafficStats):
        self.stats = stats
        self._stop = threading.Event()
        self._last_bandwidth_alert = 0.0

    async def run(self) -> None:
        if websockets is None:
            log.error("[FATAL] مكتبة websockets مش متثبتة. pip install websockets")
            return
        if "REPLACE" in settings.WS_NODE_URL:
            log.warning("WS_NODE_URL لسه placeholder — WebSocket monitor مش هيشتغل لحد ما تظبطيه.")

        while not self._stop.is_set():
            try:
                async with websockets.connect(settings.WS_NODE_URL) as ws:
                    log.info(f"✅ WebSocket متصل بـ Node: {settings.WS_NODE_URL}")
                    while not self._stop.is_set():
                        await self._push_once(ws)
                        await asyncio.sleep(settings.WS_PUSH_INTERVAL_SEC)
            except Exception as e:
                log.error(f"WebSocket connection error: {e} — إعادة محاولة بعد 5 ثواني")
                await asyncio.sleep(5)

    async def _push_once(self, ws) -> None:
        snap = self.stats.snapshot_and_reset()
        cpu, mem = _system_usage()

        payload = {
            "inbound": snap["inbound"],
            "outbound": snap["outbound"],
            "cpu_usage": cpu,
            "memory_usage": mem,
            "packets_per_second": snap["packets_per_second"],
            "active_connections": snap["active_connections"],
            "timestamp": time.time(),
        }
        await ws.send(json.dumps(payload))

        self._check_bandwidth(snap)

    def _check_bandwidth(self, snap: dict) -> None:
        total_bytes = sum(snap["inbound"].values()) + sum(snap["outbound"].values())
        # bytes/sec → bits/sec → Mbps
        mbps = (total_bytes * 8) / 1_000_000 / settings.WS_PUSH_INTERVAL_SEC
        usage_pct = (mbps / settings.NETWORK_CAPACITY_MBPS) * 100 if settings.NETWORK_CAPACITY_MBPS else 0

        if usage_pct >= settings.BANDWIDTH_ALERT_THRESHOLD_PCT:
            now = time.time()
            if now - self._last_bandwidth_alert >= settings.BANDWIDTH_ALERT_COOLDOWN_SEC:
                node_client.send_bandwidth_alert(usage_pct)
                self._last_bandwidth_alert = now

    def stop(self) -> None:
        self._stop.set()
