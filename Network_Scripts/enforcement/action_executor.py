from __future__ import annotations
import logging

from config import settings
from enforcement import nft_rules
from enforcement.rule_scheduler import RuleScheduler
from state import ewma_store

log = logging.getLogger("Net-Knight.action_executor")

A0_MONITOR, A1_RATE_LIMIT, A2_TEMP_BLOCK, A3_PERM_BLOCK, A4_A5_DDOS = 0, 1, 2, 3, 4


def _resolve_temp_block_duration(attack_category: str, ids_confirmed: bool, anomaly_flag: bool) -> int:
    if ids_confirmed and anomaly_flag:
        return settings.TEMP_BLOCK_DURATION_SEC["anomaly_with_attack"]
    if ids_confirmed:
        return settings.TEMP_BLOCK_DURATION_SEC.get(attack_category, settings.TEMP_BLOCK_DURATION_SEC["dos"])
    return settings.TEMP_BLOCK_DURATION_SEC["anomaly_only"]


class ActionExecutor:
    def __init__(self, scheduler: RuleScheduler):
        self.scheduler = scheduler

    def execute(self, decision: dict, dry_run: bool = False) -> dict | None:

        action_id = decision["action_id"]
        chain = nft_rules.determine_chain(decision["dst_ip"])

        if action_id == A0_MONITOR:
            return None

        if action_id == A1_RATE_LIMIT:
            return self._execute_rate_limit(decision, chain, dry_run)

        if action_id == A2_TEMP_BLOCK:
            duration = _resolve_temp_block_duration(
                decision["attack_category"], decision["ids_confirmed"], decision["anomaly_flag"]
            )
            deletion = None if dry_run else nft_rules.add_temp_block(decision["src_ip"], duration)
            return {"kind": "temp_block", "duration_sec": duration, "deletion": deletion}

        if action_id == A3_PERM_BLOCK:
            deletion = None if dry_run else nft_rules.add_perm_block(decision["src_ip"])
            return {"kind": "perm_block", "deletion": deletion}

        if action_id == A4_A5_DDOS:
            return self._execute_ddos(decision, chain, dry_run)

        log.warning(f"action_id غير معروف: {action_id}")
        return None

    # ── A1 ───────────────────────────────────────────────────────────────
    def _execute_rate_limit(self, decision: dict, chain: str, dry_run: bool = False) -> dict | None:
        category = decision["attack_category"]
        src_ip = decision["src_ip"]

        if category in ("anomaly", "scanning", "brute_force"):
            port = decision.get("dst_port") if category == "brute_force" else None
            rate_desc = (
                f"{settings.RATE_LIMIT_PER_MINUTE['brute_force']}/minute على المنفذ {port}"
                if category == "brute_force"
                else f"{settings.RATE_LIMIT_PPS[category]} packet/sec"
            )
            deletion = None if dry_run else nft_rules.add_rate_limit_fixed(src_ip, category, port=port)
            return {
                "kind": "rate_limit", "category": category, "rate": rate_desc,
                "duration_sec": settings.RATE_LIMIT_DURATION_SEC[category],
                "deletion": deletion,
            }

        
        dst_ip = decision["dst_ip"]
        unique_sources = max(1, int(decision.get("unique_sources", 1)))
        baseline = ewma_store.get_baseline(dst_ip)
        pps = (baseline / unique_sources) if baseline else settings.DOS_RATE_LIMIT_FALLBACK_PPS
        duration = settings.RATE_LIMIT_DURATION_SEC["dos"]

        if dry_run:
            return {
                "kind": "rate_limit", "category": "dos", "rate": f"{round(pps, 1)} packet/sec",
                "duration_sec": duration, "deletion": None,
            }

        deletion = nft_rules.add_dos_rate_limit(src_ip, chain, pps)
        if deletion is None:
            return None
        self.scheduler.schedule_deletion(deletion, duration)
        return {
            "kind": "rate_limit", "category": "dos", "rate": f"{round(pps, 1)} packet/sec",
            "duration_sec": duration, "deletion": deletion,
        }

    # ── A4 + A5 ──────────────────────────────────────────────────────────
    def _execute_ddos(self, decision: dict, chain: str, dry_run: bool = False) -> dict | None:
        dst_ip = decision["dst_ip"]
        unique_sources = max(1, int(decision.get("unique_sources", 1)))
        baseline = ewma_store.get_baseline(dst_ip) or settings.DOS_RATE_LIMIT_FALLBACK_PPS

        per_source_pps = baseline / unique_sources
        syn_pps = baseline * settings.DDOS_A5_SYN_RATIO
        duration = settings.NFT_DYNAMIC_RULE_DEFAULT_DURATION_SEC

        if dry_run:
            return {
                "kind": "ddos_response",
                "dest_ip": dst_ip,
                "a4_per_source_rate": f"{round(per_source_pps, 1)} packet/sec",
                "a5_syn_rate": f"{round(syn_pps, 1)} packet/sec",
                "duration_sec": duration,
                "deletion": None,
                "deletion_syn": None,
            }

        meter_deletion = nft_rules.add_ddos_meter(dst_ip, chain, per_source_pps)
        syn_deletion = nft_rules.add_ddos_syn_limit(dst_ip, chain, syn_pps)

        if meter_deletion:
            self.scheduler.schedule_deletion(meter_deletion, duration)
        if syn_deletion:
            self.scheduler.schedule_deletion(syn_deletion, duration)

        return {
            "kind": "ddos_response",
            "dest_ip": dst_ip,
            "a4_per_source_rate": f"{round(per_source_pps, 1)} packet/sec",
            "a5_syn_rate": f"{round(syn_pps, 1)} packet/sec",
            "duration_sec": duration,
           
            "deletion": meter_deletion,          
            "deletion_syn": syn_deletion,        
        }
