"""Fixed offline fixture replay to stdout; never reads or writes Kevin runtime state."""
import hashlib
import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("recovery", ROOT / "control-plane/autonomy/candidates/history_evidence_recovery.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
sources = []
for receipt in json.loads((ROOT / "tests/fixtures/history-public-receipts.json").read_text(encoding="utf-8")):
    raw = receipt["text"].encode("utf-8")
    blob = hashlib.sha1(b"blob " + str(len(raw)).encode() + b"\0" + raw).hexdigest()
    if blob != receipt["blob"]:
        raise ValueError("published receipt Git blob identity mismatch")
    sources.append(dict(commit=receipt["commit"], text=receipt["text"], sha256=hashlib.sha256(raw).hexdigest().upper()))
print(json.dumps(module.reconcile(sources), indent=2, sort_keys=True))
