#!/usr/bin/env python3
import importlib.util
from pathlib import Path
HERE=Path(__file__).resolve().parent
SRC=HERE/"validate-vault-note-v1.py"
spec=importlib.util.spec_from_file_location("vault",SRC);m=importlib.util.module_from_spec(spec);assert spec.loader;spec.loader.exec_module(m)

def base(t="research"):
    return {"id":"T-1","type":t,"created_at":"2026-09-04T05:00:00Z","updated_at":"2026-09-04T05:00:00Z","claim":"test claim","source_refs":["SRC-1"],"date_seen":"2026-09-04T05:00:00Z","confidence":0.8,"owner_agent":"reviewer","next_action":"test","human_required":"no","status":"settled","depends_on":["SRC-1"]}

def must_fail(doc, code):
    try:m.validate(doc)
    except m.ContractError as e:assert str(e)==code,(str(e),code);return
    raise AssertionError("expected failure "+code)

def test_settled_requires_source():
    d=base();d["source_refs"]=[];must_fail(d,"SETTLED_WITHOUT_SOURCE")
def test_falsified_source_invalidates_settled():
    d=base();d["falsified_source_refs"]=["SRC-1"];must_fail(d,"SETTLED_DEPENDS_ON_FALSIFIED_SOURCE")
def test_candidate_may_be_unsourced():
    d=base();d["status"]="candidate";d["source_refs"]=[];assert m.validate(d)["ok"]
def test_public_content_requires_human():
    d=base("x_post");must_fail(d,"PUBLIC_CONTENT_MUST_REQUIRE_HUMAN");d["human_required"]="yes";assert m.validate(d)["ok"]
def test_youtube_requires_human():
    d=base("yt_script");d["human_required"]=False;must_fail(d,"PUBLIC_CONTENT_MUST_REQUIRE_HUMAN")
def test_paper_ticket_cannot_be_live():
    d=base("paper_ticket");d["paper_only"]=False;must_fail(d,"PAPER_TICKET_MUST_BE_PAPER_ONLY");d["paper_only"]=True;assert m.validate(d)["ok"]
def test_secret_fields_rejected():
    for field in ("private_key","seed_phrase","withdrawal_key","password","oauth_token","api_secret","recovery_code"):
        d=base();d[field]="nope";must_fail(d,"FORBIDDEN_SECRET_FIELD")
def test_confidence_bounded():
    d=base();d["confidence"]=1.1;must_fail(d,"INVALID_CONFIDENCE")

if __name__=="__main__":
    tests=[v for k,v in sorted(globals().items()) if k.startswith("test_") and callable(v)]
    for t in tests:t()
    print(f"KEVIN VAULT CONTRACT v1 SELFTEST PASS ({len(tests)} tests)")
