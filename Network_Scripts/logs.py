from __future__ import annotations

import json
import os

from flask import Blueprint, jsonify, request

from logger import LOG_FILE

bp = Blueprint("logs", __name__, url_prefix="/api")


@bp.route('/logs', methods=['GET'])
def get_logs():
    limit = request.args.get('limit', 100, type=int)
    level = request.args.get('level', '').upper()  # INFO, ERROR, أو فاضي = كل حاجة

    if not os.path.exists(LOG_FILE):
        return jsonify({"status": "success", "logs": []})

    try:
        with open(LOG_FILE, 'r') as f:
            lines = f.readlines()

        
        lines = lines[-limit:]

        logs = []
        for line in lines:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
                
                if level and entry.get('level') != level:
                    continue
                logs.append(entry)
            except json.JSONDecodeError:
                continue

        return jsonify({"status": "success", "logs": logs, "count": len(logs)})

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})