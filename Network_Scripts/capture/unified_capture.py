from __future__ import annotations
import argparse
import asyncio
import ipaddress
import logging
import os
import sys
import threading
import time
from collections import deque
import aiohttp
try:
    from nfstream import NFStreamer, NFPlugin
except ImportError:
    print("[FATAL] nfstream not installed. pip install nfstream")
    sys.exit(1)

import sys as _sys
import os as _os
_sys.path.insert(0, _os.path.dirname(_os.path.dirname(_os.path.abspath(__file__))))  # جذر Network_Scripts
from config import settings

# ══════════════════════════════════════════════════════════════════════════════
IDLE_TIMEOUT_SEC = 5
ACTIVE_TIMEOUT_SEC = 10
BPF_FILTER_BASE = "ip and (tcp or udp or icmp)"
WAN_INTERFACE = settings.WAN_INTERFACE
LAN_INTERFACE = settings.LAN_INTERFACE
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)]
)
log = logging.getLogger("Net-Knight-Unified-Sensor")
CDN_WHITELIST_FILE = "cdn_whitelist.txt"
# ══════════════════════════════════════════════════════════════════════════════


def load_whitelist(path: str = CDN_WHITELIST_FILE) -> set:
    networks: set = set()
    if not os.path.exists(path):
        log.warning(f"⚠️  Whitelist file not found: {path} — CDN filtering disabled")
        return networks
    try:
        with open(path) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                try:
                    networks.add(ipaddress.IPv4Network(line, strict=False))
                except ValueError as e:
                    log.warning(f"⚠️  Invalid CIDR in whitelist: '{line}' — {e}")
        log.info(f"✅ CDN whitelist loaded: {len(networks)} CIDR ranges from '{path}'")
    except Exception as e:
        log.error(f"❌ Failed to load whitelist: {e}")
    return networks


def is_whitelisted(ip_str: str, whitelist: set, dst_ip: str = "") -> bool:

    if not whitelist:
        return False
    for ip_candidate in filter(None, [ip_str, dst_ip]):
        try:
            ip = ipaddress.IPv4Address(ip_candidate)
            if any(ip in net for net in whitelist):
                return True
        except ValueError:
            pass
    return False


def _parse_ttl_and_win(ip_packet: bytes, protocol: int):

    ttl = 0
    win = 0
    try:
        if not ip_packet or len(ip_packet) < 20:
            return ttl, win
        if (ip_packet[0] & 0xF0) != 0x40:
            return ttl, win
        ttl = ip_packet[8]
        if protocol == 6:
            ihl = (ip_packet[0] & 0x0F) * 4
            tcp_start = ihl
            if len(ip_packet) >= tcp_start + 16:
                b1, b2 = ip_packet[tcp_start + 14], ip_packet[tcp_start + 15]
                win_be = (b1 << 8) | b2
                win_le = (b2 << 8) | b1
                win = max(win_be, win_le)
    except Exception:
        pass
    return ttl, win


class CapturePlugin(NFPlugin):
    
    def on_init(self, packet, flow):
        # -- IDS fields:--
        flow.udps.tcp_flags_combined = 0
        flow.udps.src_min_ttl = 255
        flow.udps.tcp_win_max_in = 0
        # -- Anomaly-only fields:--
        flow.udps.src_max_ttl = 0
        flow.udps.server_tcp_flags = 0
        self.on_update(packet, flow)

    def on_update(self, packet, flow):
       
        if hasattr(packet, 'ip_ttl') and packet.ip_ttl is not None:
            ttl_old = int(packet.ip_ttl)
            if ttl_old < flow.udps.src_min_ttl:
                flow.udps.src_min_ttl = ttl_old

        if packet.protocol == 6:
            p_flags = getattr(packet, 'tcp_flags', 0)
            if p_flags == 0:
                p_flags = (
                    (2 if getattr(packet, 'syn', False) else 0) |
                    (16 if getattr(packet, 'ack', False) else 0) |
                    (4 if getattr(packet, 'rst', False) else 0) |
                    (1 if getattr(packet, 'fin', False) else 0) |
                    (8 if getattr(packet, 'psh', False) else 0)
                )
            flow.udps.tcp_flags_combined |= p_flags

            # server flags: direction=1  (for Anomaly)
            if getattr(packet, 'direction', -1) == 1:
                flow.udps.server_tcp_flags |= p_flags

        if packet.direction == 0:
            win_old = getattr(packet, "tcp_window", 0) or 0
            if win_old > flow.udps.tcp_win_max_in:
                flow.udps.tcp_win_max_in = int(win_old)

        # ═══ Anomaly-only — MAX_TTL  raw byte parsing  ═══
        ip_pkt = getattr(packet, 'ip_packet', None)
        proto = getattr(packet, 'protocol', 0)
        ttl_raw, _ = _parse_ttl_and_win(ip_pkt, proto)
        if ttl_raw > 0 and ttl_raw > flow.udps.src_max_ttl:
            flow.udps.src_max_ttl = ttl_raw


def extract_raw_features(flow) -> dict:
    """
   For API include all fields required for IDS and Anomaly
    """
    udps = getattr(flow, "udps", None)
    dur_ms = float(flow.bidirectional_duration_ms or 0)
    in_pkts = float(flow.src2dst_packets or 0)
    out_pkts = float(flow.dst2src_packets or 0)
    tcp_flags = float(getattr(udps, "tcp_flags_combined", 0) if udps else 0)
    if dur_ms <= 0.1 and in_pkts + out_pkts <= 3 and tcp_flags == 2:
        dur_ms = 1.0

    shortest = float(flow.src2dst_min_ps or 60)
    longest = float(flow.src2dst_max_ps or shortest)

    return {
        # ── For two models────────────────────────────────────
        "IN_BYTES": float(flow.src2dst_bytes or 0),
        "OUT_BYTES": float(flow.dst2src_bytes or 0),
        "IN_PKTS": in_pkts,
        "OUT_PKTS": out_pkts,
        "FLOW_DURATION_MILLISECONDS": dur_ms,
        "PROTOCOL": int(flow.protocol or 0),
        "L4_DST_PORT": int(flow.dst_port or 0),
        "L7_PROTO": int(getattr(flow, "application_id", 0) or 0),
        "TCP_FLAGS": tcp_flags,
        "SHORTEST_FLOW_PKT": shortest,
        "LONGEST_FLOW_PKT": longest,
        "TCP_WIN_MAX_IN": float(getattr(udps, "tcp_win_max_in", 0) if udps else 0),

        # ── IDS only ────────────────────────
        "MIN_TTL": float(getattr(udps, "src_min_ttl", 64) if udps else 64),

        # ── for Anomaly only ─────────────────────
        "MAX_TTL": float(getattr(udps, "src_max_ttl", 0) if udps else 0),
        "SERVER_TCP_FLAGS": float(getattr(udps, "server_tcp_flags", 0) if udps else 0),
        "MAX_IP_PKT_LEN": longest,
        "MIN_IP_PKT_LEN": shortest,
    }



# ══════════════════════════════════════════════════════════════════════════════
FLOW_TTL_SEC = 15.0

class RingBuffer:
    def __init__(self, maxlen: int):
        self._buf = deque(maxlen=maxlen)
        self._lock = threading.Lock()
        self._not_empty = threading.Condition(self._lock)

    def put(self, item: dict):
        item["_enqueued_at"] = time.monotonic()
        with self._not_empty:
            self._buf.append(item)
            self._not_empty.notify()

    def get_batch(self, max_items: int) -> list[dict]:
        with self._not_empty:
            if not self._buf:
                self._not_empty.wait(timeout=0.05)
            batch = []
            now = time.monotonic()
            dropped = 0
            while self._buf and len(batch) < max_items:
                item = self._buf.popleft()
                age = now - item.pop("_enqueued_at", now)
                if age > FLOW_TTL_SEC:
                    dropped += 1
                    continue
                batch.append(item)
            if dropped:
                log.debug(f"Dropped {dropped} stale flows (age > {FLOW_TTL_SEC}s)")
            return batch


class FlowDeduplicator:
    def __init__(self, ttl_sec: float = 60.0):
        self._cache = {}
        self._lock = threading.Lock()
        self._ttl = ttl_sec

        self._stop_event = threading.Event()
        threading.Thread(
            target=self._background_cleanup,
            daemon=True,
            name="flowdedup-cleanup"
        ).start()

    def _background_cleanup(self):
        while not self._stop_event.wait(timeout=60):
            now = time.monotonic()
            with self._lock:
                dead = [fid for fid, ts in self._cache.items()
                        if now - ts >= self._ttl]
                for fid in dead:
                    del self._cache[fid]
            if dead:
                log.debug(f"FlowDedup cleanup: removed {len(dead)} expired entries")

    def stop(self):
        self._stop_event.set()

    def is_duplicate(self, fid: str) -> bool:
        now = time.monotonic()
        with self._lock:
            if fid in self._cache and (now - self._cache[fid] < self._ttl):
                return True
            self._cache[fid] = now
            return False


ALERT_SUPPRESS_SEC = 10.0

class AlertDeduplicator:
    
    def __init__(self, suppress_sec: float = ALERT_SUPPRESS_SEC):
        self._seen: dict[str, float] = {}
        self._lock = threading.Lock()
        self._suppress = suppress_sec

    def should_alert(self, src_ip: str, tag: str) -> bool:
        key = f"{src_ip}|{tag}"
        now = time.monotonic()
        with self._lock:
            last = self._seen.get(key)
            if last is None or (now - last) >= self._suppress:
                self._seen[key] = now
                return True
            return False


# ══════════════════════════════════════════════════════════════════════════════
def capture_worker(iface, ring, deduplicator, stop_event, whitelist: set):
    try:
        streamer = NFStreamer(
            source=iface,
            bpf_filter=BPF_FILTER_BASE,
            udps=CapturePlugin(),
            idle_timeout=IDLE_TIMEOUT_SEC,
            active_timeout=ACTIVE_TIMEOUT_SEC,
            statistical_analysis=True
        )
        for flow in streamer:
            if stop_event.is_set():
                break

        
            if is_whitelisted(flow.src_ip, whitelist, flow.dst_ip):
                log.debug(f"⬜ Whitelisted flow: {flow.src_ip} → {flow.dst_ip} skipped")
                continue

            raw = extract_raw_features(flow)
            fid = f"{flow.src_ip}|{flow.dst_ip}|{flow.src_port}|{flow.dst_port}|{flow.protocol}"
            if not deduplicator.is_duplicate(fid):
                meta = {
                    "src_ip": flow.src_ip,
                    "dst_ip": flow.dst_ip,
                    "src_port": flow.src_port,
                    "dst_port": flow.dst_port,
                    "protocol": flow.protocol,
                    "l7": flow.application_name
                }
                ring.put({"features": raw, "metadata": meta})
    except Exception as e:
        log.error(f"Capture error on {iface}: {e}")

