from __future__ import annotations

import json
import logging
import os
from datetime import datetime, timezone
from typing import Any



LOG_FILE = os.environ.get("NFT_LOG_FILE", "/var/log/nft_api.log")


_logger = logging.getLogger("nft_api")
_logger.setLevel(logging.DEBUG)


_handler = logging.FileHandler(LOG_FILE)
_handler.setLevel(logging.DEBUG)
_logger.addHandler(_handler)



def _write(level: str, data: dict[str, Any]) -> None:
    
    entry = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "level": level,
        **data,
    }
    _logger.log(getattr(logging, level), json.dumps(entry))



def log_success(endpoint: str, command: str, extra: dict | None = None) -> None:
    
    data = {
        "endpoint": endpoint,
        "command" : command,
        "status"  : "success",
    }
    if extra:
        data.update(extra)
    _write("INFO", data)


def log_error(endpoint: str, command: str, message: str) -> None:
    
    _write("ERROR", {
        "endpoint": endpoint,
        "command" : command,
        "status"  : "error",
        "message" : message,
    })


def log_request(endpoint: str, body: dict) -> None:
    
    _write("INFO", {
        "endpoint": endpoint,
        "event"   : "request_received",
        "body"    : body,
    })