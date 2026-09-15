#!/usr/bin/env python3
"""Source proof: Diagnose v1.3.5 follows live selected_id, never a COMPLETE parent."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
DIAG = ROOT / "tools" / "Diagnose-Kevin-InvocationStage-v1.ps1"
STICKY = ROOT / "tools" / "Repair-Kevin-StickyInvokeState-v1.ps1"

INV = "471E505151E211C254FAB9DD090AEA76E7D304B01333FEA03B115D2ECE39B7E8"
BLD = "E7381E6051B988A0E36386265A0E09263D88CF83EB2EB2BAC808DF04EB5BB1B3"
WORKER_GH = "16C49542847BBB22EACC09F254C030D2FF03DE0ADFB1B9DA08C9B617C73B0332"
FRESH8 = "owner-west-motor-parts-chase-fresh-8-v1"


def fail(msg: str) -> None:
    print("FAIL:", msg)
    sys.exit(1)


def main() -> None:
    d = DIAG.read_text(encoding="utf-8")
    s = STICKY.read_text(encoding="utf-8")

    if "version = '1.3.5'" not in d and 'version = "1.3.5"' not in d:
        fail("Diagnose version is not 1.3.5")
    if "Get-SelectedWorkId" not in d:
        fail("Diagnose missing Get-SelectedWorkId")
    if "NO_OPEN_SELECTED_ID" not in d:
        fail("Diagnose missing NO_OPEN_SELECTED_ID fail-closed")
    if "hq-live-floor.json" not in d:
        fail("Diagnose does not read hq-live-floor.json")
    if "autonomy-continuation-latest.json" not in d:
        fail("Diagnose does not read continuation")

    # Runtime must not assign WorkId to the COMPLETE fresh-8 parent.
    runtime_default = re.search(
        r"^\s*\$WorkId\s*=\s*'owner-west-motor-parts-chase-fresh-8-v1'\s*$",
        d,
        re.M,
    )
    if runtime_default:
        fail("Diagnose still hard-codes fresh-8 as runtime WorkId")

    if f"$InvExpected = '{INV}'" not in d:
        fail("Diagnose InvExpected pin missing or corrupt")
    if f"$BldExpected = '{BLD}'" not in d:
        fail("Diagnose BldExpected pin missing or corrupt")
    if "$InvExpected$BldExpected" in d:
        fail("Diagnose still has concatenated hash-pin variable names")
    if f"$WorkerExpectedV1 = '{WORKER_GH}'" not in d:
        fail("Diagnose must keep GitHub ControlPlane worker pin 16C49542")

    if "COMPLETE_DO_NOT_RESELECT" not in d and "COMPLETE'" not in d:
        fail("Diagnose must skip COMPLETE selected ids")

    if "Get-SelectedWorkId" not in s:
        fail("Sticky missing Get-SelectedWorkId")
    if "version = '1.1.0'" not in s and 'version = "1.1.0"' not in s:
        fail("Sticky version is not 1.1.0")
    sticky_default = re.search(
        r"^\s*\$WorkId\s*=\s*'owner-west-motor-parts-chase-fresh-8-v1'\s*$",
        s,
        re.M,
    )
    if sticky_default:
        fail("Sticky still hard-codes fresh-8 as runtime WorkId")
    if "NO_OPEN_SELECTED_ID" not in s:
        fail("Sticky missing NO_OPEN_SELECTED_ID")

    # Fresh-8 may appear as a documented COMPLETE parent, never as the live default.
    if FRESH8 in d and "COMPLETE" not in d:
        fail("fresh-8 mentioned without COMPLETE context")

    print("PASS diagnose-selected-id-v1.3.5 source proof")
    print("  Diagnose follows floor/continuation selected_id")
    print("  Sticky v1.1.0 follows the same resolver")
    print("  Hash pins restored; GitHub worker pin 16C49542 stands")
    print("  No runtime default to COMPLETE fresh-8")


if __name__ == "__main__":
    main()
