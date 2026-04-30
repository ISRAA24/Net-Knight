from __future__ import annotations
import argparse
import asyncio
import logging
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

# ══════════════════════════════════════════════════════════════════════════════
IDLE_TIMEOUT_SEC   = 5
ACTIVE_TIMEOUT_SEC = 10
BPF_FILTER_BASE    = "ip and (tcp or udp or icmp)"
WAN_INTERFACE      = "ens33"
LAN_INTERFACE      = "ens37"
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)]
)
log = logging.getLogger("Net-Knight-Sensor-v5.2")
# ══════════════════════════════════════════════════════════════════════════════

def _parse_ttl_and_win(ip_packet: bytes, protocol: int):
    """
    بتقرأ TTL و TCP Window من الـ raw IP packet bytes مباشرة.

    IP header:
      byte 8  = TTL
      byte 9  = Protocol
      bytes 20+ = TCP header (لو Protocol=6)

    TCP header (يبدأ بعد الـ IP header):
      bytes 0-1  = src port
      bytes 2-3  = dst port
      bytes 12   = data offset (header length)
      bytes 14-15 = window size

    ip_size مش موجود كـ attribute مباشر في بعض الـ versions —
    بنجيبه من len(ip_packet).
    """
    ttl = 0
    win = 0
    try:
        if ip_packet and len(ip_packet) >= 20:
            ttl = ip_packet[8]
            # TCP window
            if protocol == 6:
                ihl = (ip_packet[0] & 0x0F) * 4  # IP header length
                tcp_start = ihl
                if len(ip_packet) >= tcp_start + 16:
                    win = (ip_packet[tcp_start + 14] << 8) | ip_packet[tcp_start + 15]
    except Exception:
        pass
    return ttl, win


class CapturePlugin(NFPlugin):
    """
    بيجمع الـ custom fields من الـ raw packet bytes.

    بعد التحقق من الـ packet attributes المتاحة في nfstream بتاعنا:
    - ip_ttl مش موجود كـ attribute → بنقرأه من ip_packet[8] مباشرة
    - tcp_window مش موجود → بنقرأه من TCP header في ip_packet
    - ip_size موجود ✅
    - syn/ack/rst/fin/psh موجودين ✅
    - direction موجود ✅
    """
    def on_init(self, packet, flow):
        flow.udps.tcp_flags_combined = 0
        flow.udps.src_min_ttl        = 255
        flow.udps.src_max_ttl        = 0
        flow.udps.tcp_win_max_in     = 0
        flow.udps.longest_flow_pkt   = 0
        flow.udps.server_tcp_flags   = 0
        self.on_update(packet, flow)

    def on_update(self, packet, flow):
        # --- TTL و TCP Window من الـ raw bytes ---
        ip_pkt = getattr(packet, 'ip_packet', None)
        proto  = getattr(packet, 'protocol', 0)
        ttl, win = _parse_ttl_and_win(ip_pkt, proto)

        if ttl > 0:
            if ttl < flow.udps.src_min_ttl:
                flow.udps.src_min_ttl = ttl
            if ttl > flow.udps.src_max_ttl:
                flow.udps.src_max_ttl = ttl

        # --- TCP Flags ---
        if proto == 6:
            p_flags = (
                (2  if getattr(packet, 'syn', False) else 0) |
                (16 if getattr(packet, 'ack', False) else 0) |
                (4  if getattr(packet, 'rst', False) else 0) |
                (1  if getattr(packet, 'fin', False) else 0) |
                (8  if getattr(packet, 'psh', False) else 0)
            )
            flow.udps.tcp_flags_combined |= p_flags

            # server flags: direction=1 فقط
            if getattr(packet, 'direction', -1) == 1:
                flow.udps.server_tcp_flags |= p_flags

            # TCP Window من الـ client فقط
            if getattr(packet, 'direction', -1) == 0 and win > flow.udps.tcp_win_max_in:
                flow.udps.tcp_win_max_in = win

        # --- Longest Packet ---
        pkt_len = getattr(packet, 'ip_size', 0) or 0
        if pkt_len > flow.udps.longest_flow_pkt:
            flow.udps.longest_flow_pkt = int(pkt_len)


def extract_raw_features(flow) -> dict:
    """
    بتستخرج الـ raw features من الـ flow.
    بترجع dict فيه كل الـ fields للموديلين مع بعض —
    كل API هياخد اللي هو محتاجه بس.
    """
    udps    = getattr(flow, 'udps', None)
    dur_ms  = float(flow.bidirectional_duration_ms or 0)
    in_pkts = float(flow.src2dst_packets or 0)
    out_pkts= float(flow.dst2src_packets or 0)
    tcp_flags = float(getattr(udps, 'tcp_flags_combined', 0) if udps else 0)

    # Fix للـ SYN flood وnmap — مش اتغير
    if dur_ms <= 0.1 and in_pkts + out_pkts <= 3 and tcp_flags == 2:
        dur_ms = 1.0

    # SHORTEST/LONGEST: موجودين في nfstream بتاعنا كـ src2dst_min/max_ps
    shortest = float(flow.src2dst_min_ps or 60)
    longest  = float(flow.src2dst_max_ps or shortest)

    # TCP_WIN_MAX_IN و MAX_TTL: مش موجودين في الـ flow object في الـ version دي
    # بنجيبهم من الـ plugin اللي بيحسبهم على مستوى الـ packet
    tcp_win = float(getattr(udps, 'tcp_win_max_in', 0) if udps else 0)
    max_ttl = float(getattr(udps, 'src_max_ttl',   0) if udps else 0)

    return {
        # ── مشتركة بين الموديلين ──────────────────────────────────────
        "IN_BYTES":                   float(flow.src2dst_bytes or 0),
        "OUT_BYTES":                  float(flow.dst2src_bytes or 0),
        "IN_PKTS":                    in_pkts,
        "OUT_PKTS":                   out_pkts,
        "FLOW_DURATION_MILLISECONDS": dur_ms,
        "PROTOCOL":                   int(flow.protocol        or 0),
        "L4_DST_PORT":                int(flow.dst_port        or 0),
        "L7_PROTO":                   int(getattr(flow, 'application_id', 0) or 0),
        "TCP_FLAGS":                  tcp_flags,
        "SHORTEST_FLOW_PKT":          shortest,
        "LONGEST_FLOW_PKT":           longest,
        "TCP_WIN_MAX_IN":             tcp_win,

        # ── الموديل القديم فقط (LightGBM) ────────────────────────────
        "MIN_TTL":       float(getattr(udps, 'src_min_ttl', 64) if udps else 64),

        # ── الموديل الجديد فقط (Isolation Forest) ────────────────────
        "MAX_TTL":           max_ttl,
        "SERVER_TCP_FLAGS":  float(getattr(udps, 'server_tcp_flags', 0) if udps else 0),
    }

# ══════════════════════════════════════════════════════════════════════════════
class ApiClient:
    """
    Client بيدعم إرسال الـ batch لـ API واحد أو اتنين في نفس الوقت.

    كل API ليه response format مختلف:
      LightGBM API  → predictions[].is_attack + label + confidence
      Anomaly API   → predictions[].is_anomaly + anomaly_score + status
    """
    def __init__(self, lgbm_url: str = None, anomaly_url: str = None):
        self.lgbm_url   = lgbm_url
        self.anomaly_url= anomaly_url
        self._session   = None

    async def start(self):
        self._session = aiohttp.ClientSession(
            timeout=aiohttp.ClientTimeout(total=10)
        )

    def _build_payload(self, batch: list[dict]) -> dict:
        return {
            "records": [
                {"features": r["features"], "metadata": r["metadata"]}
                for r in batch
            ]
        }

    async def _send_lgbm(self, batch: list[dict]):
        """بيبعت للـ LightGBM API وبيطبع الـ attack alerts."""
        try:
            async with self._session.post(
                self.lgbm_url, json=self._build_payload(batch)
            ) as resp:
                if resp.status == 200:
                    result = await resp.json()
                    for i, p in enumerate(result.get("predictions", [])):
                        if p.get("is_attack"):
                            meta     = batch[i]["metadata"]
                            src_ip   = meta.get("src_ip",   "N/A")
                            dst_ip   = meta.get("dst_ip",   "N/A")
                            dst_port = meta.get("dst_port", 0)
                            log.warning(
                                f"🚨 [LGBM] {p.get('label')} "
                                f"({p.get('confidence', 0):.1%}) | "
                                f"{src_ip} → {dst_ip}:{dst_port}"
                            )
                else:
                    log.error(f"[LGBM] API Error {resp.status}")
        except Exception as e:
            log.error(f"[LGBM] Connection failed: {e}")

    async def _send_anomaly(self, batch: list[dict]):
        """بيبعت للـ Anomaly API وبيطبع الـ anomaly alerts."""
        try:
            async with self._session.post(
                self.anomaly_url, json=self._build_payload(batch)
            ) as resp:
                if resp.status == 200:
                    result = await resp.json()
                    for i, p in enumerate(result.get("predictions", [])):
                        if p.get("is_anomaly"):
                            meta     = batch[i]["metadata"]
                            src_ip   = meta.get("src_ip",   "N/A")
                            dst_ip   = meta.get("dst_ip",   "N/A")
                            dst_port = meta.get("dst_port", 0)
                            log.warning(
                                f"⚠️  [ANOMALY] Score: {p.get('anomaly_score', 0):.4f} | "
                                f"{src_ip} → {dst_ip}:{dst_port}"
                            )
                else:
                    log.error(f"[ANOMALY] API Error {resp.status}")
        except Exception as e:
            log.error(f"[ANOMALY] Connection failed: {e}")

    async def send_batch(self, batch: list[dict]):
        """
        بيبعت الـ batch للـ APIs المفعّلة.
        لو الاتنين مفعّلين، بيبعت للاتنين بالتوازي (asyncio.gather).
        """
        tasks = []
        if self.lgbm_url:
            tasks.append(self._send_lgbm(batch))
        if self.anomaly_url:
            tasks.append(self._send_anomaly(batch))
        if tasks:
            await asyncio.gather(*tasks)

    async def stop(self):
        if self._session:
            await self._session.close()

# ══════════════════════════════════════════════════════════════════════════════
class RingBuffer:
    def __init__(self, maxlen: int):
        self._buf       = deque(maxlen=maxlen)
        self._lock      = threading.Lock()
        self._not_empty = threading.Condition(self._lock)

    def put(self, item: dict):
        with self._not_empty:
            self._buf.append(item)
            self._not_empty.notify()

    def get_batch(self, max_items: int) -> list[dict]:
        with self._not_empty:
            if not self._buf:
                self._not_empty.wait(timeout=0.05)
            batch = []
            while self._buf and len(batch) < max_items:
                batch.append(self._buf.popleft())
            return batch


class FlowDeduplicator:
    def __init__(self, ttl_sec: float = 60.0):
        self._cache = {}
        self._lock  = threading.Lock()
        self._ttl   = ttl_sec

    def is_duplicate(self, fid: str) -> bool:
        now = time.monotonic()
        with self._lock:
            if fid in self._cache and (now - self._cache[fid] < self._ttl):
                return True
            self._cache[fid] = now
            return False

# ══════════════════════════════════════════════════════════════════════════════
def capture_worker(iface, ring, deduplicator, stop_event):
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
            raw = extract_raw_features(flow)
            fid = (f"{flow.src_ip}|{flow.dst_ip}|"
                   f"{flow.src_port}|{flow.dst_port}|{flow.protocol}")
            if not deduplicator.is_duplicate(fid):
                meta = {
                    "src_ip":   flow.src_ip,
                    "dst_ip":   flow.dst_ip,
                    "src_port": flow.src_port,
                    "dst_port": flow.dst_port,
                    "protocol": flow.protocol,
                    "l7":       flow.application_name,
                }
                ring.put({"features": raw, "metadata": meta})
    except Exception as e:
        log.error(f"Capture error on {iface}: {e}")


async def main():
    parser = argparse.ArgumentParser(
        description="Net-Knight Sensor v5.2 — Dual Model Support",
        formatter_class=argparse.RawTextHelpFormatter,
        epilog="""
أمثلة الاستخدام:
  LightGBM فقط:
    python sensor.py --lgbm-url http://localhost:8080/predict

  Anomaly فقط:
    python sensor.py --anomaly-url http://localhost:8081/predict

  الاتنين مع بعض:
    python sensor.py --lgbm-url http://localhost:8080/predict \
                     --anomaly-url http://localhost:8081/predict
        """
    )
    parser.add_argument(
        "--lgbm-url",
        default=None,
        help="LightGBM API URL (اتركه فاضي لو مش عايزة تشغّله)"
    )
    parser.add_argument(
        "--anomaly-url",
        default=None,
        help="Anomaly API URL (اتركه فاضي لو مش عايزة تشغّله)"
    )
    args = parser.parse_args()

    # لازم على الأقل API واحد يكون محدد
    if not args.lgbm_url and not args.anomaly_url:
        parser.error(
            "لازم تحددي API واحد على الأقل:\n"
            "  --lgbm-url   للـ LightGBM\n"
            "  --anomaly-url للـ Anomaly\n"
            "  أو الاتنين مع بعض"
        )

    # اطبعي إيه اللي شغّال
    active = []
    if args.lgbm_url:
        active.append(f"LightGBM → {args.lgbm_url}")
    if args.anomaly_url:
        active.append(f"Anomaly  → {args.anomaly_url}")
    log.info("Active models: " + " | ".join(active))

    ring         = RingBuffer(15000)
    deduplicator = FlowDeduplicator()
    stop_event   = threading.Event()

    api = ApiClient(
        lgbm_url   =args.lgbm_url,
        anomaly_url=args.anomaly_url
    )
    await api.start()

    for iface in [WAN_INTERFACE, LAN_INTERFACE]:
        threading.Thread(
            target=capture_worker,
            args=(iface, ring, deduplicator, stop_event),
            daemon=True
        ).start()

    log.info(
        f"🚀 Net-Knight v5.2 Active → WAN:{WAN_INTERFACE} | LAN:{LAN_INTERFACE}"
    )

    try:
        while True:
            batch = ring.get_batch(32)
            if batch:
                await api.send_batch(batch)
            await asyncio.sleep(0.1)
    except KeyboardInterrupt:
        log.info("Shutdown initiated...")
        stop_event.set()
    await api.stop()


if __name__ == "__main__":
    asyncio.run(main())