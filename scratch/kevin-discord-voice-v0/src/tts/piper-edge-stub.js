"use strict";
/**
 * TTS: stub | piper (local) | edge-tts (free, needs network).
 * No paid APIs (ElevenLabs/etc) without explicit owner auth.
 */
const { spawnSync } = require("child_process");
const fs = require("fs");
const path = require("path");
const os = require("os");

function probePiper() {
  const r = spawnSync("piper", ["--help"], { encoding: "utf8", timeout: 10000 });
  // piper often exits non-zero on --help; check PATH presence via where/which style
  const which = process.platform === "win32" ? "where" : "which";
  const w = spawnSync(which, ["piper"], { encoding: "utf8" });
  if (w.status === 0 && String(w.stdout || "").trim()) {
    return { ok: true, backend: "piper" };
  }
  return { ok: false, backend: "stub", status: "READY_FOR_STT_TTS_INSTALL", detail: "piper not on PATH" };
}

function probeEdgeTts() {
  const r = spawnSync("python", ["-c", "import edge_tts; print('OK')"], {
    encoding: "utf8",
    timeout: 15000,
  });
  if (r.status === 0 && String(r.stdout || "").includes("OK")) {
    return { ok: true, backend: "edge-tts" };
  }
  return { ok: false, backend: "stub", detail: "edge_tts missing" };
}

function synthesizeStub(text) {
  return {
    ok: true,
    backend: "stub",
    text: String(text || ""),
    audioPath: null,
    note: "TTS stub — install piper or edge-tts for VC speak",
  };
}

function synthesizeEdgeTts(text, outPath) {
  const py = `
import asyncio, edge_tts, sys
async def main():
    comm = edge_tts.Communicate(sys.argv[1], "en-US-GuyNeural")
    await comm.save(sys.argv[2])
asyncio.run(main())
`;
  const script = path.join(os.tmpdir(), "kevin-edge-tts.py");
  fs.writeFileSync(script, py, "utf8");
  const r = spawnSync("python", [script, String(text || ""), outPath], {
    encoding: "utf8",
    timeout: 60000,
  });
  if (r.status !== 0) {
    return { ok: false, backend: "edge-tts", error: String(r.stderr || r.error || "fail") };
  }
  return { ok: true, backend: "edge-tts", audioPath: outPath, text };
}

async function synthesize(text, opts = {}) {
  const backend = opts.backend || process.env.KEVIN_TTS_BACKEND || "stub";
  if (backend === "stub") return synthesizeStub(text);
  const outPath = opts.outPath || path.join(os.tmpdir(), "kevin-tts-" + Date.now() + ".mp3");
  if (backend === "edge-tts") {
    const probe = probeEdgeTts();
    if (!probe.ok) return { ...synthesizeStub(text), probe };
    return synthesizeEdgeTts(text, outPath);
  }
  if (backend === "piper") {
    const probe = probePiper();
    if (!probe.ok) return { ...synthesizeStub(text), probe };
    const wav = outPath.replace(/\.mp3$/i, ".wav");
    const r = spawnSync("piper", ["--output_file", wav], {
      input: String(text || ""),
      encoding: "utf8",
      timeout: 60000,
    });
    if (r.status !== 0) {
      return { ok: false, backend: "piper", error: String(r.stderr || r.error || "fail") };
    }
    return { ok: true, backend: "piper", audioPath: wav, text };
  }
  return synthesizeStub(text);
}

module.exports = { synthesize, synthesizeStub, probePiper, probeEdgeTts };
