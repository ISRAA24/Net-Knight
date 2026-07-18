from __future__ import annotations
import asyncio
import logging

import requests

from config import settings

log = logging.getLogger("Net-Knight.node_client")

ALERTS_ENDPOINT = "/api/ai/netknight/alerts"          
BANDWIDTH_ENDPOINT = "/api/ai/netknight/bandwidth-alert"  


def _post(path: str, payload: dict) -> requests.Response | None:
    if not settings.NODE_BASE_URL or "REPLACE" in settings.NODE_BASE_URL:
        log.warning(f"NODE_BASE_URL لسه مش متظبط — تجاهل إرسال {path} (payload محفوظ في اللوج فقط).")
        log.debug(f"Payload كان هيتبعت: {payload}")
        return None
    url = settings.NODE_BASE_URL.rstrip("/") + path
    try:
        resp = requests.post(url, json=payload, timeout=5)
        if resp.status_code >= 300:
            log.error(f"Node رفض الطلب {path}: {resp.status_code} {resp.text[:300]}")
        return resp
    except requests.RequestException as e:
        log.error(f"فشل الاتصال بـ Node ({path}): {e}")
        return None


async def apost(path: str, payload: dict) -> requests.Response | None:
    
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(None, _post, path, payload)


def send_alert(payload: dict) -> None:
    
    _post(ALERTS_ENDPOINT, payload)


async def send_alert_async(payload: dict) -> None:
    await apost(ALERTS_ENDPOINT, payload)


def send_bandwidth_alert(usage_percent: float) -> None:
    _post(BANDWIDTH_ENDPOINT, {
        "message": "Warning: Bandwidth usage is high and has exceeded 80%.",
        "usage_percent": round(usage_percent, 2),
    })
