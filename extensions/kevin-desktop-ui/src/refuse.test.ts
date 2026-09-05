import { afterEach, describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { getToolPluginMetadata } from "openclaw/plugin-sdk/tool-plugin";
import entry from "./index.js";
import { catalogControlIds, resetCatalogCache } from "./catalog.js";
import { ENABLE_ENV } from "./refuse.js";
import { clickControl, focusApp, typeText } from "./ui.js";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");

afterEach(() => {
  delete process.env[ENABLE_ENV];
  resetCatalogCache();
});

describe("kevin-desktop-ui plugin metadata", () => {
  it("declares the three optional UI tools", () => {
    const tools = getToolPluginMetadata(entry)?.tools ?? [];
    expect(tools.map((t) => t.name)).toEqual([
      "kevin_ui_focus_app",
      "kevin_ui_click",
      "kevin_ui_type",
    ]);
    expect(tools.every((t) => t.optional === true)).toBe(true);
  });

  it("keeps openclaw.plugin.json enabled_by_default false", () => {
    const meta = JSON.parse(
      readFileSync(join(ROOT, "openclaw.plugin.json"), "utf8"),
    ) as {
      enabled_by_default: boolean;
      activation: { onStartup: boolean };
      id: string;
    };
    expect(meta.id).toBe("kevin-desktop-ui");
    expect(meta.enabled_by_default).toBe(false);
    expect(meta.activation.onStartup).toBe(false);
  });
});

describe("refuse-by-default gates", () => {
  it("disabled_by_default when env unset", () => {
    delete process.env[ENABLE_ENV];
    const r = focusApp("calculator");
    expect(r.ok).toBe(false);
    expect(r).toMatchObject({ error: "disabled_by_default" });
  });

  it("invalid_app when enabled", () => {
    process.env[ENABLE_ENV] = "1";
    const r = focusApp("notepad");
    expect(r.ok).toBe(false);
    expect(r).toMatchObject({ error: "invalid_app", app: "notepad" });
  });

  it("invalid_control when enabled", () => {
    process.env[ENABLE_ENV] = "1";
    expect(catalogControlIds().has("digit_1")).toBe(true);
    const r = clickControl("calculator", "not_a_real_control");
    expect(r.ok).toBe(false);
    expect(r).toMatchObject({
      error: "invalid_control",
      control_id: "not_a_real_control",
    });
  });

  it("secret_deny when enabled", () => {
    process.env[ENABLE_ENV] = "1";
    const r = typeText("calculator", "password=hunter2");
    expect(r.ok).toBe(false);
    expect(r).toMatchObject({ error: "secret_deny" });
  });

  it("text_too_long when enabled", () => {
    process.env[ENABLE_ENV] = "1";
    const r = typeText("calculator", "1".repeat(65));
    expect(r.ok).toBe(false);
    expect(r).toMatchObject({ error: "text_too_long", max: 64, length: 65 });
  });

  it("enabled calculator returns candidate_no_live_uia", () => {
    process.env[ENABLE_ENV] = "1";
    const focus = focusApp("calculator");
    expect(focus.ok).toBe(false);
    expect(focus).toMatchObject({ error: "candidate_no_live_uia" });

    const click = clickControl("calculator", "digit_1");
    expect(click.ok).toBe(false);
    expect(click).toMatchObject({ error: "candidate_no_live_uia" });

    const typed = typeText("calculator", "42");
    expect(typed.ok).toBe(false);
    expect(typed).toMatchObject({ error: "candidate_no_live_uia" });
  });
});
