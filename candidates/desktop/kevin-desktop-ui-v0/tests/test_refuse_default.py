"""Refuse-by-default + catalog/negative tests for kevin-desktop-ui-v0 candidate."""
from __future__ import annotations

import json
import os
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from module import refuse as refuse_mod  # noqa: E402
from module import ui_control  # noqa: E402


class RefuseDefaultTests(unittest.TestCase):
    def test_disabled_by_default(self):
        os.environ.pop(ui_control.ENABLE_ENV, None)
        self.assertFalse(ui_control.is_enabled())
        for action, fn in [
            ("focus", lambda: ui_control.focus_app("calculator")),
            ("click", lambda: ui_control.click_control("calculator", "digit_1")),
            ("type", lambda: ui_control.type_text("calculator", "1")),
            ("prove", lambda: ui_control.run_prove()),
        ]:
            with self.subTest(action=action):
                r = fn()
                self.assertFalse(r.get("ok"))
                self.assertEqual(r.get("error"), "disabled_by_default")
                self.assertTrue(r.get("candidate_only"))
                self.assertTrue(r.get("openclaw_untouched"))

    def test_tool_dispatch_disabled(self):
        os.environ.pop(ui_control.ENABLE_ENV, None)
        r = ui_control.tool_dispatch("kevin_ui_focus_app", {"app": "calculator"})
        self.assertEqual(r.get("error"), "disabled_by_default")

    def test_refuse_unit(self):
        out = refuse_mod.run_refuse_unit()
        self.assertTrue(out["ok"])
        self.assertTrue(all(c["pass"] for c in out["results"]))

    def test_catalog_ids(self):
        ids = refuse_mod.catalog_ids()
        self.assertIn("digit_1", ids)
        self.assertIn("op_eq", ids)
        self.assertNotIn("xyz_button", ids)

    def test_fixture_negatives(self):
        fixtures = ROOT / "fixtures"
        for name, err in [
            ("invalid_app.json", "invalid_app"),
            ("invalid_control.json", "invalid_control"),
            ("secret_deny.json", "secret_deny"),
        ]:
            data = json.loads((fixtures / name).read_text(encoding="utf-8-sig"))
            if err == "invalid_app":
                r = refuse_mod.check_app(data["app"])
            elif err == "invalid_control":
                r = refuse_mod.check_control(data["control_id"])
            else:
                r = refuse_mod.check_text(data["text"])
            self.assertIsNotNone(r)
            self.assertEqual(r["error"], err)

    def test_xy_fixture_has_extra_props(self):
        data = json.loads((ROOT / "fixtures" / "xy_click_forbidden.json").read_text(encoding="utf-8-sig"))
        self.assertIn("x", data)
        self.assertIn("y", data)
        # Schema oneOf objects forbid additionalProperties; document expectation.
        self.assertEqual(data["expect"]["schema_ok"], False)


if __name__ == "__main__":
    unittest.main()
