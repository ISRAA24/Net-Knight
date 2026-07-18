from __future__ import annotations
import ipaddress
import socket

# ══════════════════════════════════════════════════════════════════════════════
# Network
# ══════════════════════════════════════════════════════════════════════════════
LAN_INTERFACE = "ens37"
WAN_INTERFACE = "ens33"

LAN_SUBNETS = [
    ipaddress.ip_network("10.0.0.0/24"),
]


def _detect_own_ips() -> set[str]:
    ips = set()
    try:
        hostname = socket.gethostname()
        ips.add(socket.gethostbyname(hostname))
    except Exception:
        pass
    return ips


GATEWAY_OWN_IPS: set[str] = {"10.0.0.10", "192.168.1.6"}  


def is_internal_ip(ip_str: str) -> bool:
    try:
        ip = ipaddress.ip_address(ip_str)
    except ValueError:
        return False
    return any(ip in net for net in LAN_SUBNETS)


def is_gateway_ip(ip_str: str) -> bool:
    return ip_str in GATEWAY_OWN_IPS


# ══════════════════════════════════════════════════════════════════════════════
# Redis
# ══════════════════════════════════════════════════════════════════════════════
REDIS_HOST = "localhost"
REDIS_PORT = 6379
REDIS_DB = 0

IP_HISTORY_TTL_SEC = 3 * 24 * 3600          
IP_HISTORY_ATTACK_FIELDS = [
    "dos", "ddos", "brute_force", "password", "scanning", "injection", "xss", "anomaly",
]

# ══════════════════════════════════════════════════════════════════════════════
# EWMA 
# ══════════════════════════════════════════════════════════════════════════════
EWMA_ALPHA = 0.1                              
EWMA_UPDATE_INTERVAL_SEC = 5                 
EWMA_SPIKE_GUARD_MULTIPLIER = 2.0            
EWMA_ATTACK_STABILIZE_SEC = 180              
EWMA_TTL_SEC = 7 * 24 * 3600                 
                                              

# ══════════════════════════════════════════════════════════════════════════════
# Redis Backup 
# ══════════════════════════════════════════════════════════════════════════════
REDIS_BACKUP_INTERVAL_SEC = 5 * 60           
REDIS_BACKUP_FILE = "/var/lib/netknight/redis_backup.json"

# ══════════════════════════════════════════════════════════════════════════════
# nftables 
# ══════════════════════════════════════════════════════════════════════════════
NFT_FAMILY = "inet"
NFT_TABLE = "filter"
NFT_CHAIN_INPUT = "dynamic_input"     
NFT_CHAIN_FORWARD = "dynamic_forward"  
NFT_SET_TEMP_BLOCK = "nk_temp_block"          
NFT_SET_PERM_BLOCK = "nk_perm_block"          
NFT_SET_RL_ANOMALY = "nk_rl_anomaly"          
NFT_SET_RL_SCANNING = "nk_rl_scanning"        
NFT_SET_RL_BRUTEFORCE = "nk_rl_bruteforce"    
NFT_DYNAMIC_RULE_DEFAULT_DURATION_SEC = 30 * 60   

# ══════════════════════════════════════════════════════════════════════════════
# Node.js
# ══════════════════════════════════════════════════════════════════════════════
NODE_BASE_URL = "http://100.97.136.8:3003"

PENDING_REQUEST_TTL_SEC = 24 * 3600

# ══════════════════════════════════════════════════════════════════════════════
# WebSocket Monitoring  + Bandwidth Alert 
# ══════════════════════════════════════════════════════════════════════════════
WS_NODE_URL = "ws://100.97.136.8:3003/netknight/monitor"   
WS_PUSH_INTERVAL_SEC = 1.0

NETWORK_CAPACITY_MBPS = 1000
BANDWIDTH_ALERT_THRESHOLD_PCT = 80.0
BANDWIDTH_ALERT_COOLDOWN_SEC = 60   

# ══════════════════════════════════════════════════════════════════════════════
#  nftables Action Table
# ══════════════════════════════════════════════════════════════════════════════
# A1 — Rate Limit
RATE_LIMIT_PPS = {
    "anomaly": 30,          # anomaly-only
    "scanning": 10,
}
RATE_LIMIT_PER_MINUTE = {
    "brute_force": 5,       
}
RATE_LIMIT_DURATION_SEC = {
    "anomaly": 30 * 60,
    "scanning": 30 * 60,
    "brute_force": 30 * 60,
    "dos": 30 * 60,   
}
DOS_RATE_LIMIT_FALLBACK_PPS = 50   
# A2 — Temp Block durations 
TEMP_BLOCK_DURATION_SEC = {
    "brute_force": 30 * 60,
    "password": 60 * 60,
    "scanning": 30 * 60,
    "injection": 6 * 3600,
    "xss": 6 * 3600,
    "dos": 30 * 60,
    "anomaly_only": 20 * 60,    
    "anomaly_with_attack": 60 * 60, 
}

DDOS_A5_SYN_RATIO = 0.2


MONITOR_ALERT_COOLDOWN_SEC = 60          
                                          
PENDING_ALERT_COOLDOWN_SEC = 5 * 60      
REJECTED_ALERT_COOLDOWN_SEC = 2 * 60     
PERM_BLOCK_WINDOW_TTL_SEC = 7 * 24 * 3600  