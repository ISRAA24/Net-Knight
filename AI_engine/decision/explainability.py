from __future__ import annotations

import numpy as np

from decision.rl_inference import (
    ATTACK_NAMES, ATTACK_NORMAL, ATTACK_DDOS, ATTACK_BRUTE, ATTACK_PASSWORD,
    ATTACK_SCAN, ATTACK_INJECT, ATTACK_XSS, ATTACK_DOS,
    ACTION_NAMES, A0_MONITOR, A1_RATE_LIMIT, A2_TEMP_BLOCK, A3_PERM_BLOCK, A4_A5_DDOS,
    IDSOutput, AnomalyOutput, IPHistory, NetworkState,
    ids_ok, ddos_cond, a3_ok, ANOMALY_NORM_BOUNDARY, ANOMALY_NORMAL_MAX, ANOMALY_SUSPICIOUS_MAX,
    DDOS_MIN_SOURCES, DDOS_MIN_PRESSURE, DDOS_MIN_CONNRATE, DDOS_MIN_IDS_CONF, IDS_CONF_THR,
)
from decision.severity import get_anomaly_severity, get_final_severity



HUMAN_IDS_REASONS = {
    "Packet_Rate": "High packet transmission rate detected",
    "MIN_TTL": "Abnormal packet characteristics observed",
    "TCP_FLAGS": "Suspicious TCP flag behavior detected",
    "TCP_WIN_MAX_IN": "Abnormal TCP window behavior observed",
    "SHORTEST_FLOW_PKT": "Unusual packet size pattern detected",
}
ANOMALY_HUMAN_REASONS = {
    "FLAG_MISMATCH":
        "Unusual TCP communication pattern detected",

    "SERVER_TCP_FLAGS":
        "Abnormal server response behavior observed",

    "PKT_SIZE_CV":
        "Packet size pattern differs from normal traffic",

    "IN_BYTES":
        "Traffic volume differs from expected baseline",

    "BYTE_ASYMMETRY_V2":
        "Traffic flow imbalance detected"
}
IDS_FEATURE_DESCRIPTIONS = {
    "L4_DST_PORT":                 "Destination port targeted by the flow",
    "PROTOCOL":                    "Transport-layer protocol number (6=TCP, 17=UDP, 1/58=ICMP)",
    "L7_PROTO":                    "Application-layer protocol identifier",
    "IN_BYTES":                    "Bytes sent from source to destination",
    "IN_PKTS":                     "Packets sent from source to destination",
    "OUT_BYTES":                   "Bytes returned from destination to source",
    "OUT_PKTS":                    "Packets returned from destination to source",
    "TCP_FLAGS":                   "Cumulative TCP flags observed on the flow",
    "FLOW_DURATION_MILLISECONDS":  "Total duration of the flow",
    "MIN_TTL":                     "Minimum IP TTL observed on the flow",
    "SHORTEST_FLOW_PKT":           "Size of the smallest packet in the flow",
    "TCP_WIN_MAX_IN":              "Maximum TCP receive window advertised inbound",
    "Packet_Density":              "Bytes carried per inbound packet (IN_BYTES / IN_PKTS)",
    "Flow_Symmetry":               "Ratio of outbound to inbound bytes",
    "Symmetry_Ratio":              "Ratio of inbound to outbound packets",
    "Byte_Symmetry":               "Share of total bytes that are inbound",
    "Packet_Rate":                 "Total packets per second across the flow",
    "Byte_Rate":                   "Total bytes per second across the flow",
    "Aggressiveness":              "Inbound byte rate relative to flow duration",
    "Pkt_Size_Avg":                "Average packet size for the flow",
    "Is_SYN_Only":                 "Flow consists only of a TCP SYN with no completed handshake",
    "Is_Common_Port":              "Destination port is a well-known service port",
}

ANOMALY_FEATURE_DESCRIPTIONS = {
    "IN_BYTES":                    "Bytes sent from source to destination",
    "IN_PKTS":                     "Packets sent from source to destination",
    "OUT_BYTES":                   "Bytes returned from destination to source",
    "OUT_PKTS":                    "Packets returned from destination to source",
    "AVG_PKT_SIZE":                "Average packet size for the flow",
    "PKT_SIZE_CV":                 "Coefficient of variation of packet size (burstiness of sizes)",
    "LONGEST_FLOW_PKT":            "Largest packet observed in the flow",
    "SHORTEST_FLOW_PKT":           "Smallest packet observed in the flow",
    "IS_CONSTANT_PKT_SIZE":        "All packets in the flow are the same size",
    "PKT_SIZE_APPROX_VAR":         "Spread between largest and smallest packet size",
    "BURSTINESS":                  "Packet-size variance relative to average packet size",
    "SPARSITY":                    "Flow duration relative to packet count (gaps between packets)",
    "FLOW_BALANCE":                "Directional balance between inbound and outbound bytes",
    "BYTE_RATIO":                  "Ratio of inbound to outbound bytes",
    "UPLOAD_DOWNLOAD_RATIO":       "Ratio of inbound bytes to outbound bytes",
    "BYTE_ASYMMETRY_V2":           "Normalized inbound/outbound byte imbalance",
    "FLOW_DURATION_MILLISECONDS":  "Total duration of the flow",
    "PKTS_PER_MS":                 "Packet rate per millisecond",
    "FLOW_TOO_LONG_NO_REPLY":      "Flow ran long with no response traffic from the destination",
    "TCP_FLAGS":                   "Cumulative TCP flags observed on the flow",
    "SERVER_TCP_FLAGS":            "Cumulative TCP flags observed from the destination side",
    "FLAG_MISMATCH":               "Discrepancy between client-side and server-side TCP flags",
    "IS_RISK_PORT":                "Destination port is on the high-risk port list",
    "IS_RARE_PORT":                "Destination port is not a commonly used service port",
    "REQ_RES_RATIO":               "Ratio of request packets to response packets",
    "OUT_PKTS_PER_SEC":            "Outbound packet rate",
    "PKT_ENTROPY_APPROX":          "Approximate entropy of inbound/outbound packet split",
    "HANDSHAKE_COMPLETENESS":      "Whether a full TCP handshake was observed",
    "SERVER_SILENT":               "Destination never sent any TCP flags back",
}


# ══════════════════════════════════════════════════════════════════════════════
# IDS explanation
# ══════════════════════════════════════════════════════════════════════════════
def get_ids_feature_contributions(
    lgbm_model,
    transformed_row,               # 1-row DataFrame, exact same row passed to predict_proba
    feature_order: list[str],
    predicted_class_index: int,
    top_n: int = 5,
) -> list[dict]:
    """
    Ranks the real IDS features by their contribution to the predicted class
    using LightGBM's pred_contrib (SHAP-style additive contributions), if the
    loaded model exposes a booster. Falls back to an empty list (caller then
    omits per-feature contributions but still reports the prediction) if the
    model doesn't support it — this only happens if a non-LightGBM object is
    loaded, which should not occur in production.
    """
    booster = getattr(lgbm_model, "booster_", None) or getattr(lgbm_model, "booster", None)
    if booster is None:
        return []

    try:
        contrib = booster.predict(transformed_row, pred_contrib=True)
    except Exception:
        return []

    contrib = np.asarray(contrib)
    n_features = len(feature_order)

    # Multiclass pred_contrib layout: (n_features+1) values per class, per class stacked.
    if contrib.ndim == 2 and contrib.shape[1] == (n_features + 1):
        # Binary / single-row-single-block case
        row = contrib[0]
    else:
        row = contrib.reshape(-1)
        expected_len = (n_features + 1)
        # Slice out this class's block
        start = predicted_class_index * expected_len
        row = row[start:start + expected_len]

    feature_contribs = row[:n_features]  # last value is the expected-value bias term

    ranked_idx = np.argsort(-np.abs(feature_contribs))[:top_n]

    out = []
    for i in ranked_idx:
        fname = feature_order[i]
        out.append({
            "feature": fname,
            "value": transformed_row.iloc[0][fname] if fname in transformed_row.columns else None,
            "contribution": round(float(feature_contribs[i]), 4),
        })
    return out


def _cap_first(s: str) -> str:
    """Capitalize only the first character; leaves the rest (e.g. acronyms) untouched."""
    return s[0].upper() + s[1:] if s else s


def _ids_feature_reason(fname: str) -> str:
    
    if fname in HUMAN_IDS_REASONS:
        return HUMAN_IDS_REASONS[fname]
    desc = IDS_FEATURE_DESCRIPTIONS.get(fname, fname.replace("_", " ").lower())
    return f"{_cap_first(desc)} was atypical for this type of traffic"


def build_ids_explanation(
    ids_label: str,
    ids_confidence: float,
    contributions: list[dict],
    raw_engineered_features: dict,
) -> dict:
    
    top_features = [{"reason": _ids_feature_reason(c["feature"])} for c in contributions]

    if ids_label.lower() in ("benign", "normal"):
        notes = (
            f"Traffic on this flow was classified as normal with {ids_confidence:.1%} confidence; "
            f"no attack behavior was identified."
        )
    elif top_features:
        reasons = "; ".join(f["reason"] for f in top_features[:2])
        notes = (
            f"Traffic was classified as '{ids_label}' with {ids_confidence:.1%} confidence. {reasons}."
        )
    else:
        notes = (
            f"Traffic was classified as '{ids_label}' with {ids_confidence:.1%} confidence "
            f"based on overall flow behavior."
        )

    return {
        "label": ids_label,
        "confidence": round(float(ids_confidence), 4),
        "top_features": top_features,
        "notes": notes,
    }


# ══════════════════════════════════════════════════════════════════════════════
# Anomaly explanation
# ══════════════════════════════════════════════════════════════════════════════
def get_anomaly_feature_deviations(
    scaler,
    feature_row: dict,       # {feature_name: preprocessed_value} for this model's feature list
    feature_list: list[str],
    top_n: int = 5,
) -> list[dict]:
    
    if hasattr(scaler, "mean_"):
        center = scaler.mean_
    elif hasattr(scaler, "center_"):
        center = scaler.center_
    else:
        return []

    scale_ = getattr(scaler, "scale_", None)
    if scale_ is None:
        return []

    z_scores = {}
    for i, fname in enumerate(feature_list):
        if fname not in feature_row:
            continue
        val = feature_row[fname]
        sd = scale_[i] if scale_[i] != 0 else 1e-6
        z = (val - center[i]) / sd
        z_scores[fname] = (val, float(z))

    ranked = sorted(z_scores.items(), key=lambda kv: -abs(kv[1][1]))[:top_n]
    out = []
    for fname, (val, z) in ranked:
        out.append({"feature": fname, "value": val, "z_score": round(z, 3)})
    return out


def _anomaly_feature_reason(fname: str, z_score: float) -> str:
    
    if fname in ANOMALY_HUMAN_REASONS:
        return ANOMALY_HUMAN_REASONS[fname]
    desc = ANOMALY_FEATURE_DESCRIPTIONS.get(fname, fname.replace("_", " ").lower())
    direction = "higher" if z_score > 0 else "lower"
    magnitude = "substantially" if abs(z_score) >= 3 else ("moderately" if abs(z_score) >= 1.5 else "slightly")
    return f"{_cap_first(desc)} is {magnitude} {direction} than typical for this type of traffic"


def build_anomaly_explanation(
    model_key: str,
    raw_score: float,
    anomaly_norm: float,
    threshold: float,
    deviations: list[dict],
) -> dict:
    
    is_anom = anomaly_norm >= ANOMALY_NORM_BOUNDARY
    sev = get_anomaly_severity(anomaly_norm)

    signals = [_anomaly_feature_reason(d["feature"], d["z_score"]) for d in deviations[:3]]

    if is_anom:
        notes = (
            f"Traffic on this flow deviates from normal baseline behavior for this connection "
            f"type, classified as {sev} severity."
        )
    elif anomaly_norm >= ANOMALY_NORMAL_MAX:
        notes = (
            f"Traffic on this flow shows some deviation from typical baseline behavior, "
            f"flagged as {sev} for review."
        )
    else:
        notes = f"Traffic on this flow is within normal expected behavior ({sev} severity)."

    if signals:
        notes += f" {signals[0]}."

    return {
        "model": model_key,
        "raw_score": round(float(raw_score), 6),
        "normalized_score": round(float(anomaly_norm), 4),
        "threshold": round(float(threshold), 4),
        "is_anomaly": bool(is_anom),
        "severity": sev,
        "top_signals": signals,
        "notes": notes,
    }


# ══════════════════════════════════════════════════════════════════════════════
# RL mitigation explanation — observable evidence only, no model internals
# ══════════════════════════════════════════════════════════════════════════════
def build_rl_explanation(
    action_id: int,
    ids: IDSOutput,
    anomaly_norm: float,
    hist: IPHistory,
    net: NetworkState,
    mask: list,
) -> dict:
    
    action_name = ACTION_NAMES[action_id]
    is_anom = anomaly_norm >= ANOMALY_NORM_BOUNDARY
    evidence = []

    evidence.append({
        "feature": "ids_confidence",
        "value": round(float(ids.confidence), 4),
        "reason": (
            f"The IDS reports {ids.confidence:.1%} confidence in the "
            f"'{ATTACK_NAMES.get(ids.attack_type, 'unknown')}' classification."
        ),
    })
    evidence.append({
        "feature": "repeat_count",
        "value": hist.repeat_count,
        "reason": (
            "This is the first occurrence from this source." if hist.repeat_count == 0
            else f"This source has been observed {hist.repeat_count} time(s) previously."
        ),
    })
    evidence.append({
        "feature": "same_attack_count",
        "value": hist.same_attack_count,
        "reason": (
            f"The same attack type has recurred {hist.same_attack_count} time(s) in a row from this source."
            if hist.same_attack_count > 1
            else "No repeated pattern of the same attack type from this source yet."
        ),
    })
    evidence.append({
        "feature": "anomaly_score",
        "value": round(float(anomaly_norm), 4),
        "reason": (
            "Anomaly detection flagged this traffic as unusual compared to normal baseline behavior."
            if is_anom else
            "Anomaly detection did not flag significant deviation from normal baseline behavior."
        ),
    })
    evidence.append({
        "feature": "dest_pressure_ratio",
        "value": round(float(net.dest_pressure_ratio), 3),
        "reason": (
            "Traffic load on the destination is elevated compared to normal levels."
            if net.dest_pressure_ratio > DDOS_MIN_PRESSURE else
            "Traffic load on the destination is within normal levels."
        ),
    })
    evidence.append({
        "feature": "unique_sources",
        "value": net.unique_sources,
        "reason": (
            f"{net.unique_sources} unique source(s) are targeting this destination"
            + (", which is an unusually high number for this destination." if net.unique_sources > DDOS_MIN_SOURCES else ".")
        ),
    })
    evidence.append({
        "feature": "dest_new_conn_rate",
        "value": round(float(net.dest_new_conn_rate), 2),
        "reason": (
            f"New connection rate to this destination is {net.dest_new_conn_rate:.1f}/sec"
            + (", which is well above the normal range for this destination." if net.dest_new_conn_rate >= DDOS_MIN_CONNRATE else ".")
        ),
    })

    # ── Reason for the specific action, built from the same evidence ──────────
    if action_id == A4_A5_DDOS:
        reason = (
            f"Distributed attack conditions are met: {net.unique_sources} sources, "
            f"elevated load on the destination, a connection rate of "
            f"{net.dest_new_conn_rate:.1f}/sec, and IDS confidence {ids.confidence:.1%} — "
            f"together these are consistent with a distributed attack, so per-source rate "
            f"metering and destination-side SYN protection were applied together."
        )
    elif action_id == A3_PERM_BLOCK:
        if ids.confidence > 0.8 and anomaly_norm > 0.5 and hist.repeat_count > 2:
            reason = (
                f"IDS confidence ({ids.confidence:.1%}), anomaly detection, and repeat count "
                f"({hist.repeat_count}) all strongly agree this source is malicious, justifying "
                f"a permanent block."
            )
        else:
            reason = (
                f"This source has repeated a high-severity attack "
                f"('{ATTACK_NAMES.get(ids.attack_type, 'unknown')}') {hist.repeat_count} time(s), "
                f"which justifies escalating from temporary to permanent block."
            )
    elif action_id == A2_TEMP_BLOCK:
        reason = (
            f"The traffic is confirmed malicious "
            f"('{ATTACK_NAMES.get(ids.attack_type, 'unknown')}', confidence {ids.confidence:.1%}) "
            f"with {hist.repeat_count} prior occurrence(s) from this source, warranting a temporary block "
            f"while stopping short of a permanent block."
        )
    elif action_id == A1_RATE_LIMIT:
        if ids.attack_type == ATTACK_NORMAL:
            reason = (
                "No confirmed IDS attack, but anomaly detection flagged this traffic as unusual, "
                "so the source is rate-limited pending further evidence."
            )
        else:
            reason = (
                f"The traffic appears malicious "
                f"('{ATTACK_NAMES.get(ids.attack_type, 'unknown')}', confidence {ids.confidence:.1%}), "
                f"but this is the first occurrence from this source, so current evidence does not yet "
                f"justify a full block — rate limiting was applied instead."
            )
    else:  # A0_MONITOR
        reason = (
            f"IDS confidence ({ids.confidence:.1%}) and anomaly detection are both below the level "
            f"needed to trigger active mitigation — traffic is being monitored without active mitigation."
        )

    
    evidence_priority = {
        A0_MONITOR:    ["ids_confidence", "anomaly_score", "repeat_count"],
        A1_RATE_LIMIT: ["ids_confidence", "repeat_count", "anomaly_score"],
        A2_TEMP_BLOCK: ["ids_confidence", "repeat_count", "same_attack_count"],
        A3_PERM_BLOCK: ["repeat_count", "ids_confidence", "anomaly_score"],
        A4_A5_DDOS:    ["dest_pressure_ratio", "unique_sources", "dest_new_conn_rate"],
    }
    by_feature = {e["feature"]: e for e in evidence}
    priority = evidence_priority.get(action_id, [e["feature"] for e in evidence])
    top_evidence = [by_feature[f] for f in priority if f in by_feature][:3]

    return {
        "selected_action": action_name,
        "action_id": action_id,
        "reason": reason,
        "evidence": top_evidence,
        "action_mask": {ACTION_NAMES[i]: bool(mask[i]) for i in range(len(mask))},
    }


# ══════════════════════════════════════════════════════════════════════════════
# Dashboard-facing fields
# ══════════════════════════════════════════════════════════════════════════════
def build_dashboard_fields(
    ids: IDSOutput,
    anomaly_norm: float,
    anomaly_raw: float,
    action_id: int,
    net: NetworkState,
    hist: IPHistory,
    ids_top_feature: dict | None,
) -> dict:
    
    at = ids.attack_type
    is_anom = anomaly_norm >= ANOMALY_NORM_BOUNDARY

    # ── guide: what action was taken ────────────────────────────────────────
    guide_by_action = {
        A0_MONITOR:    "Continue monitoring this source; no active mitigation required at this time.",
        A1_RATE_LIMIT: "Apply rate limiting to this source and continue monitoring for escalation.",
        A2_TEMP_BLOCK: "Apply a temporary block to this source pending further observation.",
        A3_PERM_BLOCK: "Apply a permanent block; this source has repeatedly confirmed malicious behavior.",
        A4_A5_DDOS:    "Apply DDoS mitigation controls and continue monitoring destination service availability.",
    }
    guide = guide_by_action[action_id]

    # ── detected_pattern: what was detected + why it's suspicious ──────────
    if action_id == A4_A5_DDOS or at == ATTACK_DDOS:
        pattern = (
            f"Distributed denial-of-service (DDoS) activity detected. {net.unique_sources} distinct "
            f"sources are sending traffic to this destination at a combined rate of "
            f"{net.dest_new_conn_rate:.0f} new connections/sec, and the destination is showing signs "
            f"of load pressure beyond normal levels."
        )
    elif at == ATTACK_SCAN:
        pattern = (
            f"Port scanning activity detected from this source, with {ids.confidence:.1%} IDS confidence. "
            + (
                f"This behavior has been observed {hist.repeat_count} time(s) from this source before."
                if hist.repeat_count > 0 else
                "This is the first time this behavior has been observed from this source."
            )
        )
    elif at in (ATTACK_BRUTE, ATTACK_PASSWORD):
        pattern = (
            f"{ATTACK_NAMES[at]} activity detected, with {ids.confidence:.1%} IDS confidence. "
            + (
                f"The same attack type has recurred {hist.same_attack_count} time(s) in a row from this source."
                if hist.same_attack_count > 1 else
                "This is the first occurrence of this attack type from this source."
            )
        )
    elif at in (ATTACK_INJECT, ATTACK_XSS):
        pattern = (
            f"{ATTACK_NAMES[at]} activity detected in web traffic, with {ids.confidence:.1%} IDS confidence. "
            + (
                f"This source has triggered {hist.repeat_count} similar detection(s) before."
                if hist.repeat_count > 0 else
                "This is the first detection of this kind from this source."
            )
        )
    elif at == ATTACK_DOS:
        pattern = (
            f"Denial-of-service activity detected, with {ids.confidence:.1%} IDS confidence and a "
            f"connection rate of {net.dest_new_conn_rate:.0f}/sec toward this destination."
        )
    elif is_anom:
        pattern = (
            "Traffic deviates from normal baseline behavior for this type of connection, though no "
            "specific attack signature was confirmed. "
            + (
                f"This behavior has recurred {hist.repeat_count} time(s) from this source."
                if hist.repeat_count > 0 else
                "This is the first time this behavior has been observed from this source."
            )
        )
    else:
        pattern = (
            f"No significant attack pattern detected. Traffic is classified as normal with "
            f"{ids.confidence:.1%} IDS confidence."
        )

    if ids_top_feature and at != ATTACK_NORMAL and ids_top_feature.get("reason"):
        pattern += f" {ids_top_feature['reason']}."

    return {"guide": guide, "detected_pattern": pattern}


def build_consolidated_summary(
    ids_explanation: dict,
    anomaly_explanation: dict,
    rl_explanation: dict,
    final_severity: str,
) -> dict:
    
    summary = (
        f"[{final_severity}] {ids_explanation['label']} detected with "
        f"{ids_explanation['confidence']:.1%} IDS confidence. "
        f"Mitigation applied: {rl_explanation['selected_action']}."
    )
    analyst_notes = " ".join([ids_explanation["notes"], anomaly_explanation["notes"]])
    return {
        "summary": summary,
        "analyst_notes": analyst_notes,
        "mitigation_reason": rl_explanation["reason"],
        "evidence": rl_explanation["evidence"],
    }
