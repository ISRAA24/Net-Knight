from __future__ import annotations

import json
import os
import subprocess
from typing import Any


NFT_RULES_FILE = "/etc/nftables.conf"


NFT_TABLES_REGISTRY = "/var/lib/nft_api_tables.json"


def run_command(command: list[str]) -> dict[str, Any]:
    
    try:
        result = subprocess.run(command, check=True, capture_output=True, text=True)
        return {"status": "success", "output": result.stdout.strip()}
    except subprocess.CalledProcessError as e:
        return {"status": "error", "output": e.stderr.strip() or str(e)}


def get_rule_handle(family: str, table: str, chain: str, comment: str | None) -> int | None:
    
    if not comment:
        return None
    cmd = ["nft", "-j", "list", "chain", family, table, chain]
    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        data = json.loads(result.stdout)
        for obj in data.get("nftables", []):
            if "rule" in obj:
                rule = obj["rule"]
                if rule.get("comment") == comment:
                    return rule.get("handle")
    except Exception:
        pass
    return None



def _load_registry() -> list[dict]:
    
    if not os.path.exists(NFT_TABLES_REGISTRY):
        return []
    try:
        with open(NFT_TABLES_REGISTRY, "r") as f:
            return json.load(f)
    except Exception:
        return []


def _save_registry(tables: list[dict]) -> None:
    
    with open(NFT_TABLES_REGISTRY, "w") as f:
        json.dump(tables, f)


def register_table(family: str, table_name: str) -> None:
    
    tables = _load_registry()
    entry = {"family": family, "table": table_name}
    if entry not in tables:
        tables.append(entry)
        _save_registry(tables)


def unregister_table(family: str, table_name: str) -> None:
    
    tables = _load_registry()
    tables = [t for t in tables if not (t["family"] == family and t["table"] == table_name)]
    _save_registry(tables)



def save_rules() -> dict[str, Any]:
    
    tables = _load_registry()

    if not tables:
       
        with open(NFT_RULES_FILE, "w") as f:
            f.write("#!/usr/sbin/nft -f\n\nflush ruleset\n")
        return {"status": "success", "message": "No tables to save"}

    lines = ["#!/usr/sbin/nft -f\n"]

    for entry in tables:
        family     = entry["family"]
        table_name = entry["table"]

        try:
            result = subprocess.run(
                ["nft", "list", "table", family, table_name],
                check=True, capture_output=True, text=True
            )
            lines.append(result.stdout)
        except subprocess.CalledProcessError:
            
            unregister_table(family, table_name)

    with open(NFT_RULES_FILE, "w") as f:
        f.write("\n".join(lines))

    return {"status": "success", "message": "Rules saved to disk"}


def load_rules() -> dict[str, Any]:
   
    if not os.path.exists(NFT_RULES_FILE):
        return {"status": "error", "message": f"{NFT_RULES_FILE} not found"}
    return run_command(["nft", "-f", NFT_RULES_FILE])