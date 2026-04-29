"""
routes/firewall.py — endpoints الـ nftables (execution)
نفس الـ responses الأصلية + حفظ تلقائي بعد كل عملية ناجحة.
"""
from __future__ import annotations

from flask import Blueprint, jsonify, request

from builders import build_nat_expr, build_rule_expr
from helpers  import get_rule_handle, run_command, save_rules, register_table
from logger   import log_error, log_request, log_success

bp = Blueprint("firewall", __name__, url_prefix="/api")


def _ensure_nat_table() -> None:
    """
    بتتأكد إن nk_nat table والـ chains موجودين.
    لو موجودين أصلاً nft بيتجاهل الأمر من غير error.
    """
    run_command(["nft", "add", "table", "ip", "nk_nat"])
    run_command([
        "nft", "add", "chain", "ip", "nk_nat", "postrouting",
        "{", "type", "nat", "hook", "postrouting", "priority", "100", ";", "}"
    ])
    run_command([
        "nft", "add", "chain", "ip", "nk_nat", "prerouting",
        "{", "type", "nat", "hook", "prerouting", "priority", "-100", ";", "}"
    ])
    register_table("ip", "nk_nat")


@bp.route('/create_table', methods=['POST'])
def create_table():
    data       = request.json
    table_name = data.get('table_name')
    family     = data.get('family', 'ip')

    log_request('create_table', data)

    if not table_name:
        return jsonify({"status": "error", "message": "table_name required"})

    command  = ["nft", "add", "table", family, table_name]
    rule_str = f"nft add table {family} {table_name}"
    result   = run_command(command)

    if result["status"] == "success":
        result["rule"] = rule_str
        register_table(family, table_name)
        save_rules()   # 💾 حفظ دائم
        log_success('create_table', rule_str)
    else:
        log_error('create_table', rule_str, result["output"])

    return jsonify(result)


@bp.route('/create_chain', methods=['POST'])
def create_chain():
    data       = request.json
    table_name = data.get('table_name')
    chain_name = data.get('chain_name')
    hook       = data.get('hook')
    priority   = data.get('priority', 0)
    policy     = data.get('policy', 'accept')
    chain_type = data.get('chain_type', 'filter')
    family     = data.get('family', 'ip')

    log_request('create_chain', data)

    if not table_name or not chain_name:
        return jsonify({"status": "error", "message": "table_name and chain_name required"})

    command  = [
        "nft", "add", "chain", family, table_name, chain_name,
        "{", "type", chain_type, "hook", hook, "priority", str(priority), ";",
        "policy", policy, ";", "}"
    ]
    rule_str = (
        f"nft add chain {family} {table_name} {chain_name} "
        f"{{ type {chain_type} hook {hook} priority {priority}; policy {policy}; }}"
    )
    result = run_command(command)

    if result["status"] == "success":
        result["rule"] = rule_str
        save_rules()   # 💾 حفظ دائم
        log_success('create_chain', rule_str)
    else:
        log_error('create_chain', rule_str, result["output"])

    return jsonify(result)


@bp.route('/add_rule', methods=['POST'])
def add_rule():
    data       = request.json
    table_name = data.get('table_name')
    chain_name = data.get('chain_name')
    family     = data.get('family', 'ip')
    comment    = data.get('comment')

    log_request('add_rule', data)

    if not table_name or not chain_name:
        return jsonify({"status": "error", "message": "table_name and chain_name required"})

    rule_str, cmd = build_rule_expr(
        family     = family,
        table_name = table_name,
        chain_name = chain_name,
        ip_src     = data.get('ip_src', ''),
        ip_dest    = data.get('ip_dest', ''),
        port_dest  = data.get('port_dest', ''),
        interface  = data.get('interface', ''),
        protocol   = data.get('protocol', ''),
        action     = data.get('action', 'accept'),
    )

    if comment:
        cmd += ["comment", comment]

    result = run_command(cmd)

    if result["status"] == "success":
        handle = get_rule_handle(family, table_name, chain_name, comment)
        result["rule"]    = rule_str
        if comment:
            result["rule"] += f' comment "{comment}"'
        result["handle"]  = handle
        result["comment"] = comment
        save_rules()   # 💾 حفظ دائم
        log_success('add_rule', result["rule"], {"handle": handle, "comment": comment})
    else:
        log_error('add_rule', rule_str, result["output"])

    return jsonify(result)


@bp.route('/add_nat', methods=['POST'])
def add_nat():
    data     = request.json
    nat_type = data.get('nat_type')
    comment  = data.get('comment')

    log_request('add_nat', data)

    if not nat_type:
        return jsonify({"status": "error", "message": "nat_type required"})

    # تأكد إن nk_nat table والـ chains موجودين
    _ensure_nat_table()

    built = build_nat_expr(data)
    if built is None:
        if nat_type == "masquerade":
            return jsonify({"status": "error", "message": "source_ip and output_interface required"})
        elif nat_type == "source":
            return jsonify({"status": "error", "message": "source_ip and new_source_ip required"})
        elif nat_type == "destination":
            return jsonify({"status": "error", "message": "input_interface, dest_ip, int_port required"})
        else:
            return jsonify({"status": "error", "message": "Invalid NAT type"})

    rule_str, cmd, chain_name = built

    if comment:
        cmd      += ["comment", comment]
        rule_str += f' comment "{comment}"'

    result = run_command(cmd)

    if result["status"] == "success":
        handle = get_rule_handle("ip", "nk_nat", chain_name, comment)
        result["rule"]    = rule_str
        result["handle"]  = handle
        result["comment"] = comment
        save_rules()   # 💾 حفظ دائم
        log_success('add_nat', rule_str, {"handle": handle, "comment": comment})
    else:
        log_error('add_nat', rule_str, result["output"])

    return jsonify(result)


@bp.route('/delete_rule', methods=['DELETE'])
def delete_rule():
    data   = request.json
    family = data.get('family', 'ip')
    table  = data.get('table')
    chain  = data.get('chain')
    handle = data.get('handle')

    log_request('delete_rule', data)

    if not all([table, chain, handle]):
        return jsonify({"status": "error", "message": "table, chain, handle required"})

    command  = ["nft", "delete", "rule", family, table, chain, "handle", str(handle)]
    rule_str = f"nft delete rule {family} {table} {chain} handle {handle}"
    result   = run_command(command)

    if result["status"] == "success":
        result["message"] = f"Rule with handle {handle} deleted"
        save_rules()   # 💾 حفظ دائم
        log_success('delete_rule', rule_str, {"handle": handle})
    else:
        log_error('delete_rule', rule_str, result["output"])

    return jsonify(result)


@bp.route('/delete_nat', methods=['DELETE'])
def delete_nat():
    data     = request.json
    nat_type = data.get('nat_type')
    handle   = data.get('handle')

    log_request('delete_nat', data)

    if not all([nat_type, handle]):
        return jsonify({"status": "error", "message": "nat_type and handle required"})

    # ستاتيك زي ما هو في builders
    chain_map = {
        "masquerade":  "postrouting",
        "source":      "postrouting",
        "destination": "prerouting",
    }

    chain = chain_map.get(nat_type)
    if not chain:
        return jsonify({"status": "error", "message": "Invalid nat_type"})

    # family و table ستاتيك زي builders
    command  = ["nft", "delete", "rule", "ip", "nk_nat", chain, "handle", str(handle)]
    rule_str = f"nft delete rule ip nk_nat {chain} handle {handle}"
    result   = run_command(command)

    if result["status"] == "success":
        result["message"] = f"NAT rule with handle {handle} deleted"
        save_rules()   # 💾 حفظ دائم
        log_success('delete_nat', rule_str, {"handle": handle})
    else:
        log_error('delete_nat', rule_str, result["output"])

    return jsonify(result)