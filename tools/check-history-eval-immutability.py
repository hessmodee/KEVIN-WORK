"""CI-only byte snapshot of tracked files; comparison emits no file contents."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
snapshot = Path(os.environ["RUNNER_TEMP"]) / "kevin-history-eval-byte-snapshot.json"
paths = subprocess.check_output(["git", "ls-files", "-z"], cwd=root).decode().split("\0")
state = {}
for name in filter(None, paths):
    path = root / name
    if path.is_symlink():
        raw = b"SYMLINK\0" + os.readlink(path).encode()
    elif path.is_file():
        raw = b"FILE\0" + path.read_bytes()
    else:
        raise ValueError("tracked file missing")
    state[name] = hashlib.sha256(raw).hexdigest()
if len(sys.argv) != 2 or sys.argv[1] not in {"record", "verify"} or not state:
    raise ValueError("invalid fixed CI invocation")
if sys.argv[1] == "record":
    snapshot.write_text(json.dumps(state, sort_keys=True), encoding="utf-8")
    print("TRACKED_BYTE_BASELINE_RECORDED", len(state))
else:
    before = json.loads(snapshot.read_text(encoding="utf-8"))
    if before != state:
        raise ValueError("tracked file set or bytes changed during evaluation")
    print("TRACKED_BYTES_UNCHANGED", len(state))
