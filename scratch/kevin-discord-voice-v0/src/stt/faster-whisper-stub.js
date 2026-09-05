"use strict";
/**
 * STT backend: stub by default; faster-whisper if python module + ffmpeg ready.
 * Free/local only — no paid cloud STT.
 */
const { spawnSync } = require("child_process");
const fs = require("fs");
const path = require("path");
const os = require("os");

function probeFasterWhisper() {
  const r = spawnSync("python", ["-c", "import faster_whisper; print('OK')"], {
    encoding: "utf8",
    timeout: 15000,
  });
  if (r.status === 0 && String(r.stdout || "").includes("OK")) {
    return { ok: true, backend: "faster-whisper" };
  }
  return {
    ok: false,
    backend: "stub",
    status: "READY_FOR_STT_TTS_INSTALL",
    detail: String(r.stderr || r.stdout || r.error || "faster_whisper missing"),
  };
}

function transcribeStub(pcmOrPath, opts = {}) {
  return {
    ok: true,
    backend: "stub",
    text: opts.fakeText || "",
    note: "STT stub — install faster-whisper for live voice directs",
  };
}

function transcribeWithFasterWhisper(wavPath) {
  const py = `
from faster_whisper import WhisperModel
import sys
model = WhisperModel("base", device="cpu", compute_type="int8")
segments, info = model.transcribe(sys.argv[1], beam_size=1)
print("".join(s.text for s in segments).strip())
`;
  const script = path.join(os.tmpdir(), "kevin-fw-stt.py");
  fs.writeFileSync(script, py, "utf8");
  const r = spawnSync("python", [script, wavPath], { encoding: "utf8", timeout: 120000 });
  if (r.status !== 0) {
    return { ok: false, backend: "faster-whisper", error: String(r.stderr || r.error || "fail") };
  }
  return { ok: true, backend: "faster-whisper", text: String(r.stdout || "").trim() };
}

async function transcribe(input, opts = {}) {
  const backend = opts.backend || process.env.KEVIN_STT_BACKEND || "stub";
  if (backend === "stub") return transcribeStub(input, opts);
  const probe = probeFasterWhisper();
  if (!probe.ok) return { ...transcribeStub(input, opts), probe };
  let wavPath = input;
  if (Buffer.isBuffer(input)) {
    wavPath = path.join(os.tmpdir(), "kevin-stt-" + Date.now() + ".wav");
    const { pcmToWav } = require("../voice/receive-pcm");
    fs.writeFileSync(wavPath, pcmToWav(input, 48000, 2));
  }
  return transcribeWithFasterWhisper(wavPath);
}

module.exports = { probeFasterWhisper, transcribe, transcribeStub };
