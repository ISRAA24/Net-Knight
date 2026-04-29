"""
routes/interfaces.py — إدارة الـ network interfaces
نفس الـ logic والـ responses الأصلية بالظبط.
"""
from __future__ import annotations

import subprocess

import netifaces
from flask import Blueprint, jsonify, request

from helpers import run_command

bp = Blueprint("interfaces", __name__, url_prefix="/api")


@bp.route('/manage_interfaces', methods=['GET', 'POST'])
def manage_interfaces():
    if request.method == 'GET':
        interfaces = netifaces.interfaces()
        details = []
        for iface in interfaces:
            addrs   = netifaces.ifaddresses(iface)
            ip_info = addrs.get(netifaces.AF_INET, [{}])[0]
            ip      = ip_info.get('addr', 'No IP')
            status_output = subprocess.run(
                ['ip', 'link', 'show', iface],
                capture_output=True, text=True
            ).stdout
            status = 'up' if 'UP' in status_output else 'down'
            details.append({"name": iface, "ip": ip, "status": status})
        return jsonify({"status": "success", "interfaces": details})

    # POST
    data    = request.json
    iface   = data.get('interface')
    action  = data.get('action')
    new_ip  = data.get('new_ip')

    if not iface:
        return jsonify({"status": "error", "message": "interface required"})

    command = _build_interface_command(iface, action, new_ip)
    if command is None:
        return jsonify({"status": "error", "message": "Invalid action"})
    if isinstance(command, str):
        return jsonify({"status": "error", "message": command})

    result = run_command(command)
    if result["status"] == "success":
        result["message"] = f"{action} applied on {iface}"

    return jsonify(result)


def _build_interface_command(iface: str, action: str, new_ip: str | None):
    """يبني الأمر المناسب حسب الـ action."""
    if action == 'up':
        return ["ip", "link", "set", "dev", iface, "up"]

    if action == 'down':
        return ["ip", "link", "set", "dev", iface, "down"]

    if action in ('add_ip', 'modify_ip'):
        current_ips = netifaces.ifaddresses(iface).get(netifaces.AF_INET, [])
        if current_ips and action == 'modify_ip':
            old = current_ips[0]['addr']
            subprocess.run(["ip", "addr", "del", f"{old}/24", "dev", iface], check=False)
        return ["ip", "addr", "add", f"{new_ip}/24", "dev", iface]

    if action == 'del_ip':
        current_ips = netifaces.ifaddresses(iface).get(netifaces.AF_INET, [])
        if not current_ips:
            return "No IP to delete"
        old = current_ips[0]['addr']
        return ["ip", "addr", "del", f"{old}/24", "dev", iface]

    return None
