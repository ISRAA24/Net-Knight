from __future__ import annotations
import logging
import threading
import time

import aiohttp

from config import settings
from enforcement.action_executor import ActionExecutor, A4_A5_DDOS
from enforcement.rule_scheduler import RuleScheduler
from gateway import approval_gateway
from gateway.ws_monitor import TrafficStats
from state import ip_history_store, ewma_store, active_window_store
from state.pps_tracker import PpsTracker

log = logging.getLogger("Net-Knight.flow_pipeline")

_ACTIVE_FLOW_TTL_SEC = 30.0


class FlowPipeline:
    def __init__(self, api_url: str, alert_dedup):
        self.api_url = api_url.rstrip("/")
        self._session: aiohttp.ClientSession | None = None
        self._alert_dedup = alert_dedup

        self.pps_tracker = PpsTracker(window_seconds=settings.EWMA_UPDATE_INTERVAL_SEC)
        self.traffic_stats = TrafficStats()
        self.rule_scheduler = RuleScheduler()
        self.executor = ActionExecutor(self.rule_scheduler)

        self._tracked_internal_ips: dict[str, float] = {}
        self._active_flows: dict[str, float] = {}
        self._lock = threading.Lock()

    def start(self) -> None:
        self.rule_scheduler.start()

    def tracked_internal_ips(self) -> set[str]:
    
        now = time.time()
        with self._lock:
            return {ip for ip, ts in self._tracked_internal_ips.items() if now - ts < 30}

    async def start_session(self) -> None:
        self._session = aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=30))

    async def stop(self) -> None:
        if self._session:
            await self._session.close()
        self.pps_tracker.stop()
        self.rule_scheduler.stop()


    def _enrich(self, record: dict) -> dict:
        meta = record["metadata"]
        features = record["features"]
        src_ip, dst_ip = meta["src_ip"], meta["dst_ip"]

        history = ip_history_store.get_for_state(src_ip)
        history["active_windows"] = active_window_store.get_relevant_windows(src_ip, dst_ip)

        network = None
        total_pkts = features.get("IN_PKTS", 0) + features.get("OUT_PKTS", 0)
        total_bytes = features.get("IN_BYTES", 0) + features.get("OUT_BYTES", 0)

        if settings.is_internal_ip(dst_ip) or settings.is_gateway_ip(dst_ip):
            self.pps_tracker.record(dst_ip, total_pkts)
            with self._lock:
                self._tracked_internal_ips[dst_ip] = time.time()
            current_rate = self.pps_tracker.get_rate(dst_ip)
            network = {"dest_pressure_ratio": ewma_store.pressure_ratio(dst_ip, current_rate or total_pkts)}

        
        self.traffic_stats.record_flow(
            src_ip, dst_ip, meta.get("protocol", 0), meta.get("src_port", 0), meta.get("dst_port", 0),
            meta.get("l7", ""), int(total_bytes), int(total_pkts),
        )
        self._track_active_connection(meta)

        return {"features": features, "metadata": meta, "history": history, "network": network}

    def _track_active_connection(self, meta: dict) -> None:
        fid = f"{meta['src_ip']}|{meta['dst_ip']}|{meta['src_port']}|{meta['dst_port']}|{meta.get('protocol')}"
        now = time.time()
        with self._lock:
            self._active_flows[fid] = now
            if len(self._active_flows) % 200 == 0:  
                dead = [k for k, ts in self._active_flows.items() if now - ts > _ACTIVE_FLOW_TTL_SEC]
                for k in dead:
                    del self._active_flows[k]
            self.traffic_stats.set_active_connections(len(self._active_flows))

    
    def _build_payload(self, batch: list[dict]) -> dict:
        return {"records": [self._enrich(r) for r in batch]}

    async def send_batch(self, batch: list[dict]) -> None:
        try:
            async with self._session.post(
                f"{self.api_url}/predict", json=self._build_payload(batch)
            ) as resp:
                if resp.status != 200:
                    log.error(f"API Error {resp.status}")
                    return
                result = await resp.json()
                
                handled_this_batch: set[tuple[str, str]] = set()
                for idx, full in enumerate(result.get("predictions", [])):
                    if idx >= len(batch):
                        continue
                    self._handle_prediction(full, handled_this_batch)
        except Exception as e:
            log.error(f"Failed to connect to AI_engine API: {type(e).__name__}: {e}")

    def _handle_prediction(self, full: dict, handled_this_batch: set[tuple[str, str]]) -> None:
        if not full.get("is_alert"):
            return  
        meta = full["flow_metadata"]
        src_ip, dst_ip, dst_port = meta["src_ip"], meta["dst_ip"], meta["dst_port"]
        mitigation = full["mitigation"]

        if mitigation.get("suppressed"):
            log.debug(
                f"↺ suppressed (same ongoing attack) | {src_ip} → {dst_ip}:{dst_port} | "
                f"{mitigation['attack_category']} | reused action={mitigation['action_name']}"
            )
            return

        
        scope_ip = dst_ip if mitigation["action_id"] == A4_A5_DDOS else src_ip
        batch_key = (scope_ip, mitigation["attack_category"])
        if batch_key in handled_this_batch:
            log.debug(
                f"↺ suppressed (same ongoing attack, same batch) | {src_ip} → {dst_ip}:{dst_port} | "
                f"{mitigation['attack_category']} | action={mitigation['action_name']}"
            )
            return
        handled_this_batch.add(batch_key)

        tag = f"{mitigation['attack_category']}:{mitigation['action_name']}"
        if self._alert_dedup.should_alert(src_ip, tag):
            log.warning(
                f"🚨 ALERT | {src_ip} → {dst_ip}:{dst_port} | "
                f"{mitigation['attack_category']} (conf={full['detection']['confidence']:.1%}) | "
                f"action={mitigation['action_name']}"
            )

        approval_gateway.handle_decision(full, self.executor)
