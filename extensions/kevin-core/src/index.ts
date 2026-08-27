import { Type } from "typebox";
import { defineToolPlugin } from "openclaw/plugin-sdk/tool-plugin";
import { collectStatus, type Status } from "./collect.js";

const params = Type.Object({}, { additionalProperties: false });

const outputSchema = Type.Object(
  {
    ok: Type.Boolean(),
    collected_at: Type.String(),
    ram_used_gb: Type.Number(),
    ram_total_gb: Type.Number(),
    ram_load_percent: Type.Number(),
    cpu_percent: Type.Number(),
    gpu_name: Type.String(),
    gpu_percent: Type.Number(),
    vram_used_mb: Type.Number(),
    vram_total_mb: Type.Number(),
    disk_free_gb: Type.Number(),
    ollama_status: Type.String(),
    gateway_status: Type.String(),
    error: Type.String(),
  },
  { additionalProperties: false },
);

export const statusOutputSchema = outputSchema;

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
      outputSchema,
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
