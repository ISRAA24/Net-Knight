"""
core/builders.py — بناء nft expressions
"""
from __future__ import annotations


def build_rule_expr(
    family: str,
    table_name: str,
    chain_name: str,
    ip_src: str = "",
    ip_dest: str = "",
    port_dest: str = "",
    interface: str = "",
    protocol: str = "",
    action: str = "accept",
) -> tuple[str, list[str]]:
    """
    يبني الـ rule expression.
    بيرجع: (rule_string, cmd_list)
    """
    parts = []
    if interface:   parts.append(f"iif {interface}")
    if ip_src:      parts.append(f"ip saddr {ip_src}")
    if ip_dest:     parts.append(f"ip daddr {ip_dest}")
    if protocol and port_dest:
        port_dest = str(port_dest)
        ports = [p.strip() for p in port_dest.replace(',', ' ').split() if p.strip()]
        ports_str = f"{{ {', '.join(ports)} }}" if len(ports) > 1 else ports[0] if ports else ""
        parts.append(f"{protocol} dport {ports_str}")
    parts.append(action)

    rule_expr = " ".join(filter(None, parts))
    cmd = ["nft", "add", "rule", family, table_name, chain_name] + rule_expr.split()
    rule_str = f"nft add rule {family} {table_name} {chain_name} {rule_expr}"

    return rule_str, cmd


def build_nat_expr(data: dict) -> tuple[str, list[str], str] | None:
    """
    يبني الـ NAT command.
    بيرجع: (rule_string, cmd_list, chain_name)
    أو None لو الـ nat_type غلط.
    """
    nat_type = data.get('nat_type')

    if nat_type == "masquerade":
        source_ip = data.get('source_ip')
        oif       = data.get('output_interface')
        if not source_ip or not oif:
            return None
        cmd      = ["nft", "add", "rule", "ip", "nk_nat", "postrouting",
                    "ip", "saddr", source_ip, "oif", oif, "masquerade"]
        rule_str = f"nft add rule ip nk_nat postrouting ip saddr {source_ip} oif {oif} masquerade"
        return rule_str, cmd, "postrouting"

    if nat_type == "source":
        source_ip = data.get('source_ip')
        new_ip    = data.get('new_source_ip')
        oif       = data.get('output_interface')  # اختياري
        if not source_ip or not new_ip:
            return None
        cmd = ["nft", "add", "rule", "ip", "nk_nat", "postrouting",
               "ip", "saddr", source_ip]
        if oif:
            cmd += ["oif", oif]
        cmd += ["snat", "to", new_ip]
        rule_str = f"nft add rule ip nk_nat postrouting ip saddr {source_ip}"
        if oif:
            rule_str += f" oif {oif}"
        rule_str += f" snat to {new_ip}"
        return rule_str, cmd, "postrouting"

    if nat_type == "destination":
        iif      = data.get('input_interface')
        dest_ip  = data.get('dest_ip')
        int_port = data.get('int_port')
        protocol = data.get('protocol')
        ext_port = data.get('ext_port')

        if not iif or not dest_ip or not int_port:
            return None

        proto_part = f"{protocol} dport {ext_port}" if protocol and ext_port else ""
        cmd = ["nft", "add", "rule", "ip", "nk_nat", "prerouting", "iif", iif]
        if proto_part:
            cmd += proto_part.split()
        cmd += ["dnat", "to", f"{dest_ip}:{int_port}"]

        rule_str = f"nft add rule ip nk_nat prerouting iif {iif}"
        if proto_part:
            rule_str += f" {proto_part}"
        rule_str += f" dnat to {dest_ip}:{int_port}"

        return rule_str, cmd, "prerouting"

    return None