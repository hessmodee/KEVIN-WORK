"""Reader v1 sense: system status + Kevin state events. No OpenClaw exec required."""
import os, sys, time, subprocess

ROOT = os.path.join(os.path.expanduser("~"), ".openclaw", "workspace")
STATE = os.path.join(ROOT, "helper_kevin_state.py")
STATUS = os.path.join(ROOT, "helper_system_status.py")
REPORTS = os.path.join(ROOT, "reports")


def run_state(*args):
    cmd = [sys.executable, STATE, "--source", "kevin-reader"] + list(args)
    subprocess.run(cmd, check=False)


def main():
    t0 = time.time()
    run_state("start", "system-status", "Checking system status", "system_reader")
    code = 1
    if os.path.isfile(STATUS):
        code = subprocess.call([sys.executable, STATUS])
    else:
        print("FAIL: helper_system_status.py missing")
    ms = int((time.time() - t0) * 1000)
    result = "PASS" if code == 0 else "FAIL"
    run_state("finish", "system-status", result, "kevin_system_status %s %sms" % (result, ms))
    path = os.path.join(REPORTS, "system-status.md")
    if os.path.isfile(path):
        print(open(path, encoding="utf-8", errors="replace").read())
    print("READER", result, ms, "ms")
    return 0 if code == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
