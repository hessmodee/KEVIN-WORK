
from pathlib import Path
import subprocess, os, sys, hashlib
root = Path(__file__).resolve().parent
pkg = root / "vendor" / "mineflayer-for-bedrock-main"
gym_lock = root.parent / "kevin-minecraft-bedrock-v0" / "package-lock.json"
before = None
if gym_lock.exists():
    before = hashlib.sha256(gym_lock.read_bytes()).hexdigest()
    print("JOIN_OK_LOCK_BEFORE", before)
pm = None
for cand in [os.environ.get("ProgramFiles", r"C:\Program Files") + r"\nodejs\npm.cmd",
             r"C:\Program Files\nodejs\npm.cmd"]:
    if Path(cand).exists():
        pm = cand
        break
if pm is None:
    # PATH search
    from shutil import which
    pm = which("npm") or which("npm.cmd")
if not pm:
    print("PM_MISSING")
    sys.exit(2)
print("PM", pm)
r = subprocess.run([pm, "install", "--no-fund", "--no-audit", "--omit=dev"], cwd=str(pkg))
print("INSTALL_RC", r.returncode)
if gym_lock.exists():
    after = hashlib.sha256(gym_lock.read_bytes()).hexdigest()
    print("JOIN_OK_LOCK_AFTER", after)
    print("JOIN_OK_LOCK_UNCHANGED", before == after)
sys.exit(r.returncode)
