import { Type } from "typebox";
import { defineToolPlugin } from "openclaw/plugin-sdk/tool-plugin";
import { clickControl, focusApp, typeText, type UiResult } from "./ui.js";

const focusParams = Type.Object(
  {
    app: Type.Literal("calculator"),
  },
  { additionalProperties: false },
);

const clickParams = Type.Object(
  {
    app: Type.Literal("calculator"),
    control_id: Type.String({ minLength: 1, maxLength: 64 }),
  },
  { additionalProperties: false },
);

const typeParams = Type.Object(
  {
    app: Type.Literal("calculator"),
    text: Type.String({ minLength: 0, maxLength: 256 }),
  },
  { additionalProperties: false },
);

export default defineToolPlugin({
  id: "kevin-desktop-ui",
  name: "Kevin Desktop UI (Phase 2 candidate)",
  description:
    "Disabled-by-default typed Calculator UI focus/click/type. Phase 2 candidate only — not on Chat. No live UIA until Phase 3.",
  tools: (tool) => [
    tool({
      name: "kevin_ui_focus_app",
      label: "Focus Calculator app (candidate)",
      description:
        "Phase 2 candidate: focus allowlisted Calculator. Disabled by default unless KEVIN_DESKTOP_UI_ENABLE=1. No live UIA yet.",
      parameters: focusParams,
      optional: true,
      async execute(params, _config, context): Promise<UiResult> {
        context.signal?.throwIfAborted();
        return focusApp(String(params.app));
      },
    }),
    tool({
      name: "kevin_ui_click",
      label: "Click Calculator control (candidate)",
      description:
        "Phase 2 candidate: click catalog control id on Calculator. Disabled by default. No live UIA yet.",
      parameters: clickParams,
      optional: true,
      async execute(params, _config, context): Promise<UiResult> {
        context.signal?.throwIfAborted();
        return clickControl(String(params.app), String(params.control_id));
      },
    }),
    tool({
      name: "kevin_ui_type",
      label: "Type into Calculator (candidate)",
      description:
        "Phase 2 candidate: type short text into Calculator. Secret patterns denied. Disabled by default. No live UIA yet.",
      parameters: typeParams,
      optional: true,
      async execute(params, _config, context): Promise<UiResult> {
        context.signal?.throwIfAborted();
        return typeText(String(params.app), String(params.text));
      },
    }),
  ],
});
