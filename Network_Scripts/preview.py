"""
routes/preview.py — endpoints المعاينة اللحظية للفرونت
نفس الـ responses الأصلية بالظبط: {"status": "success/error", "command": "..."}
"""
from __future__ import annotations

from flask import Blueprint, jsonify, request

from builders import build_nat_expr, build_rule_expr

bp = Blueprint("preview", __name__, url_prefix="/api")


@bp.route('/preview_table', methods=['POST'])
def preview_table():
    data       = request.json
    table_name = data.get('table_name', '').strip()
    family     = data.get('family', 'ip')

    if not table_name:
        return jsonify({"status": "error", "command": ""})

    return jsonify({
        "status": "success",
        "command": f"nft add table {family} {table_name}"
    })


@bp.route('/preview_chain', methods=['POST'])
def preview_chain():
    data       = request.json
    family     = data.get('family', 'ip')
    table_name = data.get('table_name', '').strip()
    chain_name = data.get('chain_name', '').strip()
    hook       = data.get('hook')
    priority   = data.get('priority', 0)
    policy     = data.get('policy', 'accept')
    chain_type = data.get('chain_type', 'filter')

    if not table_name or not chain_name:
        return jsonify({"status": "error", "command": ""})

    cmd = (
        f"nft add chain {family} {table_name} {chain_name} "
        f"{{ type {chain_type} hook {hook} priority {priority}; policy {policy}; }}"
    )
    return jsonify({"status": "success", "command": cmd})


@bp.route('/preview_rule', methods=['POST'])
def preview_rule():
    data       = request.json
    family     = data.get('family', 'ip')
    table_name = data.get('table_name', '').strip()
    chain_name = data.get('chain_name', '').strip()

    if not table_name or not chain_name:
        return jsonify({"status": "error", "command": ""})

    rule_str, _ = build_rule_expr(
        family     = family,
        table_name = table_name,
        chain_name = chain_name,
        ip_src     = data.get('ip_src', '').strip(),
        ip_dest    = data.get('ip_dest', '').strip(),
        port_dest  = data.get('port_dest', '').strip(),
        interface  = data.get('interface', '').strip(),
        protocol   = data.get('protocol', '').strip(),
        action     = data.get('action', 'accept'),
    )
    return jsonify({"status": "success", "command": rule_str})


@bp.route('/preview_nat', methods=['POST'])
def preview_nat():
    data     = request.json
    nat_type = data.get('nat_type')

    if not nat_type:
        return jsonify({"status": "error", "command": ""})

    built = build_nat_expr(data)
    if built is None:
        return jsonify({"status": "error", "command": ""})

    rule_str, _, _ = built
    return jsonify({"status": "success", "command": rule_str})
