"""
core/logger.py — JSON logger

بيكتب كل حاجة بتحصل في الـ API في ملف JSON
كل سطر في الملف هو JSON object مستقل (JSON Lines format)
علشان الـ Node.js يقدر يقراه بسهولة سطر سطر
"""
from __future__ import annotations

import json
import logging
import os
from datetime import datetime, timezone
from typing import Any

# ---------------------------------------------------------------------------
# إعداد الـ logger
# ---------------------------------------------------------------------------

LOG_FILE = os.environ.get("NFT_LOG_FILE", "/var/log/nft_api.log")

# بنعمل logger مخصص للـ API
_logger = logging.getLogger("nft_api")
_logger.setLevel(logging.DEBUG)

# بنكتب في ملف
_handler = logging.FileHandler(LOG_FILE)
_handler.setLevel(logging.DEBUG)
_logger.addHandler(_handler)


# ---------------------------------------------------------------------------
# دالة الـ logging الأساسية
# ---------------------------------------------------------------------------

def _write(level: str, data: dict[str, Any]) -> None:
    """بتكتب سطر JSON في الملف."""
    entry = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "level": level,
        **data,
    }
    _handler.stream.write(json.dumps(entry) + "\n")
    _handler.stream.flush()


# ---------------------------------------------------------------------------
# الدوال اللي بتستخدمها الـ routes
# ---------------------------------------------------------------------------

def log_success(endpoint: str, command: str, extra: dict | None = None) -> None:
    """
    بتسجل لما الأمر ينجح.
    extra: أي داتا إضافية زي الـ handle أو الـ comment
    """
    data = {
        "endpoint": endpoint,
        "command" : command,
        "status"  : "success",
    }
    if extra:
        data.update(extra)
    _write("INFO", data)


def log_error(endpoint: str, command: str, message: str) -> None:
    """بتسجل لما الأمر يفشل."""
    _write("ERROR", {
        "endpoint": endpoint,
        "command" : command,
        "status"  : "error",
        "message" : message,
    })


def log_request(endpoint: str, body: dict) -> None:
    """بتسجل الـ request الجاي من الباك."""
    _write("INFO", {
        "endpoint": endpoint,
        "event"   : "request_received",
        "body"    : body,
    })