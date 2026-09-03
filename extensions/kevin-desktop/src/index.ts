import { Type } from "typebox";
import { defineToolPlugin } from "openclaw/plugin-sdk/tool-plugin";
import {
  APP_ALLOWLIST,
  findDesktopFolder,
  launchAllowedApp,
  openDesktopFolder,
  type DesktopResult,
} from "./desktop.js";

const folderParams = Type.Object(
  {
    name: Type.String({ minLength: 1, maxLength: 120 }),
  },
  { additionalProperties: false },
);

const appParams = Type.Object(
  {
    app: Type.Union(Object.keys(APP_ALLOWLIST).map((name) => Type.Literal(name))),
  },
  { additionalProperties: false },
);

export default defineToolPlugin({
  id: "kevin-desktop",
  name: "Kevin Desktop",
  description:
    "Bounded Windows desktop fluency: find/open a direct Desktop folder and launch fixed allowlisted apps. No arbitrary shell, paths, installs, downloads, or generic mouse/keyboard automation.",
  tools: (tool) => [
    tool({
      name: "kevin_desktop_find_folder",
      label: "Find Desktop folder",
      description:
        "Find one direct child folder on Matt's Windows Desktop by folder name. Returns no private filesystem path. Use before opening when identity is uncertain.",
      parameters: folderParams,
      optional: true,
      async execute(params, _config, context): Promise<DesktopResult> {
        context.signal?.throwIfAborted();
        const result = await findDesktopFolder(String(params.name));
        context.signal?.throwIfAborted();
        return result;
      },
    }),
    tool({
      name: "kevin_desktop_open_folder",
      label: "Open Desktop folder",
      description:
        "Open exactly one direct Desktop folder in Windows Explorer by safe folder name. No arbitrary path, command, shell, or recursive search.",
      parameters: folderParams,
      optional: true,
      async execute(params, _config, context): Promise<DesktopResult> {
        context.signal?.throwIfAborted();
        const result = await openDesktopFolder(String(params.name));
        context.signal?.throwIfAborted();
        return result;
      },
    }),
    tool({
      name: "kevin_app_launch",
      label: "Launch approved Windows app",
      description:
        "Launch one fixed approved local Windows application. Allowed: notepad, calculator, paint, explorer. No caller-selected executable, arguments, URI, command, or shell.",
      parameters: appParams,
      optional: true,
      async execute(params, _config, context): Promise<DesktopResult> {
        context.signal?.throwIfAborted();
        const result = launchAllowedApp(String(params.app));
        context.signal?.throwIfAborted();
        return result;
      },
    }),
  ],
});
