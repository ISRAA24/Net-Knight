from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
import ipaddress
import joblib
import json
import os
import sys
import logging
import time
import threading
import uuid
from datetime import datetime, timezone
from collections import defaultdict, deque

import numpy as np
import pandas as pd
import torch
import uvicorn

# ── RL / explainability / history / severity / network-metrics modules ───────
import sys as _sys
import os as _os
_sys.path.insert(0, _os.path.dirname(_os.path.dirname(_os.path.abspath(__file__))))  

from decision import rl_inference as RL
from decision import explainability as EXPLAIN
from decision import severity as SEV
from state.state_adapter import build_ip_history, build_network_state, attack_category

# ══════════════════════════════════════════════════════════════════════════════
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("Net-Knight-Unified-API")

# ══════════════════════════════════════════════════════════════════════════════
#     CDN / Trusted IP Whitelist 
# ══════════════════════════════════════════════════════════════════════════════
CDN_WHITELIST: set = set()
CDN_WHITELIST_FILE = "cdn_whitelist.txt"


def load_whitelist(path: str = CDN_WHITELIST_FILE) -> None:
    
    global CDN_WHITELIST
    networks: set = set()
    if not os.path.exists(path):
        logger.warning(f"⚠️  Whitelist file not found: {path} — CDN filtering disabled in API")
        CDN_WHITELIST = networks
        return
    try:
        with open(path) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                try:
                    networks.add(ipaddress.IPv4Network(line, strict=False))
                except ValueError as e:
                    logger.warning(f"⚠️  Invalid CIDR in whitelist: '{line}' — {e}")
        logger.info(f"✅ CDN whitelist loaded: {len(networks)} CIDR ranges from '{path}'")
    except Exception as e:
        logger.error(f"❌ Failed to load whitelist: {e}")
    CDN_WHITELIST = networks


def is_whitelisted(src_ip: str, dst_ip: str = "") -> bool:
    
    if not CDN_WHITELIST:
        return False
    for ip_candidate in filter(None, [src_ip, dst_ip]):
        try:
            ip = ipaddress.IPv4Address(ip_candidate)
            if any(ip in net for net in CDN_WHITELIST):
                return True
        except ValueError:
            pass
    return False


# ══════════════════════════════════════════════════════════════════════════════
#       IDS (LightGBM) — Globals  
# ══════════════════════════════════════════════════════════════════════════════
LGBM_MODEL = None
SCALER = None
LABEL_ENCODER = None
FEATURE_ORDER = None

CONFIDENCE_THRESHOLD = 0.60

ATTACK_THRESHOLDS = {
    "DDoS":        0.60,
    "DoS":         0.60,
    "scanning":    0.60,
    "Brute Force": 0.60,
    "password":    0.60,
    "injection":   0.60,
    "xss":         0.60,
}

ORIGINAL_NUM_COLS = ['IN_BYTES', 'OUT_BYTES', 'IN_PKTS', 'OUT_PKTS', 'FLOW_DURATION_MILLISECONDS',
                     'TCP_WIN_MAX_IN', 'SHORTEST_FLOW_PKT', 'Packet_Rate', 'Byte_Rate',
                     'Packet_Density', 'Aggressiveness', 'Pkt_Size_Avg',
                     'Flow_Symmetry', 'Symmetry_Ratio', 'Byte_Symmetry', 'MIN_TTL']

# ──────────────────────────────────────────────────────────────────────────────
# TUNED CONSTANTS 
# ──────────────────────────────────────────────────────────────────────────────
SCAN_PORT_THRESHOLD = 8
DOS_PACKET_RATE_THRESHOLD = 1000
DOS_SYN_RATIO_THRESHOLD = 0.70
BF_SUSPICION_THRESHOLD = 0.35
BF_AUTH_RATIO_THRESHOLD = 0.85
WEB_ATTACK_MIN_FLOWS = 5
WEB_MALICE_THRESHOLD = 0.12
SLOW_ATTACK_MIN_FLOWS = 25
SLOW_ATTACK_MAX_PORTS = 2
SLOW_ATTACK_MAX_RATE  = 40
DDOS_MIN_SOURCES = 10
DDOS_MIN_FLOWS = 5

# ──────────────────────────────────────────────────────────────────────────────

class FinalAnchorEngine:
    
    def __init__(self, ttl=60):
        self.ttl = ttl
        self.history = defaultdict(lambda: deque())
        self.port_history = defaultdict(lambda: set())
        self.global_target_stats = defaultdict(lambda: {
            "sources": set(),
            "last_update": 0,
            "flows": deque()
        })
        self.lock = threading.Lock()
        self.auth_ports = {21, 22, 23, 25, 110, 143, 445, 3389}
        self.strict_auth_ports = {21, 22, 23, 25}

        self._stop_event = threading.Event()
        self._cleanup_thread = threading.Thread(
            target=self._background_cleanup,
            daemon=True,
            name="anchor-cleanup"
        )
        self._cleanup_thread.start()
        logger.info(
            f"FinalAnchorEngine started | "
            f"scan_threshold={SCAN_PORT_THRESHOLD} ports | "
            f"ddos_min_sources={DDOS_MIN_SOURCES}"
        )

    def _background_cleanup(self):
        while not self._stop_event.wait(timeout=30):
            now = time.time()
            with self.lock:
                dead_keys = []
                for key, dq in self.history.items():
                    while dq and now - dq[0]['ts'] > self.ttl:
                        dq.popleft()
                    if not dq:
                        dead_keys.append(key)
                for key in dead_keys:
                    del self.history[key]
                    self.port_history.pop(key, None)

                dead_dsts = []
                for dst_ip, stats in self.global_target_stats.items():
                    flows = stats["flows"]
                    while flows and now - flows[0]['ts'] > self.ttl:
                        flows.popleft()
                    if now - stats["last_update"] > self.ttl:
                        stats["sources"].clear()
                    if not flows and not stats["sources"]:
                        dead_dsts.append(dst_ip)
                for dst in dead_dsts:
                    del self.global_target_stats[dst]

            if dead_keys or dead_dsts:
                logger.debug(f"Cleanup: removed {len(dead_keys)} pair-keys, {len(dead_dsts)} dst-keys")

    def stop(self):
        self._stop_event.set()

    def _cleanup_on_request(self, key, dst_ip):
        now = time.time()
        dq = self.history[key]
        while dq and now - dq[0]['ts'] > self.ttl:
            dq.popleft()
        if not dq:
            self.port_history[key].clear()
        flows = self.global_target_stats[dst_ip]["flows"]
        while flows and now - flows[0]['ts'] > self.ttl:
            flows.popleft()

    def update(self, src_ip, dst_ip, lgbm_res, eng, meta):
        src_is_victim = (
            src_ip in self.global_target_stats
            and len(self.global_target_stats[src_ip]["flows"]) >= 3
        )
        is_response = (
            eng['TCP_FLAGS'] in {18, 20, 4, 16, 17, 24, 25}
            and not eng['Is_SYN_Only']
            and meta.get('src_port', 0) > 1024
            and meta.get('dst_port', 0) not in self.auth_ports
            and src_is_victim
        )
        if is_response:
            return "Benign", 0.99, {"context": "Response Traffic - Victim"}

        key = (src_ip, dst_ip)
        with self.lock:
            self._cleanup_on_request(key, dst_ip)
            dst_port = meta.get('dst_port', 0)

            self.history[key].append({
                'ts':       time.time(),
                'label':    lgbm_res['label'],
                'probs':    lgbm_res['all'],
                'port':     dst_port,
                'rate':     eng['Packet_Rate'],
                'is_syn':   eng['Is_SYN_Only'],
                'pkt_size': eng['Pkt_Size_Avg'],
            })
            self.port_history[key].add(dst_port)

            stats = self.global_target_stats[dst_ip]
            stats["sources"].add(src_ip)
            stats["last_update"] = time.time()
            stats["flows"].append({
                'ts':     time.time(),
                'rate':   eng['Packet_Rate'],
                'is_syn': eng['Is_SYN_Only'],
                'src':    src_ip
            })

            ddos_result = self._check_ddos(dst_ip)
            if ddos_result[0]:
                return ddos_result

            return self._analyze(src_ip, dst_ip)

    def _check_ddos(self, dst_ip):
        stats = self.global_target_stats[dst_ip]
        source_count = len(stats["sources"])

        if source_count < DDOS_MIN_SOURCES:
            return None, 0.0, {}

        flows = list(stats["flows"])
        if len(flows) < DDOS_MIN_FLOWS:
            return None, 0.0, {}

        avg_rate  = sum(f['rate'] for f in flows) / len(flows)
        syn_ratio = sum(1 for f in flows if f['is_syn']) / len(flows)

        if avg_rate > DOS_PACKET_RATE_THRESHOLD and syn_ratio > DOS_SYN_RATIO_THRESHOLD:
            return "DDoS", 0.99, {
                "sources":  source_count,
                "avg_rate": round(avg_rate, 2),
                "flows":    len(flows),
                "method":   "rate"
            }

        if (source_count >= DDOS_MIN_SOURCES
                and syn_ratio > 0.8
                and len(flows) >= 20):
            return "DDoS", 0.97, {
                "sources":    source_count,
                "syn_ratio":  round(syn_ratio, 2),
                "flows":      len(flows),
                "method":     "volume"
            }

        return None, 0.0, {}

    def _analyze(self, src_ip, dst_ip):
        key = (src_ip, dst_ip)
        data  = list(self.history[key])
        total = len(data)
        if total < 2:
            return None, 0.0, {}

        unique_ports = self.port_history[key]
        num_ports    = len(unique_ports)
        avg_rate     = sum(d['rate'] for d in data) / total
        syn_ratio    = sum(1 for d in data if d['is_syn']) / total
        source_count = len(self.global_target_stats[dst_ip]["sources"])

        src_is_known_victim = (
            src_ip in self.global_target_stats
            and len(self.global_target_stats[src_ip]["flows"]) >= 3
        )

        if num_ports >= SCAN_PORT_THRESHOLD and not src_is_known_victim:
            if any(d['is_syn'] for d in data):
                return "scanning", 0.98, {
                    "unique_ports": num_ports,
                    "threshold":    SCAN_PORT_THRESHOLD
                }

        if avg_rate > DOS_PACKET_RATE_THRESHOLD and syn_ratio > DOS_SYN_RATIO_THRESHOLD:
            if num_ports < SCAN_PORT_THRESHOLD:
                label = "DDoS" if source_count >= DDOS_MIN_SOURCES else "DoS"
                return label, 0.99, {"avg_rate": round(avg_rate, 2), "sources": source_count}

        strict_attempts = [d for d in data if d['port'] in self.strict_auth_ports]
        if len(strict_attempts) >= 4:
            bf_suspicion = sum(
                d['probs'].get('Brute Force', 0) + d['probs'].get('password', 0)
                for d in strict_attempts
            ) / len(strict_attempts)
            auth_ratio = len(strict_attempts) / total
            if bf_suspicion > BF_SUSPICION_THRESHOLD or auth_ratio > BF_AUTH_RATIO_THRESHOLD:
                return "Brute Force", 0.96, {
                    "attempts": len(strict_attempts), "path": "strict"
                }

        soft_auth_ports = self.auth_ports - self.strict_auth_ports
        soft_attempts = [d for d in data if d['port'] in soft_auth_ports]
        if len(soft_attempts) >= 6:
            bf_suspicion = sum(
                d['probs'].get('Brute Force', 0) + d['probs'].get('password', 0)
                for d in soft_attempts
            ) / len(soft_attempts)
            if bf_suspicion > (BF_SUSPICION_THRESHOLD + 0.15):
                return "Brute Force", 0.93, {
                    "attempts": len(soft_attempts), "path": "soft"
                }

        https_attempts = [d for d in data if d['port'] == 443]
        if len(https_attempts) >= 8:
            bf_suspicion_https = sum(
                d['probs'].get('Brute Force', 0) + d['probs'].get('password', 0)
                for d in https_attempts
            ) / len(https_attempts)
            avg_pkt_size = sum(d.get('pkt_size', 0) for d in https_attempts) / len(https_attempts)
            is_keepalive_pattern = avg_pkt_size < 100
            if bf_suspicion_https > 0.75 and not is_keepalive_pattern:
                return "Brute Force", 0.91, {
                    "attempts":     len(https_attempts),
                    "path":         "https",
                    "avg_pkt_size": round(avg_pkt_size, 1)
                }

        web_malice = sum(
            d['probs'].get('injection', 0) + d['probs'].get('xss', 0)
            for d in data
        ) / total
        if web_malice > WEB_MALICE_THRESHOLD and total >= WEB_ATTACK_MIN_FLOWS:
            label = (
                "injection"
                if sum(d['probs'].get('injection', 0) for d in data) >
                   sum(d['probs'].get('xss', 0) for d in data)
                else "xss"
            )
            return label, 0.88, {"malice": round(web_malice, 3)}

        if num_ports <= SLOW_ATTACK_MAX_PORTS and total >= 10:
            http_flows = [d for d in data if d['port'] in {80, 443}]
            if len(http_flows) >= 8:
                http_ratio = len(http_flows) / total
                if http_ratio > 0.7 and avg_rate < SLOW_ATTACK_MAX_RATE:
                    return "DoS", 0.92, {
                        "type":       "Slow-Attack",
                        "flows":      total,
                        "http_flows": len(http_flows)
                    }
                if len(http_flows) >= 20:
                    return "DoS", 0.90, {
                        "type":       "Slow-Attack-HighVolume",
                        "flows":      total,
                        "http_flows": len(http_flows)
                    }

        return None, 0.0, {}


engine = FinalAnchorEngine()


def engineer_features(raw: dict) -> dict:
    in_b,  out_b  = float(raw.get('IN_BYTES', 0)),  float(raw.get('OUT_BYTES', 0))
    in_p,  out_p  = float(raw.get('IN_PKTS',  0)),  float(raw.get('OUT_PKTS',  0))
    dur_ms         = float(raw.get('FLOW_DURATION_MILLISECONDS', 0))
    prot, flags, port = (int(raw.get('PROTOCOL', 0)),
                         int(raw.get('TCP_FLAGS', 0)),
                         int(raw.get('L4_DST_PORT', 0)))
    dur_sec  = max(dur_ms, 0.1) / 1000.0
    is_syn   = 1 if (prot == 6 and (flags & 0x02)) else 0
    base_rate = (in_p + out_p) / dur_sec
    return {
        'L4_DST_PORT': port, 'PROTOCOL': prot, 'L7_PROTO': int(raw.get('L7_PROTO', 0)),
        'IN_BYTES': in_b, 'IN_PKTS': in_p, 'OUT_BYTES': out_b, 'OUT_PKTS': out_p,
        'TCP_FLAGS': flags, 'FLOW_DURATION_MILLISECONDS': dur_ms,
        'MIN_TTL': float(raw.get('MIN_TTL', 0)),
        'SHORTEST_FLOW_PKT': float(raw.get('SHORTEST_FLOW_PKT', 0)),
        'TCP_WIN_MAX_IN': float(raw.get('TCP_WIN_MAX_IN', 0)),
        'Packet_Rate':    base_rate,
        'Byte_Rate':      (in_b + out_b) / dur_sec,
        'Aggressiveness': in_b / (dur_ms + 0.001),
        'Pkt_Size_Avg':   (in_b + out_b) / (in_p + out_p + 1.0),
        'Flow_Symmetry':  out_b / (in_b + 1.0),
        'Symmetry_Ratio': in_p / (out_p + 0.001),
        'Byte_Symmetry':  in_b / (in_b + out_b + 1.0),
        'Packet_Density': in_b / (in_p + 1.0),
        'Is_SYN_Only':    is_syn,
        'Is_Common_Port': 1 if port in {80, 443, 53, 21, 22, 23, 25, 3389} else 0,
        'SYN_Rate':            base_rate * is_syn,
        'SYN_Aggressiveness':  (in_b / (dur_ms + 0.001)) * is_syn,
        'Half_Open_Ratio':     is_syn * (in_p / (in_p + out_p + 0.001)),
        'Zero_Response_SYN':   is_syn * (1 if out_p == 0 else 0),
        'SYN_Flood_Score':     is_syn * (1 if out_p == 0 else 0) * base_rate * max(in_p, 1) ** 0.7,
        'HTTP_Flood_Index':    (1 if port in {80, 443} else 0) * (in_b / (dur_ms + 0.001)),
        'High_Rate_HTTP':      (1 if port in {80, 443} else 0) * base_rate,
        'Brute_Flow_Density':  in_p if port in {21, 22, 23, 25} else 0,
        'Scan_Index':          1 if (is_syn and in_p <= 8 and out_p == 0) else 0,
    }


def load_ids_artifacts():
    """تحميل ملفات موديل الـ IDS (LightGBM) عند الـ startup."""
    global LGBM_MODEL, SCALER, LABEL_ENCODER, FEATURE_ORDER
    try:
        LGBM_MODEL    = joblib.load("best_net_knight_LightGBM5.pkl")
        SCALER        = joblib.load("net_knight_scaler_final5.pkl")
        LABEL_ENCODER = joblib.load("attack_label_encoder5.pkl")
        FEATURE_ORDER = joblib.load("feature_names3.pkl")
        logger.info("✅ IDS (LightGBM) artifacts loaded successfully.")
    except Exception as e:
        logger.error(f"❌ Failed to load IDS artifacts: {e}")


def run_ids_batch(records: list[dict], return_debug: bool = False):
    
    if LGBM_MODEL is None:
        empty = [
            {"label": "N/A", "confidence": 0.0, "is_attack": False, "status": "IDS model not loaded"}
            for _ in records
        ]
        return (empty, [], None) if return_debug else empty

    engineered = [engineer_features(rec.get("features", {})) for rec in records]

    df_all = pd.DataFrame(engineered)
    for col in FEATURE_ORDER:
        if col not in df_all.columns:
            df_all[col] = 0.0
    df_all = df_all[FEATURE_ORDER].copy()

    cols_to_scale = [c for c in ORIGINAL_NUM_COLS if c in df_all.columns]
    df_all[cols_to_scale] = SCALER.transform(df_all[cols_to_scale])

    cat_cols = ['PROTOCOL', 'L7_PROTO', 'TCP_FLAGS', 'Is_Common_Port',
                'Is_SYN_Only', 'L4_DST_PORT', 'Scan_Index']
    for c in cat_cols:
        if c in df_all.columns:
            df_all[c] = df_all[c].astype(int).astype('category')

    all_probs = LGBM_MODEL.predict_proba(df_all)

    results = []
    for i, rec in enumerate(records):
        meta   = rec.get("metadata", {})
        src_ip = meta.get('src_ip', 'N/A')
        dst_ip = meta.get('dst_ip', 'N/A')

        if is_whitelisted(src_ip, dst_ip):
            results.append({
                "label":      "Benign",
                "confidence": 1.0,
                "is_attack":  False,
                "reason":     {"context": "CDN/Trusted IP — whitelisted"},
            })
            continue

        probs    = all_probs[i]
        lgbm_res = {
            "label": LABEL_ENCODER.inverse_transform([int(np.argmax(probs))])[0],
            "conf":  float(np.max(probs)),
            "all":   {cls: float(p) for cls, p in zip(LABEL_ENCODER.classes_, probs)}
        }

        final_label, final_conf, reason = engine.update(
            src_ip, dst_ip, lgbm_res, engineered[i], meta
        )

        if not final_label:
            final_label = lgbm_res['label']
            final_conf  = lgbm_res['conf']

        threshold = ATTACK_THRESHOLDS.get(final_label, CONFIDENCE_THRESHOLD)
        is_attack = (
            final_label.lower() not in ("benign", "normal", "0")
            and final_conf >= threshold
        )

        results.append({
            "label":      final_label,
            "confidence": round(final_conf, 4),
            "is_attack":  is_attack,
            "reason":     reason,
            "_raw_ml_label_index": int(np.argmax(probs)),   # internal — used by explainability only
        })

    if return_debug:
        return results, engineered, df_all
    return results


# ══════════════════════════════════════════════════════════════════════════════
#       Anomaly Detection — Globals  
# ══════════════════════════════════════════════════════════════════════════════
MODELS   = {}
SCALERS  = {}
FEATURES = {}

WEBTCP_THRESHOLD = 19.0
NONWEBTCP_THRESHOLD = 5.0
NONWEBUDP_THRESHOLD = 6.63

MODEL_MAPPING = {
    "WebTcp": {
        "features": "web_tcp_features2.json",
        "model":    "web_tcp_model2.joblib",
        "scaler":   "web_tcp_scaler2.joblib",
    },
    "NonWebTcp": {
        "features": "non_web_tcp_features2.json",
        "model":    "non_web_tcp_model2.joblib",
        "scaler":   "non_web_tcp_scaler2.joblib",
    },
    "NonWebUDP": {
        "features": "features_udp.json",
        "model":    "model_udp.joblib",
        "scaler":   "scaler_udp.joblib",
    },
}

CAPTURE_FEATURES = {
    'IN_BYTES', 'OUT_BYTES', 'IN_PKTS', 'OUT_PKTS',
    'FLOW_DURATION_MILLISECONDS', 'TCP_FLAGS', 'MIN_TTL', 'MAX_TTL',
    'LONGEST_FLOW_PKT', 'SHORTEST_FLOW_PKT', 'MAX_IP_PKT_LEN',
    'MIN_IP_PKT_LEN', 'L4_DST_PORT', 'TCP_WIN_MAX_IN', 'SERVER_TCP_FLAGS',
    'PROTOCOL',
}


def _load_model(path: str):
   
    if path.endswith(".joblib"):
        original_torch_load = torch.load
        def cpu_torch_load(*args, **kwargs):
            kwargs["map_location"] = torch.device("cpu")
            kwargs.setdefault("weights_only", False)
            return original_torch_load(*args, **kwargs)
        torch.load = cpu_torch_load
        try:
            obj = joblib.load(path)
        finally:
            torch.load = original_torch_load

        if hasattr(obj, 'device'):
            obj.device = torch.device("cpu")
        if hasattr(obj, 'model') and hasattr(obj.model, 'to'):
            obj.model = obj.model.to(torch.device("cpu"))

        return obj
    else:
        return joblib.load(path)


def load_anomaly_artifacts():
    
    for model_key, files in MODEL_MAPPING.items():
        try:
            if os.path.exists(files["features"]):
                with open(files["features"], "r") as f:
                    FEATURES[model_key] = json.load(f)
                logger.info(f"✅ Features loaded for {model_key}: {len(FEATURES[model_key])} features")
            else:
                FEATURES[model_key] = []
                logger.warning(f"⚠️  Feature file not found for {model_key}: {files['features']}")

            if os.path.exists(files["model"]):
                MODELS[model_key] = _load_model(files["model"])
                offset = getattr(MODELS[model_key], 'offset_', None)
                thresh = getattr(MODELS[model_key], 'threshold_', None)
                if thresh is not None:
                    logger.info(f"✅ Model loaded: {model_key} | threshold_={thresh:.6f}")
                elif offset is not None:
                    logger.info(f"✅ Model loaded: {model_key} | offset_={offset:.6f}")
                else:
                    logger.info(f"✅ Model loaded: {model_key}")
            else:
                logger.warning(f"⚠️  Model file not found for {model_key}: {files['model']}")

            if os.path.exists(files["scaler"]):
                SCALERS[model_key] = _load_model(files["scaler"])
                logger.info(f"✅ Scaler loaded: {model_key}")
            else:
                logger.warning(f"⚠️  Scaler file not found for {model_key}: {files['scaler']}")

        except Exception as e:
            logger.error(f"❌ Failed to load artifacts for {model_key}: {e}")


# ══════════════════════════════════════════════════════════════════════════════
# Feature Engineering — matches training notebook
# ══════════════════════════════════════════════════════════════════════════════
def apply_feature_engineering(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()

    df.replace([np.inf, -np.inf], np.nan, inplace=True)
    df.fillna(0, inplace=True)

    numeric_cols = [
        'IN_BYTES', 'OUT_BYTES',
        'IN_PKTS', 'OUT_PKTS',
        'FLOW_DURATION_MILLISECONDS',
        'TCP_FLAGS',
        'MAX_TTL', 'MIN_TTL',
        'LONGEST_FLOW_PKT', 'SHORTEST_FLOW_PKT',
        'MAX_IP_PKT_LEN', 'MIN_IP_PKT_LEN',
        'L4_DST_PORT',
        'TCP_WIN_MAX_IN',
        'PROTOCOL'
    ]
    eps = 1e-6
    for col in numeric_cols:
        df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0)

    df["FLOW_PACKETS"] = df["IN_PKTS"] + df["OUT_PKTS"]
    df["FLOW_BYTES"] = df["IN_BYTES"] + df["OUT_BYTES"]

    duration_sec = (df["FLOW_DURATION_MILLISECONDS"] / 1000) + 1e-6

    df["PKT_RATE"] = (df["FLOW_PACKETS"] / (df["FLOW_DURATION_MILLISECONDS"] + 1))
    df["BYTE_RATE"] = (df["FLOW_BYTES"] / duration_sec)
    df["SESSION_DENSITY"] = (df["FLOW_BYTES"] / (df["FLOW_DURATION_MILLISECONDS"] + 1))

    df["BYTE_IMBALANCE"] = (abs(df["IN_BYTES"] - df["OUT_BYTES"]) / (df["FLOW_BYTES"] + 1e-6))
    df["PKT_ASYMMETRY"] = (abs(df["IN_PKTS"] - df["OUT_PKTS"]) / (df["FLOW_PACKETS"] + 1e-6))
    df["REQ_RES_RATIO"] = (df["IN_PKTS"] / (df["OUT_PKTS"] + 1e-6))

    df["AVG_PKT_SIZE"] = (df["FLOW_BYTES"] / (df["FLOW_PACKETS"] + 1))
    df["PKT_SIZE_APPROX_VAR"] = (df["MAX_IP_PKT_LEN"] - df["MIN_IP_PKT_LEN"]).abs()
    df["PKT_SIZE_VARIANCE_APPROX"] = (df["LONGEST_FLOW_PKT"] - df["SHORTEST_FLOW_PKT"]).abs()
    df["IS_CONSTANT_PKT_SIZE"] = (df["LONGEST_FLOW_PKT"] == df["SHORTEST_FLOW_PKT"]).astype(int)

    df["BURSTINESS"] = (df["PKT_SIZE_VARIANCE_APPROX"] / (df["AVG_PKT_SIZE"] + 1e-6))
    df["CONN_STABILITY"] = (df["FLOW_DURATION_MILLISECONDS"] / (df["FLOW_PACKETS"] + 1e-6))
    df["SPARSITY"] = (df["FLOW_DURATION_MILLISECONDS"] / (df["FLOW_PACKETS"] + 1))

    df["SYN_RATIO"] = (df["TCP_FLAGS"] == 2).astype(int)

    df["IS_FULL_TCP_HANDSHAKE"] = (
        (df["TCP_FLAGS"] >= 2) & (df["TCP_WIN_MAX_IN"] > 0)
    ).astype(int)

    common_ports = [20, 21, 22, 23, 25, 53, 80, 110, 143, 443]

    df["IS_WEB_PORT"] = (df["L4_DST_PORT"].isin([80, 443, 8080])).astype(int)
    df["IS_RARE_PORT"] = (~df["L4_DST_PORT"].isin(common_ports)).astype(int)
    df["IS_RISK_PORT"] = (df["L4_DST_PORT"].isin([23, 2323, 7547])).astype(int)
    df["PORT_ANOMALY"] = (df["L4_DST_PORT"].isin([0, 22, 23, 53, 80, 443, 8080, 1900, 123])).astype(int)

    df["IS_TCP"] = (df["PROTOCOL"] == 6).astype(int)
    df["IS_UDP"] = (df["PROTOCOL"] == 17).astype(int)
    df["IS_ICMP"] = (df["PROTOCOL"].isin([1, 58])).astype(int)
    df["IS_RARE_PROTOCOL"] = (~df["PROTOCOL"].isin([6, 17, 1, 58])).astype(int)

    df['BYTES_PER_PKT'] = df['FLOW_BYTES'] / df['FLOW_PACKETS']
    duration_seconds = df["FLOW_DURATION_MILLISECONDS"] / 1000.0
    duration_seconds = duration_seconds.replace(0, 0.001)

    df["IN_BYTES_PER_SEC"] = df["IN_BYTES"] / duration_seconds
    df["OUT_PKTS_PER_SEC"] = df["OUT_PKTS"] / duration_seconds

    df["BYTE_RATIO"] = np.where(
        df["OUT_BYTES"] == 0, df["IN_BYTES"], df["IN_BYTES"] / df["OUT_BYTES"]
    )

    total_bytes = df["IN_BYTES"] + df["OUT_BYTES"]
    df["BYTE_ASYMMETRY"] = np.where(
        total_bytes == 0, 0, (df["IN_BYTES"] - df["OUT_BYTES"]) / total_bytes
    )
    df["PKTS_PER_MS"] = (df["IN_PKTS"] + df["OUT_PKTS"]) / df["FLOW_DURATION_MILLISECONDS"].replace(0, 0.001)

    df["Aggressiveness"] = df["IN_PKTS"] / df["FLOW_DURATION_MILLISECONDS"].replace(0, 0.001)
    df['LOG_DENSITY'] = df['FLOW_BYTES'] / (df['FLOW_DURATION_MILLISECONDS'] + 1)

    df["UPLOAD_DOWNLOAD_RATIO"] = (df["IN_BYTES"] / (df["OUT_BYTES"] + 1))
    df["PKT_SIZE_CV"] = (np.sqrt(df["PKT_SIZE_APPROX_VAR"]) / (df["AVG_PKT_SIZE"] + 1))
    df["NORMALIZED_BURSTINESS"] = (df["BURSTINESS"] / (df["FLOW_DURATION_MILLISECONDS"] + 1))

    df["LOG_FLOW_BYTES"] = np.log1p(df["FLOW_BYTES"])
    df["LOG_DURATION"] = np.log1p(df["FLOW_DURATION_MILLISECONDS"])
    df["LOG_BYTE_RATE"] = np.log1p(df["BYTE_RATE"])

    df["TRAFFIC_INTENSITY"] = df["FLOW_PACKETS"] * df["FLOW_BYTES"]

    df["FLOW_DIRECTION_IMBALANCE"] = ((df["IN_BYTES"] + 1) / (df["OUT_BYTES"] + 1))

    df["PKT_ENTROPY_APPROX"] = (
        -(
            (df["IN_PKTS"] / (df["FLOW_PACKETS"] + 1)) *
            np.log1p(df["IN_PKTS"] / (df["FLOW_PACKETS"] + 1))
        )
    )

    df["RISK_SCORE"] = (
        df["IS_RARE_PORT"] + df["IS_RISK_PORT"] + df["PORT_ANOMALY"] + df["IS_RARE_PROTOCOL"]
    )

    df["BURST_SPIKE"] = df["PKT_RATE"] * df["BYTE_RATE"]
    df["TCP_AGGRESSION"] = df["TCP_FLAGS"] * df["FLOW_PACKETS"]
    df["INSTABILITY"] = df["CONN_STABILITY"] * df["BURSTINESS"]

    df["BYTES_PER_PKT"] = df["FLOW_BYTES"] / (df["FLOW_PACKETS"] + 1e-6)
    df["TRAFFIC_EFFICIENCY"] = df["FLOW_BYTES"] / (df["FLOW_PACKETS"] + 1)
    df["FLOW_REGULARITY"] = 1 / (1 + df["BURSTINESS"] + df["PKT_ASYMMETRY"])
    df["COMPRESSION_RATIO"] = df["MIN_IP_PKT_LEN"] / (df["MAX_IP_PKT_LEN"] + 1)

    df['IS_SYN_ONLY'] = (df['TCP_FLAGS'] == 2).astype(int)
    df['FLAG_MISMATCH'] = (abs(df['TCP_FLAGS'] - df['SERVER_TCP_FLAGS']))
    df['SERVER_SILENT'] = (df['SERVER_TCP_FLAGS'] == 0).astype(int)
    df['FLOW_TOO_LONG_NO_REPLY'] = (
        (df['FLOW_DURATION_MILLISECONDS'] > 5000) & (df['OUT_BYTES'] == 0)
    ).astype(int)

    df['PKT_RATE'] = (df['IN_PKTS'] + df['OUT_PKTS']) / (df['FLOW_DURATION_MILLISECONDS'] + 1)
    df['BYTE_RATE'] = (df['IN_BYTES'] + df['OUT_BYTES']) / (df['FLOW_DURATION_MILLISECONDS'] + 1)
    df['PKT_ASYMMETRY'] = abs(df['IN_PKTS'] - df['OUT_PKTS']) / (df['IN_PKTS'] + df['OUT_PKTS'] + eps)
    df['BYTE_ASYMMETRY_V2'] = abs(df['IN_BYTES'] - df['OUT_BYTES']) / (df['IN_BYTES'] + df['OUT_BYTES'] + eps)
    df['HANDSHAKE_COMPLETENESS'] = ((df['SERVER_TCP_FLAGS'] > 0) & (df['OUT_PKTS'] > 0)).astype(int)
    df["PKT_SIZE_STD"] = df["LONGEST_FLOW_PKT"] - df["SHORTEST_FLOW_PKT"]
    df["FLOW_BALANCE"] = (df["IN_BYTES"] - df["OUT_BYTES"]) / (df["FLOW_BYTES"] + 1e-6)

    return df


# ══════════════════════════════════════════════════════════════════════════════
# Preprocessing — matches training notebook exactly (log1p + clip at 99th pct)
# ══════════════════════════════════════════════════════════════════════════════
def preprocess_df(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()

    df.replace([np.inf, -np.inf], np.nan, inplace=True)
    df.fillna(0, inplace=True)

    for col in df.columns:
        if col not in ["Label", "Attack"]:
            df[col] = pd.to_numeric(df[col], errors="coerce")
    df.fillna(0, inplace=True)

    to_log1p = [
        "IN_BYTES", "OUT_BYTES", "IN_PKTS", "OUT_PKTS",
        "FLOW_DURATION_MILLISECONDS", "LONGEST_FLOW_PKT", "SHORTEST_FLOW_PKT",
        "MAX_IP_PKT_LEN", "MIN_IP_PKT_LEN", "TCP_WIN_MAX_IN",
        "FLOW_PACKETS", "FLOW_BYTES", "PKT_RATE", "BYTE_RATE",
        "SESSION_DENSITY", "AVG_PKT_SIZE", "PKT_SIZE_APPROX_VAR",
        "PKT_SIZE_VARIANCE_APPROX", "BURSTINESS", "CONN_STABILITY",
        "SPARSITY", "REQ_RES_RATIO", "BYTES_PER_PKT", "IN_BYTES_PER_SEC",
        "BYTE_RATIO", "PKTS_PER_MS", "OUT_PKTS_PER_SEC", "Aggressiveness",
        'LOG_DENSITY', "TRAFFIC_INTENSITY", "BURST_SPIKE", "TCP_AGGRESSION",
    ]

    for col in to_log1p:
        if col in df.columns:
            df[col] = np.log1p(df[col])

    df.replace([np.inf, -np.inf], 0, inplace=True)
    df.fillna(0, inplace=True)

    return df


def select_model(df_eng: pd.DataFrame) -> str:
    """
    WebTcp    → TCP + port 80/443/8080
    NonWebTcp → TCP + non-web port
    NonWebUDP → UDP أو ICMP
    """
    is_web  = int(df_eng.loc[0, "IS_WEB_PORT"])
    is_tcp  = int(df_eng.loc[0, "IS_TCP"])
    is_udp  = int(df_eng.loc[0, "IS_UDP"])
    is_icmp = int(df_eng.loc[0, "IS_ICMP"])

    if is_udp == 1 or is_icmp == 1:
        return "NonWebUDP"
    elif is_tcp == 1:
        return "WebTcp" if is_web == 1 else "NonWebTcp"
    else:
        return None


def run_anomaly_batch(records: list[dict], return_debug: bool = False):
    
    n = len(records)
    if n == 0:
        return ([], None, None) if return_debug else []

    if not MODELS:
        empty = [
            {"model": "N/A", "is_anomaly": False, "anomaly_score": 0.0,
             "status": "No anomaly models loaded"}
            for _ in records
        ]
        return (empty, None, None) if return_debug else empty

    results: list = [None] * n

    df_raw = pd.DataFrame([rec.get("features", {}) for rec in records])
    df_eng = apply_feature_engineering(df_raw)
    df_pre = preprocess_df(df_eng)

    model_assignments = np.select(
        condlist=[
            (df_eng["IS_UDP"] == 1) | (df_eng["IS_ICMP"] == 1),
            (df_eng["IS_TCP"] == 1) & (df_eng["IS_WEB_PORT"] == 1),
            (df_eng["IS_TCP"] == 1) & (df_eng["IS_WEB_PORT"] == 0),
        ],
        choicelist=["NonWebUDP", "WebTcp", "NonWebTcp"],
        default=None
    )

    groups: dict[str, list[int]] = {"WebTcp": [], "NonWebTcp": [], "NonWebUDP": []}
    for i, model_key in enumerate(model_assignments):
        meta_i  = records[i].get("metadata", {})
        src_ip  = meta_i.get("src_ip", "N/A")
        dst_ip  = meta_i.get("dst_ip", "N/A")

        if is_whitelisted(src_ip, dst_ip):
            results[i] = {
                "model":         "N/A",
                "is_anomaly":    False,
                "anomaly_score": 0.0,
                "status":        "CDN/Trusted IP — whitelisted",
            }
        elif model_key is None:
            results[i] = {
                "model": "N/A", "is_anomaly": False,
                "anomaly_score": 0.0, "status": "Unknown protocol — skipped",
            }
        elif model_key not in MODELS or model_key not in SCALERS or model_key not in FEATURES:
            results[i] = {
                "model": model_key, "is_anomaly": False,
                "anomaly_score": 0.0,
                "status": f"Artifacts for {model_key} not loaded",
            }
        else:
            groups[model_key].append(i)

    thresh_map = {
        "WebTcp":    WEBTCP_THRESHOLD,
        "NonWebTcp": NONWEBTCP_THRESHOLD,
        "NonWebUDP": NONWEBUDP_THRESHOLD,
    }

    for model_key, indices in groups.items():
        if not indices:
            continue

        model_features = FEATURES[model_key]
        missing = [c for c in model_features if c not in df_pre.columns]
        if missing:
            logger.error(f"[{model_key}] Missing features: {missing}")
            for i in indices:
                results[i] = {
                    "model": model_key, "is_anomaly": False,
                    "anomaly_score": 0.0, "status": f"Missing features: {missing}",
                }
            continue

        X_group = df_pre.iloc[indices][model_features]

        try:
            X_scaled = SCALERS[model_key].transform(X_group)
        except Exception as e:
            logger.error(f"[{model_key}] Scaling failed: {e}")
            for i in indices:
                results[i] = {
                    "model": model_key, "is_anomaly": False,
                    "anomaly_score": 0.0, "status": f"Scaling failed: {e}",
                }
            continue

        model  = MODELS[model_key]
        thresh = thresh_map[model_key]

        try:
            if hasattr(model, "decision_function"):
                raw_scores = model.decision_function(X_scaled)
                for j, orig_idx in enumerate(indices):
                    score      = float(raw_scores[j])
                    is_anomaly = score > thresh
                    results[orig_idx] = {
                        "model":         model_key,
                        "is_anomaly":    bool(is_anomaly),
                        "anomaly_score": round(score, 6),
                        "threshold":     round(thresh, 6),
                        "status":        "Block" if is_anomaly else "Pass",
                    }
            else:
                preds = model.predict(X_scaled)
                for j, orig_idx in enumerate(indices):
                    is_anomaly = bool(int(preds[j]) == -1)
                    results[orig_idx] = {
                        "model":         model_key,
                        "is_anomaly":    bool(is_anomaly),
                        "anomaly_score": 0.0,
                        "threshold":     0.0,
                        "status":        "Block" if is_anomaly else "Pass",
                    }
        except Exception as e:
            logger.error(f"[{model_key}] Prediction failed: {e}")
            for i in indices:
                results[i] = {
                    "model": model_key, "is_anomaly": False,
                    "anomaly_score": 0.0, "status": f"Prediction failed: {e}",
                }

    if return_debug:
        return results, df_pre, model_assignments
    return results


def run_anomaly_single(rec: dict) -> dict:
    """Thin wrapper حول run_anomaly_batch — للاستخدام في الـ debug endpoints."""
    return run_anomaly_batch([rec])[0]


# ══════════════════════════════════════════════════════════════════════════════
#       STAGE 3 — RL Mitigation  
# ══════════════════════════════════════════════════════════════════════════════
RL_MODEL = None



def load_rl_artifacts(path: str = "net_knight_rl_agent_l6.zip"):
    global RL_MODEL
    try:
        from sb3_contrib import MaskablePPO
        RL_MODEL = MaskablePPO.load(path)
        logger.info(f"✅ RL agent loaded successfully from '{path}'.")
    except Exception as e:
        RL_MODEL = None
        logger.error(f"❌ Failed to load RL agent: {e}")


def run_rl_stage(
    meta: dict,
    engineered_features: dict,
    ids_res: dict,
    anomaly_res: dict,
    whitelisted_flow: bool,
    history_payload: dict | None = None,
    network_payload: dict | None = None,
) -> dict:
    
    src_ip = meta.get("src_ip", "0.0.0.0")
    dst_ip = meta.get("dst_ip", "0.0.0.0")
    protocol_raw = meta.get("protocol", engineered_features.get("PROTOCOL", 6))

    ids_out = RL.make_ids(ids_res["label"], ids_res["confidence"], protocol_raw)
    anomaly_out = RL.make_anomaly(anomaly_res)
    a_n = RL.normalize_anomaly_score(anomaly_out.raw_score, anomaly_out.model_key)

    unique_sources, conns_active_dest, dest_new_conn_rate = _global_target_stats(dst_ip)
    net = build_network_state(
        network_payload=network_payload,
        unique_sources=unique_sources,
        conns_active_dest=conns_active_dest,
        dest_new_conn_rate=dest_new_conn_rate,
    )

    ids_confirmed = RL.ids_ok(ids_out)
    anomaly_flag = RL.is_anomaly(a_n)
    hist = build_ip_history(history_payload, ids_out.attack_type, ids_confirmed, anomaly_flag)
    category = attack_category(ids_out.attack_type, ids_confirmed, anomaly_flag)

    
    active_windows = (history_payload or {}).get("active_windows") or {}
    active_window = active_windows.get(category)
    suppressed = False

    if whitelisted_flow:
        # Whitelisted CDN/trusted traffic — never invoke the model, always A0.
        action_id = RL.A0_MONITOR
        mask = RL.get_mask(ids_out, a_n, hist, net, whitelisted=True)
    elif active_window is not None:
        # نفس الهجوم لسه مستمر تحت نفس القرار السابق — سكيب RL بالكامل.
        action_id = int(active_window.get("action_id", RL.A0_MONITOR))
        mask = RL.get_mask(ids_out, a_n, hist, net)
        suppressed = True
    elif RL_MODEL is None:
        # RL model not loaded (e.g. artifact missing at this deploy) — fail safe to monitor-only.
        action_id = RL.A0_MONITOR
        mask = RL.get_mask(ids_out, a_n, hist, net)
        logger.warning("RL model not loaded — defaulting to A0_MONITOR for this flow.")
    else:
        state = RL.build_state(ids_out, anomaly_out, hist, net)
        mask = RL.get_mask(ids_out, a_n, hist, net)
        action_pred, _ = RL_MODEL.predict(
            state,
            action_masks=np.array(mask, dtype=bool),
            deterministic=True,
        )
        action_id = int(action_pred)

    final_severity = SEV.get_final_severity(ids_out.attack_type, a_n)

    return {
        "ids_out": ids_out,
        "anomaly_out": anomaly_out,
        "anomaly_norm": a_n,
        "hist": hist,
        "net": net,
        "mask": mask,
        "action_id": action_id,
        "action_name": RL.ACTION_NAMES[action_id],
        "attack_category": category,
        "ids_confirmed": ids_confirmed,
        "anomaly_flag": anomaly_flag,
        "final_severity": final_severity,
        "suppressed": suppressed,
    }


def _global_target_stats(dst_ip: str) -> tuple[int, int, float]:
    
    stats = engine.global_target_stats.get(dst_ip)
    if stats is None:
        return 1, 0, 0.0
    unique_sources = len(stats["sources"])
    flows = list(stats["flows"])
    conns_active_dest = len(flows)
    if flows:
        span = max(time.time() - flows[0]["ts"], 1.0)
        dest_new_conn_rate = len(flows) / span
    else:
        dest_new_conn_rate = 0.0
    return unique_sources, conns_active_dest, dest_new_conn_rate


# ══════════════════════════════════════════════════════════════════════════════
#       FastAPI App  
# ══════════════════════════════════════════════════════════════════════════════
@asynccontextmanager
async def lifespan(app: FastAPI):
    load_whitelist()        
    load_ids_artifacts()
    load_anomaly_artifacts()
    load_rl_artifacts()
    yield

app = FastAPI(title="Net-Knight Unified API (IDS + Anomaly + RL)", lifespan=lifespan)


def _build_flow_metadata(meta: dict) -> dict:
    return {
        "flow_id": meta.get("flow_id") or f"flow_{uuid.uuid4().hex[:12]}",
        "timestamp": meta.get("timestamp") or datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "src_ip": meta.get("src_ip", "N/A"),
        "src_port": meta.get("src_port", 0),
        "dst_ip": meta.get("dst_ip", "N/A"),
        "dst_port": meta.get("dst_port", 0),
        "protocol": meta.get("protocol", 0),
        "protocol_name": RL.proto_to_str(meta.get("protocol", 6)),
    }


def _build_full_response(
    rec: dict,
    ids_res: dict,
    anomaly_res: dict,
    engineered: dict,
    df_all_row,
    df_pre_row,
) -> dict:
    meta = rec.get("metadata", {})
    src_ip = meta.get("src_ip", "N/A")
    dst_ip = meta.get("dst_ip", "N/A")

    whitelisted_flow = is_whitelisted(src_ip, dst_ip)

    
    if whitelisted_flow or not (ids_res.get("is_attack") or anomaly_res.get("is_anomaly")):
        return {
            "flow_metadata": _build_flow_metadata(meta),
            "detection": {
                "attack_type": ids_res["label"],
                "confidence": ids_res["confidence"],
                "anomaly_score": anomaly_res.get("anomaly_score", 0.0),
            },
            "is_alert": False,
        }

    rl = run_rl_stage(
        meta, engineered, ids_res, anomaly_res, whitelisted_flow=False,
        history_payload=rec.get("history"),
        network_payload=rec.get("network"),
    )

    # ── IDS explanation ───────────────────────────────────────────────────
    ids_contributions = []
    if not whitelisted_flow and LGBM_MODEL is not None and df_all_row is not None:
        raw_idx = ids_res.get("_raw_ml_label_index")
        if raw_idx is not None:
            ids_contributions = EXPLAIN.get_ids_feature_contributions(
                LGBM_MODEL, df_all_row, FEATURE_ORDER, raw_idx, top_n=5,
            )
    ids_explanation = EXPLAIN.build_ids_explanation(
        ids_res["label"], ids_res["confidence"], ids_contributions, engineered,
    )

    # ── Anomaly explanation ───────────────────────────────────────────────
    anomaly_deviations = []
    model_key = anomaly_res.get("model")
    if (not whitelisted_flow) and model_key in SCALERS and model_key in FEATURES and df_pre_row is not None:
        feature_list = FEATURES[model_key]
        row_dict = {f: df_pre_row.iloc[0][f] for f in feature_list if f in df_pre_row.columns}
        anomaly_deviations = EXPLAIN.get_anomaly_feature_deviations(
            SCALERS[model_key], row_dict, feature_list, top_n=5,
        )
    threshold_map = {"WebTcp": WEBTCP_THRESHOLD, "NonWebTcp": NONWEBTCP_THRESHOLD, "NonWebUDP": NONWEBUDP_THRESHOLD}
    anomaly_explanation = EXPLAIN.build_anomaly_explanation(
        model_key=model_key or "N/A",
        raw_score=anomaly_res.get("anomaly_score", 0.0),
        anomaly_norm=rl["anomaly_norm"],
        threshold=threshold_map.get(model_key, 0.0),
        deviations=anomaly_deviations,
    )

    # ── RL explanation ────────────────────────────────────────────────────
    rl_explanation = EXPLAIN.build_rl_explanation(
        rl["action_id"], rl["ids_out"], rl["anomaly_norm"], rl["hist"], rl["net"], rl["mask"],
    )

    # ── Dashboard fields ──────────────────────────────────────────────────
    top_feature = ids_explanation["top_features"][0] if ids_explanation["top_features"] else None
    dashboard = EXPLAIN.build_dashboard_fields(
        rl["ids_out"], rl["anomaly_norm"], anomaly_res.get("anomaly_score", 0.0),
        rl["action_id"], rl["net"], rl["hist"], top_feature,
    )

    consolidated = EXPLAIN.build_consolidated_summary(
        ids_explanation, anomaly_explanation, rl_explanation, rl["final_severity"],
    )

    return {
        "flow_metadata": _build_flow_metadata(meta),
        "detection": {
            "attack_type": "Anomaly Pattern" if (rl["anomaly_flag"] and not rl["ids_confirmed"]) else ids_res["label"],
            "confidence": ids_res["confidence"],
            "anomaly_score": rl["anomaly_norm"],
        },
        "severity": rl["final_severity"],
        "mitigation": {
            "action_id": rl["action_id"],
            "action_name": rl["action_name"],
            "attack_category": rl["attack_category"],   
            "ids_confirmed": rl["ids_confirmed"],
            "anomaly_flag": rl["anomaly_flag"],
            "suppressed": rl["suppressed"],   
        },
        "network_snapshot": {
            "dest_pressure_ratio": rl["net"].dest_pressure_ratio,
            "dest_new_conn_rate": rl["net"].dest_new_conn_rate,
            "conns_active_dest": rl["net"].conns_active_dest,
            "unique_sources": rl["net"].unique_sources,
        },
        "dashboard": dashboard,
        "detected_patterns": {
            "ids": ids_explanation["notes"],
            "anomaly": anomaly_explanation["notes"],
        },
        "recommended_guidance": dashboard["guide"],
        "explanation": {
            "summary": consolidated["summary"],
            "analyst_notes": consolidated["analyst_notes"],
            "mitigation_reason": consolidated["mitigation_reason"],
            "evidence": consolidated["evidence"],
            "ids": ids_explanation,
            "anomaly": anomaly_explanation,
            "rl": rl_explanation,
        },
        "is_alert": bool(ids_res.get("is_attack")) or bool(anomaly_res.get("is_anomaly")),
    }


@app.post("/predict")
async def predict_combined(request: Request):
    """
    ★ الـ Endpoint الرئيسي ★
    IDS + Anomaly + RL Mitigation + Severity + Explainability لكل flow،
    برجوع الـ response schema الكامل الموصوف في README.
    """
    if LGBM_MODEL is None and not MODELS:
        return JSONResponse(status_code=503, content={"error": "No models loaded at all. Check server logs."})

    try:
        payload = await request.json()
        records = payload.get("records", [])
        if not records:
            return {"predictions": []}

        ids_results, engineered, df_all = run_ids_batch(records, return_debug=True)
        anomaly_results, df_pre, _assignments = run_anomaly_batch(records, return_debug=True)

        predictions = []
        for i, rec in enumerate(records):
            meta     = rec.get("metadata", {})
            src_ip   = meta.get("src_ip", "N/A")
            dst_ip   = meta.get("dst_ip", "N/A")
            dst_port = meta.get("dst_port", 0)

            ids_res     = ids_results[i]
            anomaly_res = anomaly_results[i]

            df_all_row = df_all.iloc[[i]] if df_all is not None else None
            df_pre_row = df_pre.iloc[[i]] if df_pre is not None else None

            full = _build_full_response(
                rec, ids_res, anomaly_res, engineered[i] if engineered else {}, df_all_row, df_pre_row,
            )

            if full["is_alert"] and full["mitigation"].get("suppressed"):
                
                logger.debug(
                    f"↺ {src_ip} → {dst_ip}:{dst_port} | ongoing {full['mitigation']['attack_category']} | "
                    f"RL skipped (active window) | action={full['mitigation']['action_name']}"
                )
            elif full["is_alert"]:
                logger.warning(
                    f"🚨 ALERT | {src_ip} → {dst_ip}:{dst_port} | "
                    f"[IDS] {ids_res.get('label')} (conf={ids_res.get('confidence'):.1%}) | "
                    f"[ANOMALY-{anomaly_res.get('model')}] score={anomaly_res.get('anomaly_score')} | "
                    f"[MITIGATION] {full['mitigation']['action_name']}"
                )
                print(
                    f"🚨 ALERT | {src_ip} → {dst_ip}:{dst_port} | mitigation={full['mitigation']['action_name']}",
                    file=sys.stderr,
                )
            else:
                logger.info(
                    f"📊 {src_ip} -> {dst_ip} | IDS:{ids_res.get('label')} | "
                    f"Anomaly:{anomaly_res.get('status')} | No action (below attack/anomaly threshold — RL not invoked)"
                )

            predictions.append(full)

        return {"predictions": predictions}

    except Exception as e:
        logger.error(f"Combined Prediction Error: {e}")
        return JSONResponse(status_code=500, content={"error": str(e)})


@app.post("/predict/ids")
async def predict_ids_only(request: Request):
    if LGBM_MODEL is None:
        return JSONResponse(status_code=503, content={"error": "IDS model not loaded. Check server logs."})
    try:
        payload = await request.json()
        records = payload.get("records", [])
        if not records:
            return {"predictions": []}

        results = run_ids_batch(records)

        for rec, r in zip(records, results):
            meta = rec.get("metadata", {})
            if r["is_attack"]:
                logger.warning(
                    f"🚨 [{r['label']}] {meta.get('src_ip')} -> {meta.get('dst_ip')} | "
                    f"Conf: {r['confidence']:.1%}"
                )

        # strip internal-only field before returning
        clean_results = [{k: v for k, v in r.items() if not k.startswith("_")} for r in results]
        return {"predictions": clean_results}

    except Exception as e:
        logger.error(f"IDS Prediction Error: {e}")
        return JSONResponse(status_code=500, content={"error": str(e)})


@app.post("/predict/anomaly")
async def predict_anomaly_only(request: Request):
    
    if not MODELS:
        return JSONResponse(status_code=503, content={"error": "No anomaly models loaded. Check server logs."})
    try:
        payload = await request.json()
        records = payload.get("records", [])
        results = run_anomaly_batch(records)

        for rec, r in zip(records, results):
            meta = rec.get("metadata", {})
            tag = "⚠️  ANOMALY" if r["is_anomaly"] else "✅ Normal"
            logger.info(
                f"{tag} [{r['model']}] | {meta.get('src_ip')} → "
                f"{meta.get('dst_ip')}:{meta.get('dst_port')} | Score: {r['anomaly_score']}"
            )

        return {"predictions": results}

    except Exception as e:
        logger.error(f"Anomaly Prediction Error: {e}")
        return JSONResponse(status_code=500, content={"error": str(e)})


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=5000)
