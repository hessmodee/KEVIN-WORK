import { Type } from "typebox";
import { defineToolPlugin } from "openclaw/plugin-sdk/tool-plugin";
import { collectStatus, type Status } from "./collect.js";

const params = Type.Object({}, { additionalProperties: false });

export default defineToolPlugin({
  id: "kevin-core",
  name: "Kevin Core",
  description: "Read-only Kevin senses. No shell. No file mutation.",
  tools: (tool) => [
    tool({
      name: "kevin_system_status",
      label: "Kevin system status",
      description:
        "Read sanitized computer health: RAM, CPU, GPU, disk, Ollama, and gateway. No shell. No files. Call when Matt asks how the computer is doing.",
      parameters: params,
      optional: true,
      async execute(_params, _config, context): Promise<Status> {
        context.signal?.throwIfAborted();
        const result = await collectStatus(context.signal);
        context.signal?.throwIfAborted();
        return result;
      },
    }),
  ],
});
