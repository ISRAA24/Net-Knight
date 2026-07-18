from __future__ import annotations
import logging
import os
import re
import subprocess
import threading

from config import settings

log = logging.getLogger("Net-Knight.nft")

FAMILY = settings.NFT_FAMILY
TABLE = settings.NFT_TABLE

PERM_BLOCKS_STATE_FILE = "/var/lib/netknight/perm_blocks.json"
PERSIST_FILE = "/etc/nftables/netknight.conf"


# ══════════════════════════════════════════════════════════════════════════════
# nft Commands execution
# ══════════════════════════════════════════════════════════════════════════════
def _run(args: list[str], input_text: str | None = None) -> subprocess.CompletedProcess:
    proc = subprocess.run(
        args, input=input_text, capture_output=True, text=True,
    )
    if proc.returncode != 0:
        log.error(f"nft command failed: {' '.join(args)}\n{proc.stderr.strip()}")
    return proc


def _nft(*parts: str) -> subprocess.CompletedProcess:
    return _run(["nft", *parts])


def _table_exists() -> bool:
    return _run(["nft", "list", "table", FAMILY, TABLE]).returncode == 0


def ensure_base_structures() -> None:
    
    if _table_exists():
        log.info(f"✅ nftables: جدول {FAMILY} {TABLE} already exist.")
        _restore_permanent_blocks()
        return

    script = _generate_full_ruleset_script()
    proc = _run(["nft", "-f", "-"], input_text=script)
    if proc.returncode == 0:
        log.info("✅ nftables: تم إنشاء البنية الأساسية (جدول/سلاسل/sets) من الصفر.")
    else:
        log.error("❌ فشل إنشاء البنية الأساسية — راجعي صلاحيات root/CAP_NET_ADMIN.")
    persist()


def _base_script_body(perm_ips: list[str] | None = None) -> str:
    perm_ips = perm_ips or []
    perm_elements = ", ".join(perm_ips) if perm_ips else ""
    lines = [
        f"table {FAMILY} {TABLE} {{",
        f"  set {settings.NFT_SET_TEMP_BLOCK} {{ type ipv4_addr; flags timeout; }}",
        f"  set {settings.NFT_SET_PERM_BLOCK} {{ type ipv4_addr; " + (f"elements = {{ {perm_elements} }}; " if perm_elements else "") + "}",
        f"  set {settings.NFT_SET_RL_ANOMALY} {{ type ipv4_addr; flags timeout; }}",
        f"  set {settings.NFT_SET_RL_SCANNING} {{ type ipv4_addr; flags timeout; }}",
        f"  set {settings.NFT_SET_RL_BRUTEFORCE} {{ type ipv4_addr . inet_service; flags timeout; }}",
        f"  chain {settings.NFT_CHAIN_INPUT} {{",
        f"    type filter hook input priority -10; policy accept;",
        f"    ip saddr @{settings.NFT_SET_PERM_BLOCK} drop",
        f"    ip saddr @{settings.NFT_SET_TEMP_BLOCK} drop",
        f"    ip saddr @{settings.NFT_SET_RL_ANOMALY} limit rate over {settings.RATE_LIMIT_PPS['anomaly']}/second drop",
        f"    ip saddr @{settings.NFT_SET_RL_SCANNING} limit rate over {settings.RATE_LIMIT_PPS['scanning']}/second drop",
        f"    ip saddr . tcp dport @{settings.NFT_SET_RL_BRUTEFORCE} limit rate over {settings.RATE_LIMIT_PER_MINUTE['brute_force']}/minute drop",
        f"  }}",
        f"  chain {settings.NFT_CHAIN_FORWARD} {{",
        f"    type filter hook forward priority -10; policy accept;",
        f"    ip saddr @{settings.NFT_SET_PERM_BLOCK} drop",
        f"    ip saddr @{settings.NFT_SET_TEMP_BLOCK} drop",
        f"    ip saddr @{settings.NFT_SET_RL_ANOMALY} limit rate over {settings.RATE_LIMIT_PPS['anomaly']}/second drop",
        f"    ip saddr @{settings.NFT_SET_RL_SCANNING} limit rate over {settings.RATE_LIMIT_PPS['scanning']}/second drop",
        f"    ip saddr . tcp dport @{settings.NFT_SET_RL_BRUTEFORCE} limit rate over {settings.RATE_LIMIT_PER_MINUTE['brute_force']}/minute drop",
        f"  }}",
        f"}}",
    ]
    return "\n".join(lines)


def _generate_full_ruleset_script() -> str:
    perm_ips = _read_perm_blocks_state()
    return _base_script_body(perm_ips)


def persist() -> None:
    
    try:
        os.makedirs(os.path.dirname(PERSIST_FILE), exist_ok=True)
        with open(PERSIST_FILE, "w") as f:
            f.write(f"flush table {FAMILY} {TABLE}\n" if _table_exists() else "")
            f.write(_generate_full_ruleset_script())
            f.write("\n")
        log.info(f"💾 nftables ruleset persisted → {PERSIST_FILE}")
    except Exception as e:
        log.error(f"❌ فشل حفظ ملف الاستمرارية: {e}")


def _perm_blocks_path() -> str:
    return PERM_BLOCKS_STATE_FILE


def _read_perm_blocks_state() -> list[str]:
    import json
    path = _perm_blocks_path()
    if not os.path.exists(path):
        return []
    try:
        with open(path) as f:
            return json.load(f)
    except Exception:
        return []


def _write_perm_blocks_state(ips: list[str]) -> None:
    import json
    path = _perm_blocks_path()
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(sorted(set(ips)), f)


def _restore_permanent_blocks() -> None:
   
    ips = _read_perm_blocks_state()
    if not ips:
        return
    current = _run(["nft", "-j", "list", "set", FAMILY, TABLE, settings.NFT_SET_PERM_BLOCK])
    for ip in ips:
        if current.returncode != 0 or ip not in (current.stdout or ""):
            _nft("add", "element", FAMILY, TABLE, settings.NFT_SET_PERM_BLOCK, "{", ip, "}")


def determine_chain(dst_ip: str) -> str:
    return settings.NFT_CHAIN_INPUT if settings.is_gateway_ip(dst_ip) else settings.NFT_CHAIN_FORWARD



def add_to_set(set_name: str, ip: str, timeout_sec: int | None, port: int | None = None) -> dict:
    element = f"{ip} . {port}" if port is not None else ip
    if timeout_sec is not None:
        _nft("add", "element", FAMILY, TABLE, set_name, "{", f"{element} timeout {timeout_sec}s", "}")
    else:
        _nft("add", "element", FAMILY, TABLE, set_name, "{", element, "}")

    deletion = {
        "mode": "set_element",
        "family": FAMILY,
        "table": TABLE,
        "set": set_name,
        "ip": ip,
    }
    if port is not None:
        deletion["port"] = port
    return deletion


def remove_from_set(set_name: str, ip: str, port: int | None = None) -> bool:
    element = f"{ip} . {port}" if port is not None else ip
    proc = _nft("delete", "element", FAMILY, TABLE, set_name, "{", element, "}")
    return proc.returncode == 0


def add_temp_block(ip: str, duration_sec: int) -> dict:
    d = add_to_set(settings.NFT_SET_TEMP_BLOCK, ip, timeout_sec=duration_sec)
    log.info(f"🔒 A2 Temp-Block: {ip} لمدة {duration_sec}s")
    return d


def add_perm_block(ip: str) -> dict:
    d = add_to_set(settings.NFT_SET_PERM_BLOCK, ip, timeout_sec=None)
    ips = _read_perm_blocks_state()
    ips.append(ip)
    _write_perm_blocks_state(ips)
    persist()   # الحظر الدائم لازم يتحفظ فورًا عشان يعيش بعد أي reboot
    log.info(f"⛔ A3 Perm-Block: {ip} (محفوظ للاستمرارية)")
    return d


def remove_perm_block(ip: str) -> bool:
    ok = remove_from_set(settings.NFT_SET_PERM_BLOCK, ip)
    ips = [x for x in _read_perm_blocks_state() if x != ip]
    _write_perm_blocks_state(ips)
    persist()
    return ok


def add_rate_limit_fixed(ip: str, category: str, port: int | None = None) -> dict:
    set_map = {
        "anomaly": settings.NFT_SET_RL_ANOMALY,
        "scanning": settings.NFT_SET_RL_SCANNING,
        "brute_force": settings.NFT_SET_RL_BRUTEFORCE,
    }
    set_name = set_map[category]
    duration = settings.RATE_LIMIT_DURATION_SEC.get(category, settings.NFT_DYNAMIC_RULE_DEFAULT_DURATION_SEC)
    d = add_to_set(set_name, ip, timeout_sec=duration, port=port if category == "brute_force" else None)
    log.info(f"🐢 A1 Rate-Limit[{category}]: {ip} لمدة {duration}s")
    return d



_HANDLE_RE = re.compile(r"#\s*handle\s+(\d+)")


def add_dynamic_rule(chain: str, rule_body: str) -> dict | None:
    
    proc = _run(["nft", "-e", "-a", "add", "rule", FAMILY, TABLE, chain, *rule_body.split()])
    if proc.returncode != 0:
        return None
    m = _HANDLE_RE.search(proc.stdout)
    if not m:
        log.error(f"nft: القاعدة اتضافت بس معرفناش نجيب الـ handle بتاعها: {proc.stdout}")
        return None
    handle = int(m.group(1))
    return {
        "mode": "handle",
        "family": FAMILY,
        "table": TABLE,
        "chain": chain,
        "handle": handle,
    }


def add_dos_rate_limit(ip: str, chain: str, dos_pps: float) -> dict | None:
    rate = max(1, int(round(dos_pps)))
    d = add_dynamic_rule(chain, f"ip saddr {ip} limit rate over {rate}/second drop")
    if d:
        log.info(f"🐢 A1 Rate-Limit[dos]: {ip} @ {rate}pps (handle={d['handle']})")
    return d


def add_ddos_meter(dst_ip: str, chain: str, per_source_pps: float) -> dict | None:
    """A4: meter لكل IP مصدر متصل بالوجهة المستهدفة، بمعدل EWMA_dest/عدد_المصادر."""
    rate = max(1, int(round(per_source_pps)))
    meter_name = f"nk_ddos_meter_{dst_ip.replace('.', '_')}"
    body = (
        f"ip daddr {dst_ip} meter {meter_name} "
        f"{{ ip saddr limit rate over {rate}/second }} drop"
    )
    d = add_dynamic_rule(chain, body)
    if d:
        log.info(f"🌊 A4 DDoS meter: dst={dst_ip} @ {rate}pps/source (handle={d['handle']})")
    return d


def add_ddos_syn_limit(dst_ip: str, chain: str, syn_pps: float) -> dict | None:
    """A5: SYN rate limit إجمالي على الوجهة نفسها."""
    rate = max(1, int(round(syn_pps)))
    body = f"ip daddr {dst_ip} tcp flags syn limit rate over {rate}/second drop"
    d = add_dynamic_rule(chain, body)
    if d:
        log.info(f"🌊 A5 SYN-Limit: dst={dst_ip} @ {rate}pps (handle={d['handle']})")
    return d


def delete_by_handle(chain: str, handle: int) -> bool:
    proc = _nft("delete", "rule", FAMILY, TABLE, chain, "handle", str(handle))
    return proc.returncode == 0



def delete_rule(deletion: dict) -> bool:
    mode = deletion.get("mode")
    if mode == "handle":
        return delete_by_handle(deletion["chain"], int(deletion["handle"]))
    if mode == "set_element":
        set_name = deletion["set"]
        ok = remove_from_set(set_name, deletion["ip"], deletion.get("port"))
        if set_name == settings.NFT_SET_PERM_BLOCK and ok:
            ips = [x for x in _read_perm_blocks_state() if x != deletion["ip"]]
            _write_perm_blocks_state(ips)
            persist()
        return ok
    log.error(f"delete_rule: mode غير معروف: {deletion}")
    return False
