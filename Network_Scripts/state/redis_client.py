from __future__ import annotations
import logging

try:
    import redis
except ImportError:
    print("[FATAL] redis-py not installed. pip install redis")
    raise

from config import settings

log = logging.getLogger("Net-Knight.redis")

_client: "redis.Redis | None" = None


def get_client() -> "redis.Redis":
    global _client
    if _client is None:
        _client = redis.Redis(
            host=settings.REDIS_HOST,
            port=settings.REDIS_PORT,
            db=settings.REDIS_DB,
            decode_responses=True,
            socket_connect_timeout=3,
            socket_timeout=3,
        )
        try:
            _client.ping()
            log.info(f"✅ Redis connected @ {settings.REDIS_HOST}:{settings.REDIS_PORT}/{settings.REDIS_DB}")
        except redis.exceptions.ConnectionError as e:
            log.error(f"❌ Redis connection failed: {e} — تأكدي إن Redis شغال محليًا (redis-server)")
    return _client
