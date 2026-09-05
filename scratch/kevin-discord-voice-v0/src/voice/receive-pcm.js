"use strict";
/**
 * Subscribe to user audio -> PCM/WAV session buffer.
 * Session-only; do not persist beyond process unless owner opts in.
 * NOTE: DAVE receive path may be flaky upstream (@discordjs/voice#11419).
 */
const fs = require("fs");
const path = require("path");
const { EndBehaviorType } = require("@discordjs/voice");
const prism = require("prism-media");

function ensureSessionDir(dir) {
  const d = dir || path.join(process.cwd(), "session-audio");
  fs.mkdirSync(d, { recursive: true });
  return d;
}

function subscribeUserPcm(connection, userId, opts = {}) {
  const receiver = connection.receiver;
  const opusStream = receiver.subscribe(userId, {
    end: {
      behavior: EndBehaviorType.AfterSilence,
      duration: opts.silenceMs != null ? opts.silenceMs : 800,
    },
  });

  const decoder = new prism.opus.Decoder({ frameSize: 960, channels: 2, rate: 48000 });
  const chunks = [];
  const pcmStream = opusStream.pipe(decoder);

  pcmStream.on("data", (c) => chunks.push(c));
  pcmStream.on("error", (e) => {
    console.warn("PCM_STREAM_ERR", String(e && e.message || e));
  });

  return new Promise((resolve) => {
    pcmStream.on("end", () => {
      const pcm = Buffer.concat(chunks);
      let wavPath = null;
      if (opts.writeWav) {
        const dir = ensureSessionDir(opts.sessionDir);
        wavPath = path.join(dir, `u-${userId}-${Date.now()}.wav`);
        fs.writeFileSync(wavPath, pcmToWav(pcm, 48000, 2));
      }
      resolve({ userId, pcm, bytes: pcm.length, wavPath });
    });
  });
}

function pcmToWav(pcm, sampleRate, channels) {
  const byteRate = sampleRate * channels * 2;
  const blockAlign = channels * 2;
  const header = Buffer.alloc(44);
  header.write("RIFF", 0);
  header.writeUInt32LE(36 + pcm.length, 4);
  header.write("WAVE", 8);
  header.write("fmt ", 12);
  header.writeUInt32LE(16, 16);
  header.writeUInt16LE(1, 20);
  header.writeUInt16LE(channels, 22);
  header.writeUInt32LE(sampleRate, 24);
  header.writeUInt32LE(byteRate, 28);
  header.writeUInt16LE(blockAlign, 32);
  header.writeUInt16LE(16, 34);
  header.write("data", 36);
  header.writeUInt32LE(pcm.length, 40);
  return Buffer.concat([header, pcm]);
}

module.exports = { subscribeUserPcm, pcmToWav, ensureSessionDir };
