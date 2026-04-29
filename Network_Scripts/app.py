"""
app.py — نقطة البداية
نفس الـ URLs الأصلية بالظبط:

  POST /api/create_table
  POST /api/create_chain
  POST /api/add_rule
  POST /api/add_nat
  POST /api/delete_rule
  GET  /api/manage_interfaces
  POST /api/manage_interfaces
  POST /api/preview_table
  POST /api/preview_chain
  POST /api/preview_rule
  POST /api/preview_nat
"""
from __future__ import annotations

from flask import Flask

from firewall   import bp as firewall_bp
from interfaces import bp as interfaces_bp
from preview    import bp as preview_bp
from logs       import bp as logs_bp


def create_app() -> Flask:
    app = Flask(__name__)
    app.register_blueprint(firewall_bp)
    app.register_blueprint(interfaces_bp)
    app.register_blueprint(preview_bp)
    app.register_blueprint(logs_bp)
    return app


if __name__ == '__main__':
    create_app().run(debug=True, host='0.0.0.0', port=5000)