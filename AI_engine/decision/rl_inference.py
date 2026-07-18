import numpy as np

# ── Actions ──────────────────────────────────────────────────────────────────
A0_MONITOR    = 0   
A1_RATE_LIMIT = 1   
A2_TEMP_BLOCK = 2   
A3_PERM_BLOCK = 3   
A4_A5_DDOS    = 4   
N_ACTIONS     = 5

ACTION_NAMES = {
    0: "A0_MONITOR",
    1: "A1_RATE_LIMIT",
    2: "A2_TEMP_BLOCK",
    3: "A3_PERM_BLOCK",
    4: "A4_A5_DDOS",
}

# ── IDS attack encoding ───────────────────────────────────────────────────────
ATTACK_NORMAL   = 0
ATTACK_BRUTE    = 1
ATTACK_PASSWORD = 2
ATTACK_DOS      = 3
ATTACK_DDOS     = 4
ATTACK_SCAN     = 5
ATTACK_INJECT   = 6
ATTACK_XSS      = 7
N_ATTACK_TYPES  = 8

ATTACK_NAMES = {
    0: "normal",    1: "brute_force", 2: "password",  3: "dos",
    4: "ddos",      5: "scanning",    6: "injection",  7: "xss",
}


IDS_LABEL_MAP = {
    "benign":    0,
    "brute force": 1,
    "password":  2,
    "dos":       3,
    "ddos":      4,
    "scanning":  5,
    "injection": 6,
    "xss":       7,
}
def ids_label_to_int(label: str) -> int:
    l = label.lower().strip()
    for k, v in IDS_LABEL_MAP.items():
        if k in l: return v
    return ATTACK_NORMAL

# ── Protocol ─────────────────────────────────────────────────────────────────
PROTO_MAP = {6: "TCP", 17: "UDP", 1: "ICMP", 58: "ICMP"}
def proto_to_str(p) -> str:
    try: return PROTO_MAP.get(int(p), "TCP")
    except: return "TCP"

# ── Anomaly thresholds & max ranges ──────────────────────────────────────────
ANOMALY_THRESHOLD = {"WebTcp": 19.0, "NonWebTcp": 5.0, "NonWebUDP": 6.63}
ANOMALY_MAX       = {"WebTcp": 30.0, "NonWebTcp": 10.0, "NonWebUDP": 10.0}


ANOMALY_NORMAL_MAX     = 0.3   
ANOMALY_SUSPICIOUS_MAX = 0.6   
ANOMALY_NORM_BOUNDARY  = 0.6   

def normalize_anomaly_score(raw_score: float, model_key: str) -> float:
    thr = ANOMALY_THRESHOLD.get(model_key, 5.0)
    mx  = ANOMALY_MAX.get(model_key, 10.0)
    raw = max(0.0, float(raw_score))
    if raw <= thr:
        norm = (raw / thr) * ANOMALY_NORM_BOUNDARY
    else:
        extra = min((raw - thr) / max(mx - thr, 1e-6), 1.0)
        norm  = ANOMALY_NORM_BOUNDARY + extra * (1.0 - ANOMALY_NORM_BOUNDARY)
    return float(np.clip(norm, 0.0, 1.0))

def is_anomaly(norm: float) -> bool:
    return norm >= ANOMALY_NORM_BOUNDARY

# ── IDS thresholds ────────────────────────────────────────────────────────────
IDS_CONF_THR = 0.6   

# ── DDoS conditions (all four must hold simultaneously) ──────────────────────
DDOS_MIN_SOURCES  = 10
DDOS_MIN_PRESSURE = 3.0
DDOS_MIN_CONNRATE = 50.0
DDOS_MIN_IDS_CONF = 0.6

# ── Network normalization caps ────────────────────────────────────────────────
PRESSURE_CAP  = 10.0
CONNRATE_CAP  = 200.0
CONNS_CAP     = 500.0
SOURCES_CAP   = 100.0
REPEAT_CAP    = 10.0



# IDS attack type → severity label (for dashboard explanation layer)
IDS_SEVERITY_MAP = {
    ATTACK_NORMAL:   "LOW",
    ATTACK_BRUTE:    "MEDIUM",
    ATTACK_SCAN:     "MEDIUM",
    ATTACK_PASSWORD: "HIGH",
    ATTACK_INJECT:   "HIGH",
    ATTACK_XSS:      "HIGH",
    ATTACK_DOS:      "HIGH",
    ATTACK_DDOS:     "CRITICAL",
}

# Normalized anomaly score → severity label (for dashboard explanation layer)
ANOMALY_SEVERITY_THRESHOLDS = {
    "LOW":      (0.00, 0.50),
    "MEDIUM":   (0.50, 0.65),
    "HIGH":     (0.65, 0.80),
    "CRITICAL": (0.80, 1.00),
}

_SEVERITY_ORDER = ["LOW", "MEDIUM", "HIGH", "CRITICAL"]

def get_anomaly_severity(anomaly_score: float) -> str:
    """
    DASHBOARD ONLY — converts normalized anomaly score to severity label.
    Must NOT be used inside RL state, reward, or action selection.
    """
    score = float(np.clip(anomaly_score, 0.0, 1.0))
    for label, (lo, hi) in ANOMALY_SEVERITY_THRESHOLDS.items():
        if lo <= score < hi:
            return label
    return "CRITICAL"   # score == 1.0 edge case

def get_final_severity(ids_attack_type: int, anomaly_score: float) -> str:
    
    ids_sev = IDS_SEVERITY_MAP.get(ids_attack_type, "LOW")
    anom_sev = get_anomaly_severity(anomaly_score)

    if ids_attack_type == ATTACK_NORMAL:
        # IDS says benign → trust anomaly detector
        return anom_sev

    # IDS detected an attack
    if anomaly_score >= 0.6:
        # Strong agreement → upgrade IDS severity by one level
        idx = _SEVERITY_ORDER.index(ids_sev)
        upgraded = _SEVERITY_ORDER[min(idx + 1, len(_SEVERITY_ORDER) - 1)]
        return upgraded

    return ids_sev   # IDS only, anomaly not significant



from dataclasses import dataclass


@dataclass
class IDSOutput:
    """
    Output of the IDS (LightGBM) model.
    severity is NOT included — it is computed separately for the dashboard only.
    """
    attack_type: int   = ATTACK_NORMAL
    confidence:  float = 0.0
    protocol:    str   = "TCP"

@dataclass
class AnomalyOutput:
    raw_score: float = 0.0
    model_key: str   = "WebTcp"   # WebTcp / NonWebTcp / NonWebUDP

@dataclass
class IPHistory:
    """
    Per-source-IP history.
    repeat_count = total number of times this IP has been observed (any action).
    was_blocked / block_count are tracked for reference / dashboard but NOT in RL state.
    """
    repeat_count: int = 0

    same_attack_count: int = 0
    last_attack_type: int = -1

    was_blocked: bool = False

    last_action: int = -1     # NEW
    block_count: int = 0

@dataclass
class NetworkState:
    """
    Destination / network metrics.
    dest_pressure_ratio, dest_new_conn_rate, conns_active_dest, unique_sources → in RL state.
    bandwidth_util, cpu_load → dashboard only, NOT in RL state.
    """
    dest_pressure_ratio: float = 1.0
    dest_new_conn_rate:  float = 0.0
    conns_active_dest:   int   = 0
    unique_sources:      int   = 1
    bandwidth_util:      float = 0.0   # dashboard only
    cpu_load:            float = 0.0   # dashboard only

# ── IP History Store (in-memory reference implementation) ────────────────────
class HistoryStore:
    def __init__(self): self._d = {}

    def get(self, ip: str) -> IPHistory:
        return self._d.setdefault(ip, IPHistory())

    def update(self, ip: str, action: int, attack_type: int):
        
        h = self.get(ip)

        h.repeat_count += 1

        if attack_type == h.last_attack_type:
            h.same_attack_count += 1
        else:
            h.same_attack_count = 1

        h.last_attack_type = attack_type

        h.last_action = action

        if action != A0_MONITOR:
            h.was_blocked = True
            h.block_count += 1

    def reset(self, ip: str):
        self._d[ip] = IPHistory()


STATE_DIM = 28

def build_state(ids: IDSOutput, anom: AnomalyOutput,
                hist: IPHistory, net: NetworkState) -> np.ndarray:
    # Attack type one-hot (8)
    oh = np.zeros(N_ATTACK_TYPES, np.float32)
    oh[int(np.clip(ids.attack_type, 0, N_ATTACK_TYPES - 1))] = 1.0

    a_n = normalize_anomaly_score(anom.raw_score, anom.model_key)
    pr  = ids.protocol.upper()

    # Last-action one-hot (5)
    la = np.zeros(N_ACTIONS, np.float32)
    ids_uncertainty = 1 - ids.confidence
    anom_margin = abs(a_n - ANOMALY_NORM_BOUNDARY)
    if hist.last_action == -1:
        la[0] = 1.0
    else:
        la[hist.last_action] = 1.0
    v = np.concatenate([
        oh,                                                   # 8
        [np.clip(ids.confidence, 0, 1)],                     # 1  (NO severity)
        [pr == "TCP", pr == "UDP", pr == "ICMP"],             # 3
        [a_n, float(is_anomaly(a_n))],                       # 2
        [
        np.clip(hist.repeat_count / 5, 0, 1),
        np.clip(hist.same_attack_count / 5, 0, 1)
        ], 
        [float(hist.repeat_count >=1)],    # 1  (NO was_blocked)
        la,                                                   # 5
        [np.clip(net.dest_pressure_ratio / PRESSURE_CAP, 0, 1),
         np.clip(net.dest_new_conn_rate  / CONNRATE_CAP,  0, 1),
         np.clip(net.conns_active_dest   / CONNS_CAP,     0, 1),
         np.clip(net.unique_sources      / SOURCES_CAP,   0, 1)],
        [1 - ids.confidence],
        [abs(a_n - ANOMALY_NORM_BOUNDARY)],
        ]).astype(np.float32)
    assert v.shape[0] == STATE_DIM, (
        f"STATE_DIM mismatch: got {v.shape[0]}, expected {STATE_DIM}"
    )
    return v

# ══════════════════════════════════════════════════════════════════════════════
# Anomaly Sub-Model Selection
# ══════════════════════════════════════════════════════════════════════════════
WEB_PORTS = {80, 443, 8080, 8443, 8000, 3000}

def select_anomaly_model(src_port: int, dst_port: int, protocol_num: int) -> str:
    
    is_web_port = (dst_port in WEB_PORTS) or (src_port in WEB_PORTS)
    is_tcp      = (protocol_num == 6)
    is_udp      = (protocol_num == 17)
    is_icmp     = (protocol_num in (1, 58))

    if is_web_port and is_tcp:
        return "WebTcp"
    elif (not is_web_port) and is_tcp:
        return "NonWebTcp"
    elif (not is_web_port) and (is_udp or is_icmp):
        return "NonWebUDP"
    else:
        return "NonWebTcp"   # safe fallback

# ── Bridge functions ───────────────────────────────────────────────────────────
def make_ids(label: str, confidence: float, protocol_raw=6) -> IDSOutput:
    """
    IDS LightGBM string output → IDSOutput.
    severity is no longer included in IDSOutput.
    Use get_final_severity() separately for dashboard purposes.
    """
    at = ids_label_to_int(label)
    return IDSOutput(at, float(confidence), proto_to_str(protocol_raw))

def make_anomaly(api_resp: dict) -> AnomalyOutput:
    """
    Anomaly FastAPI response → AnomalyOutput.
    api_resp = {"model": "WebTcp"/"NonWebTcp"/"NonWebUDP",
                "anomaly_score": float, "is_anomaly": bool}
    """
    return AnomalyOutput(
        raw_score = float(api_resp.get("anomaly_score", 0.0)),
        model_key = api_resp.get("model", "WebTcp"),
    )

def build_state_from_flow(flow_meta: dict, ids_label: str, ids_conf: float,
                           anomaly_resp: dict, history_store: HistoryStore,
                           net: NetworkState) -> np.ndarray:
    """
    Full bridge for VM inference:
    flow_meta    = {"src_ip", "dst_ip", "src_port", "dst_port", "protocol", ...}
    ids_label    = string from LightGBM (e.g. "Brute Force")
    ids_conf     = max(predict_proba(...)[0])
    anomaly_resp = dict from Anomaly API
    """
    ids     = make_ids(ids_label, ids_conf, flow_meta.get("protocol", 6))
    anomaly = make_anomaly(anomaly_resp)
    src_ip  = flow_meta.get("src_ip", "0.0.0.0")
    history = history_store.get(src_ip)
    return build_state(ids, anomaly, history, net)



# ── Helper predicates ────────────────────────────────────────────────────────
def ids_ok(ids: IDSOutput) -> bool:
    """True when IDS confidently identifies an attack (not just anomaly)."""
    return ids.attack_type != ATTACK_NORMAL and ids.confidence > IDS_CONF_THR

def ddos_cond(ids: IDSOutput, net: NetworkState) -> bool:
    """
    Explicit DDoS detection rule (all four conditions must hold):
      unique_sources > 10
      AND dest_pressure_ratio > 3.0
      AND dest_new_conn_rate >= 50.0
      AND ids.confidence > 0.6
    """
    return (
        ids.attack_type   == ATTACK_DDOS
        and net.unique_sources      >  DDOS_MIN_SOURCES
        and net.dest_pressure_ratio >  DDOS_MIN_PRESSURE
        and net.dest_new_conn_rate  >= DDOS_MIN_CONNRATE
        and ids.confidence          >  DDOS_MIN_IDS_CONF
    )

# ── a3_ok — determines when A3_PERM_BLOCK is allowed ────────────────────────
def a3_ok(ids: IDSOutput, a_n: float, h: IPHistory) -> bool:
    """
    Returns True when A3 (permanent block) is allowed and justified.

    Two triggering rules:

    Rule 12 — Strong Agreement Escalation:
        IDS confidence > 0.8  AND  anomaly_score > 0.5  AND  repeat_count > 2
        Applies to ANY confirmed attack type (overrides decision table).

    Decision Table — Password / Injection / XSS:
        IDS confirmed  AND  attack in {password, injection, xss}  AND  repeat_count > 1
        (Second+ repetition of a high-severity attack justifies permanent block.)

    Important: A3 is NEVER allowed for anomaly-only traffic
               (IDS confidence < 0.6) — enforced via the mask.
    """
    rc = h.repeat_count
    at = ids.attack_type

    # Rule 12: Strong Agreement — any confirmed attack type
    if ids.confidence > 0.8 and a_n > 0.5 and rc > 2:
        return True

    # Decision Table: Password / Injection / XSS with repetition
    if ids_ok(ids) and at in (ATTACK_PASSWORD, ATTACK_INJECT, ATTACK_XSS):
        if rc > 1:      # repeat_count > 1 → third+ encounter
            return True

    return False


# ── Recommended action — decision table (VALIDATION/REFERENCE ONLY) ─────────
def recommended(ids: IDSOutput, a_n: float, h: IPHistory,
                net: NetworkState) -> int:
    
    A0, A1, A2, A3, A4A5 = (A0_MONITOR, A1_RATE_LIMIT,
                              A2_TEMP_BLOCK, A3_PERM_BLOCK, A4_A5_DDOS)
    rc = h.repeat_count
    at = ids.attack_type

    # ── Priority 1: DDoS distributed attack ──────────────────────────────────
    if at == ATTACK_DDOS and ddos_cond(ids, net):
        return A4A5

    # ── Priority 2: Strong Agreement (Rule 12) — escalate to A3 ─────────────
    if ids.confidence > 0.8 and a_n > 0.5 and rc > 2:
        return A3

    # ── Priority 3: IDS-confirmed attack table ────────────────────────────────
    if ids_ok(ids):
        if at == ATTACK_BRUTE:
            return A1 if rc == 0 else A2
        elif at == ATTACK_PASSWORD:
            return A3 if a3_ok(ids, a_n, h) else A2
        elif at == ATTACK_SCAN:
            return A1 if rc == 0 else A2
        elif at in (ATTACK_INJECT, ATTACK_XSS):
            return A3 if a3_ok(ids, a_n, h) else A2
        elif at == ATTACK_DOS:
            return A1 if rc == 0 else A2
        else:
            # Unknown IDS-confirmed attack → conservative rate limit
            return A1

    # ── Priority 4: Anomaly-only (IDS confidence < 0.6) ─────────────────────
    if a_n < ANOMALY_NORMAL_MAX:        # < 0.3 → clearly benign
        return A0
    if a_n < ANOMALY_SUSPICIOUS_MAX:    # 0.3 ≤ a_n < 0.6 → suspicious, needs review
        return A0                        # Case A

    # a_n ≥ 0.6 → anomaly confirmed
    if rc <= 2:
        return A1   # Case B: first/second/third encounter → rate limit
    return A2       # Case C: established repeat offender → temp block
    # Note: A3 is never recommended for anomaly-only (no IDS confirmation)

# ── Safety mask ──────────────────────────────────────────────────────────────
def get_mask(ids: IDSOutput, a_n: float, h: IPHistory,
             net: NetworkState, whitelisted: bool = False) -> list:
    """
    Action mask — prevents RL from selecting structurally disallowed actions.
    Returns list[bool] of length N_ACTIONS.
    """
    m = [True] * N_ACTIONS

    if whitelisted:
        return [a == A0_MONITOR for a in range(N_ACTIONS)]

    # Block A3 when not justified
    if not a3_ok(ids, a_n, h):
        m[A3_PERM_BLOCK] = False

    # Block A4_A5_DDOS when DDoS conditions are not met
    if not ddos_cond(ids, net):
        m[A4_A5_DDOS] = False

    return m
