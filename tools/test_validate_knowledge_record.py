from datetime import datetime, timezone
from validate_knowledge_record import validate

NOW = datetime(2026, 8, 30, 12, 30, tzinfo=timezone.utc)
H = "a" * 64

def base():
    return {
        "record_id":"fact-1","record_type":"FACT","statement":"Benchmark passed.",
        "source_refs":[{"source_id":"support-1","sha256":H,"trust_level":"PRIMARY"}],
        "observed_at":"2026-08-30T12:20:00Z","stale_after":"2026-08-30T13:20:00Z",
        "confidence":0.95,"trust_state":"VERIFIED","authority_class":"KNOWLEDGE_ONLY"
    }

def check(name, mutate, expected):
    r=base(); mutate(r); got=validate(r,NOW)[0]; assert got is expected, name

assert validate(base(), NOW) == (True,"ok")
check("unknown field", lambda r:r.update(authority_override=True), False)
check("authority", lambda r:r.update(authority_class="EXECUTE"), False)
check("empty", lambda r:r.update(statement=" "), False)
check("missing source", lambda r:r.update(source_refs=[]), False)
check("bad hash", lambda r:r["source_refs"][0].update(sha256="bad"), False)
check("unverified verified", lambda r:r["source_refs"][0].update(trust_level="UNVERIFIED"), False)
check("low confidence", lambda r:r.update(confidence=.2), False)
check("stale", lambda r:r.update(stale_after="2026-08-30T12:25:00Z"), False)
check("future", lambda r:r.update(observed_at="2026-08-30T12:40:00Z", stale_after="2026-08-30T13:40:00Z"), False)
check("bad window", lambda r:r.update(stale_after="2026-08-30T12:10:00Z"), False)
check("bad type", lambda r:r.update(record_type="AUTHORITY"), False)
check("candidate unverified allowed", lambda r:(r.update(trust_state="CANDIDATE",confidence=.3),r["source_refs"][0].update(trust_level="UNVERIFIED")), True)

def dup(r): r["source_refs"].append(dict(r["source_refs"][0]))
check("duplicate source", dup, False)
print("14/14 knowledge provenance tests PASS")
