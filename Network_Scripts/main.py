from __future__ import annotations
import argparse
import asyncio
import logging
import threading

import uvicorn

from config import settings
from enforcement import nft_rules
from state import redis_backup, ewma_store
from state.pps_tracker import PpsTracker
from gateway.flow_pipeline import FlowPipeline
from gateway.ws_monitor import WsMonitor
from api import enforcement_api

from capture.unified_capture import (
    RingBuffer, FlowDeduplicator, AlertDeduplicator, load_whitelist,
    capture_worker, WAN_INTERFACE, LAN_INTERFACE,
)

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
log = logging.getLogger("Net-Knight.main")


async def _consume_ring(ring: RingBuffer, pipeline: FlowPipeline) -> None:
    while True:
        batch = ring.get_batch(256)
        if batch:
            await pipeline.send_batch(batch)
        await asyncio.sleep(0.1)


async def async_main(api_url: str, enforcement_port: int) -> None:
    nft_rules.ensure_base_structures()

    
    redis_backup.restore_from_backup()

    whitelist = load_whitelist()
    ring = RingBuffer(15000)
    deduplicator = FlowDeduplicator()
    alert_dedup = AlertDeduplicator()
    stop_event = threading.Event()

    for iface in [WAN_INTERFACE, LAN_INTERFACE]:
        threading.Thread(
            target=capture_worker,
            args=(iface, ring, deduplicator, stop_event, whitelist),
            daemon=True,
        ).start()

    
    pipeline = FlowPipeline(api_url, alert_dedup)
    pipeline.start()
    await pipeline.start_session()

    
    ewma_updater = ewma_store.EwmaUpdater(pipeline.pps_tracker, pipeline.tracked_internal_ips)
    ewma_updater.start()

    backup_scheduler = redis_backup.RedisBackupScheduler()
    backup_scheduler.start()

    enforcement_api.bind_executor(pipeline.executor)
    ws_monitor = WsMonitor(pipeline.traffic_stats)

    uvicorn_config = uvicorn.Config(
        enforcement_api.app, host="0.0.0.0", port=enforcement_port, log_level="info",
    )
    uvicorn_server = uvicorn.Server(uvicorn_config)

    log.info(
        f"🚀 Net-Knight Network_Scripts Active → WAN:{WAN_INTERFACE} | LAN:{LAN_INTERFACE} | "
        f"AI_engine={api_url}/predict | enforcement_api=:{enforcement_port} | "
        f"whitelist={len(whitelist)} CIDRs"
    )

    try:
        await asyncio.gather(
            _consume_ring(ring, pipeline),
            uvicorn_server.serve(),
            ws_monitor.run(),
        )
    except (KeyboardInterrupt, asyncio.CancelledError):
        pass
    finally:
        log.info("Shutdown initiated...")
        stop_event.set()
        deduplicator.stop()
        ewma_updater.stop()
        backup_scheduler.stop()
        ws_monitor.stop()
        await pipeline.stop()


def main() -> None:
    parser = argparse.ArgumentParser(description="Net-Knight Network_Scripts — capture + enforcement + gateway")
    parser.add_argument("--api-url", required=True, help="AI_engine base URL, e.g. http://localhost:8080")
    parser.add_argument("--port", type=int, default=9090, help="Port بتاع enforcement_api (افتراضي 9090)")
    args = parser.parse_args()
    asyncio.run(async_main(args.api_url, args.port))


if __name__ == "__main__":
    main()
