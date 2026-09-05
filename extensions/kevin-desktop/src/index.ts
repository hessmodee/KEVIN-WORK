import { Type } from "typebox";
import { defineToolPlugin } from "openclaw/plugin-sdk/tool-plugin";
import {
  APP_ALLOWLIST,
  LIST_ROOT_ALLOWLIST,
  MAX_LIST_LIMIT,
  findDesktopFolder,
  launchAllowedApp,
  listFolder,
  openDesktopFolder,
  type DesktopResult,
} from "./desktop.js";
import { CLOSE_APP_ALLOWLIST, closeAllowedApp, type CloseResult } from "./close.js";

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

const closeAppParams = Type.Object(
  {
    app: Type.Union(Object.keys(CLOSE_APP_ALLOWLIST).map((name) => Type.Literal(name))),
    force: Type.Optional(Type.Boolean()),
  },
  { additionalProperties: false },
);

const listParams = Type.Object(
  {
    root: Type.Optional(
      Type.Union(LIST_ROOT_ALLOWLIST.map((name) => Type.Literal(name))),
    ),
    name: Type.Optional(Type.String({ minLength: 1, maxLength: 120 })),
    limit: Type.Optional(Type.Integer({ minimum: 1, maximum: MAX_LIST_LIMIT })),
  },
  { additionalProperties: false },
);

export default defineToolPlugin({
  id: "kevin-desktop",
  name: "Kevin Desktop",
  description:
    "Bounded Windows desktop fluency: find/open/list allowlisted user folders and launch/close fixed allowlisted apps. No arbitrary shell, paths, installs, downloads, or generic mouse/keyboard automation.",
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
      name: "kevin_desktop_list_folder",
      label: "List folder names",
      description:
        "List depth-1 basenames inside an allowlisted known user folder. Default root=Desktop. To list the Desktop itself: set root=Desktop (or omit root) and OMIT name entirely. Do NOT pass name equal to the root (e.g. name=Desktop). Optional name selects one safe direct child under that root. Returns basenames + file/dir kind only — never private paths. Caps entries (default 50, max 100). Secret-like basenames omitted. Refuse .., absolute paths, and separators. Use this to answer what is on the Desktop.",
      parameters: listParams,
      optional: true,
      async execute(params, _config, context): Promise<DesktopResult> {
        context.signal?.throwIfAborted();
        const root = (params.root as string | undefined) || "Desktop";
        let name = params.name as string | undefined;
        if (typeof name === "string") {
          const trimmed = name.trim();
          if (!trimmed || trimmed.toLowerCase() === String(root).toLowerCase()) {
            name = undefined;
          } else {
            name = trimmed;
          }
        }
        const result = await listFolder({
          root: params.root,
          name,
          limit: params.limit,
        });
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
    tool({
      name: "kevin_app_close",
      label: "Close approved Windows app",
      description:
        "Close one fixed approved local Windows application via graceful CloseMainWindow / UIA then audited force. Allowed: notepad, calculator, paint, minecraft. Minecraft requires KEVIN_ALLOW_CLOSE_MC=1 (Matt-authorized). Never closes Chat/Reader/node gateways. No arbitrary process names.",
      parameters: closeAppParams,
      optional: true,
      async execute(params, _config, context): Promise<CloseResult> {
        context.signal?.throwIfAborted();
        const result = closeAllowedApp(String(params.app), {
          force: Boolean(params.force),
        });
        context.signal?.throwIfAborted();
        return result;
      },
    }),
  ],
});
