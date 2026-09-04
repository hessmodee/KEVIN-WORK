#!/usr/bin/env python3
"""Deterministic public-safe contract for Kevin private-vault note metadata."""
from __future__ import annotations
import json, re, sys
from typing import Any, Dict, List

TYPES={"source","research","x_post","yt_script","paper_ticket","ops"}
STATUS={"candidate","settled","stale","falsified","superseded"}
REQUIRED={"id","type","created_at","updated_at","claim","source_refs","date_seen","confidence","owner_agent","next_action","human_required","status","depends_on"}
ISO=re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$")

class ContractError(ValueError): pass

def _nonempty_str(v:Any)->bool:return isinstance(v,str) and bool(v.strip())
def _string_list(v:Any)->bool:return isinstance(v,list) and all(_nonempty_str(x) for x in v)

def validate(note:Dict[str,Any])->Dict[str,Any]:
    if not isinstance(note,dict): raise ContractError("NOTE_NOT_OBJECT")
    missing=sorted(REQUIRED-set(note))
    if missing: raise ContractError("MISSING_FIELDS:"+",".join(missing))
    if note["type"] not in TYPES: raise ContractError("UNKNOWN_TYPE")
    if note["status"] not in STATUS: raise ContractError("UNKNOWN_STATUS")
    if note["human_required"] not in {"yes","no",True,False}: raise ContractError("INVALID_HUMAN_REQUIRED")
    for key in ("id","claim","owner_agent"):
        if not _nonempty_str(note[key]): raise ContractError("INVALID_"+key.upper())
    for key in ("created_at","updated_at","date_seen"):
        if not _nonempty_str(note[key]) or not ISO.match(note[key]): raise ContractError("INVALID_"+key.upper())
    if not isinstance(note["confidence"],(int,float)) or isinstance(note["confidence"],bool) or not 0<=float(note["confidence"])<=1:
        raise ContractError("INVALID_CONFIDENCE")
    if not _string_list(note["source_refs"]): raise ContractError("INVALID_SOURCE_REFS")
    if not _string_list(note["depends_on"]): raise ContractError("INVALID_DEPENDS_ON")

    # A settled load-bearing claim must have evidence. A source note may point to the
    # URL/file itself; personal preferences should point to an owner-input source record.
    if note["status"]=="settled" and not note["source_refs"]:
        raise ContractError("SETTLED_WITHOUT_SOURCE")

    falsified=set(map(str,note.get("falsified_source_refs",[]) or []))
    if falsified & set(map(str,note["source_refs"])) and note["status"]=="settled":
        raise ContractError("SETTLED_DEPENDS_ON_FALSIFIED_SOURCE")

    # Public content remains owner-reviewed until a separately proven publication crossing exists.
    if note["type"] in {"x_post","yt_script"} and note["human_required"] not in {"yes",True}:
        raise ContractError("PUBLIC_CONTENT_MUST_REQUIRE_HUMAN")

    # Trading notes in this contract are research/paper only.
    if note["type"]=="paper_ticket" and note.get("paper_only") is not True:
        raise ContractError("PAPER_TICKET_MUST_BE_PAPER_ONLY")

    # Secrets must never appear in metadata records destined for cloud/repo exchange.
    forbidden={"private_key","seed_phrase","withdrawal_key","password","oauth_token","api_secret","recovery_code"}
    if forbidden & set(note): raise ContractError("FORBIDDEN_SECRET_FIELD")

    return {"ok":True,"id":note["id"],"status":note["status"],"type":note["type"]}

def main()->int:
    doc=json.load(sys.stdin)
    try: out=validate(doc)
    except ContractError as e:
        print(json.dumps({"ok":False,"error":str(e)}));return 2
    print(json.dumps(out));return 0

if __name__=="__main__": raise SystemExit(main())
