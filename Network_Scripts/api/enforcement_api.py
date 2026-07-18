
from __future__ import annotations
import logging

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from gateway import approval_gateway
from enforcement import nft_rules

log = logging.getLogger("Net-Knight.enforcement_api")

app = FastAPI(title="Net-Knight Enforcement API (Network_Scripts)")


_executor = None


def bind_executor(executor) -> None:
    global _executor
    _executor = executor


class AutoApproveBody(BaseModel):
    value: bool


class DecisionBody(BaseModel):
    request_id: str
       class Config:
        extra = "allow"


class DeleteRuleBody(BaseModel):
    mode: str          # "handle" , "set_element"
    family: str = "inet"
    table: str = "filter"
    chain: str | None = None
    handle: int | None = None
    set: str | None = None
    ip: str | None = None
    port: int | None = None


@app.post("/config/auto_approve")
async def set_auto_approve(body: AutoApproveBody):
    approval_gateway.set_auto_approve(body.value)
    return {"ok": True, "auto_approve": approval_gateway.get_auto_approve()}


@app.get("/config/auto_approve")
async def get_auto_approve():
    return {"auto_approve": approval_gateway.get_auto_approve()}


@app.post("/decisions/approve")
async def approve_decision(body: DecisionBody):
    if _executor is None:
        raise HTTPException(status_code=503, detail="Executor not initialized yet")
    result = approval_gateway.handle_approve(body.request_id, _executor)
    if result is None:
        raise HTTPException(status_code=404, detail="request_id not found")
    return result


@app.post("/decisions/reject")
async def reject_decision(body: DecisionBody):
    existed = approval_gateway.handle_reject(body.request_id)
    if not existed:
        raise HTTPException(status_code=404, detail="request_id not found")
    return {"ok": True}


@app.post("/rules/delete")
async def delete_rule(body: DeleteRuleBody):
    """
      mode="handle"      → family+table+chain+handle
      mode="set_element" → family+table+set+ip(+port)
    """
    deletion = body.dict(exclude_none=True)
    ok = nft_rules.delete_rule(deletion)
    if not ok:
        raise HTTPException(status_code=400, detail="faild")
    return {"ok": True}


from a2wsgi import WSGIMiddleware
from app import create_app as _create_flask_app

app.mount("/", WSGIMiddleware(_create_flask_app()))
