#!/usr/bin/env python3
"""Identity pins for the versioned catalog-contract repair files.

v1.1.1 (75D6031E) stays on disk as the catalog-contract identity.
v1.1.2 (471E5051) is the live repair the puller/repair script copies.
Historical unversioned python and ControlPlane worker pins do not move.
"""

from __future__ import annotations

import hashlib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INV111 = ROOT / "control-plane" / "autonomy" / "kevin-proven-skill-invocation-v1.1.1.py"
INV112 = ROOT / "control-plane" / "autonomy" / "kevin-proven-skill-invocation-v1.1.2.py"
BLD = ROOT / "control-plane" / "autonomy" / "kevin-proven-skill-request-builder-v1.0.1.py"
HIST_INV = ROOT / "control-plane" / "autonomy" / "kevin-proven-skill-invocation-v1.py"
HIST_BLD = ROOT / "control-plane" / "autonomy" / "kevin-proven-skill-request-builder-v1.py"
WORKER = ROOT / "ControlPlane" / "kevin-proven-skill-invoke-worker-v1.ps1"
REPAIR = ROOT / "tools" / "Repair-Kevin-InvocationRegistryContract-v1.ps1"
PULLER = ROOT / "omen" / "pull-inbox.ps1"
DIAGNOSE = ROOT / "tools" / "Diagnose-Kevin-InvocationStage-v1.ps1"

INV111_SHA = "75D6031EFA64C0A9568EF006B4F95C71D3EDE1E3BAA4A35E2C1EE436326AD5EF"
INV112_SHA = "471E505151E211C254FAB9DD090AEA76E7D304B01333FEA03B115D2ECE39B7E8"
BLD_SHA = "93A8A881E04CC8E6AE0B900275C6158AF166484F663988EBB564BC47C4140031"
HIST_INV_SHA = "63FA334B85F895894481DF59314326F6F0F4B0785553B8FDD33DFBFC0E88147C"
HIST_BLD_SHA = "8E1CDB6911A4F087099788C1DAD9E5A425686B63A6FED471E49D9478688ACCF9"
WORKER_SHA = "16C49542847BBB22EACC09F254C030D2FF03DE0ADFB1B9DA08C9B617C73B0332"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


class InvocationRegistryContractV111Tests(unittest.TestCase):
    def test_versioned_repair_hashes(self) -> None:
        self.assertEqual(sha256(INV111), INV111_SHA)
        self.assertEqual(sha256(INV112), INV112_SHA)
        self.assertEqual(sha256(BLD), BLD_SHA)
        self.assertIn("CATALOG_PRIMITIVES", INV111.read_text(encoding="utf-8"))
        self.assertIn("CATALOG_PRIMITIVES", INV112.read_text(encoding="utf-8"))
        self.assertIn("MS_DATE_RE", INV112.read_text(encoding="utf-8"))
        self.assertIn("fictional eight-vehicle GREEN example", BLD.read_text(encoding="utf-8"))

    def test_historical_pins_unmoved(self) -> None:
        self.assertEqual(sha256(HIST_INV), HIST_INV_SHA)
        self.assertEqual(sha256(HIST_BLD), HIST_BLD_SHA)
        self.assertEqual(sha256(WORKER), WORKER_SHA)
        self.assertNotIn("CATALOG_PRIMITIVES", HIST_INV.read_text(encoding="utf-8"))

    def test_repair_script_fetches_versioned_paths(self) -> None:
        text = REPAIR.read_text(encoding="utf-8")
        self.assertIn("kevin-proven-skill-invocation-v1.1.2.py", text)
        self.assertIn("kevin-proven-skill-request-builder-v1.0.1.py", text)
        self.assertIn(INV112_SHA, text)
        self.assertIn(BLD_SHA, text)
        self.assertIn("Does not recopy Supervisor", text)
        self.assertIn("Does not replace the live worker pin", text)
        puller = PULLER.read_text(encoding="utf-8")
        self.assertIn("puller = 'v1.3'", puller)
        self.assertIn(INV112_SHA, puller)
        self.assertIn("Diagnose-Kevin-InvocationStage-v1.ps1", puller)
        diagnose = DIAGNOSE.read_text(encoding="utf-8")
        self.assertIn("diagnose-ready", diagnose)
        self.assertIn(INV112_SHA, diagnose)


if __name__ == "__main__":
    unittest.main()
