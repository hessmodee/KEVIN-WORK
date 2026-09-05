"use strict";
/**
 * VOICE bot — join allowlisted VC, receive audio, STT -> intent -> companion, TTS reply.
 * DAVE: @discordjs/voice ^0.19 + @snazzah/davey. Node >=22.12.
 * NEG: no join without allowlist; session-only audio; no token invent.
 */
const { Client, GatewayIntentBits, ChannelType } = require("discord.js");
const { createAudioPlayer, createAudioResource, AudioPlayerStatus } = require("@discordjs/voice");
const { requireTokenOrExit } = require("./config");
const { parseIntent } = require("./intent-router");
const { applyIntent } = require("./companion-bridge");
const { joinVc, leaveVc } = require("./voice/join-vc");
const { subscribeUserPcm } = require("./voice/receive-pcm");
const { transcribe, probeFasterWhisper } = require("./stt/faster-whisper-stub");
const { synthesize, probePiper, probeEdgeTts } = require("./tts/piper-edge-stub");
const fs = require("fs");

async function main() {
  const cfg = requireTokenOrExit();
  const sttProbe = probeFasterWhisper();
  const ttsProbe = cfg.ttsBackend === "edge-tts" ? probeEdgeTts() : probePiper();
  console.log("STT_PROBE", JSON.stringify(sttProbe));
  console.log("TTS_PROBE", JSON.stringify(ttsProbe));
  if (!sttProbe.ok || !ttsProbe.ok) {
    console.log("READY_FOR_STT_TTS_INSTALL — voice join still possible; STT/TTS may be stub");
  }

  const client = new Client({
    intents: [
      GatewayIntentBits.Guilds,
      GatewayIntentBits.GuildVoiceStates,
      GatewayIntentBits.GuildMessages,
      GatewayIntentBits.MessageContent,
    ],
  });

  let connection = null;

  client.once("ready", () => {
    console.log("KEVIN_DISCORD_VOICE_READY user=" + client.user.tag);
  });

  client.on("messageCreate", async (msg) => {
    try {
      if (msg.author.bot) return;
      if (cfg.ownerUserId && String(msg.author.id) !== String(cfg.ownerUserId)) return;
      const content = msg.content || "";
      if (!content.toLowerCase().startsWith(String(cfg.prefix).toLowerCase())) return;
      const intent = parseIntent(content, { prefix: cfg.prefix });

      if (intent.name === "join_vc") {
        const member = msg.member;
        const ch = member && member.voice && member.voice.channel;
        if (!ch || ch.type !== ChannelType.GuildVoice) {
          await msg.reply("Join a voice channel first, then `!k join vc`.");
          return;
        }
        connection = await joinVc({
          channel: ch,
          allowlist: cfg.voiceAllowlist,
        });
        await msg.reply("Joined VC (allowlisted). Listening session-only.");
        // Attach speaking listener
        const receiver = connection.receiver;
        receiver.speaking.on("start", async (userId) => {
          if (cfg.ownerUserId && String(userId) !== String(cfg.ownerUserId)) return;
          try {
            const cap = await subscribeUserPcm(connection, userId, { writeWav: false });
            if (!cap.bytes) return;
            const asr = await transcribe(cap.pcm, { backend: cfg.sttBackend });
            const spoken = (asr && asr.text) || "";
            if (!spoken) return;
            console.log("ASR", spoken);
            const vIntent = parseIntent(spoken, { prefix: "" });
            const result = applyIntent(vIntent, {});
            const say = `Got it: ${vIntent.name}`;
            const tts = await synthesize(say, { backend: cfg.ttsBackend });
            if (tts.audioPath && fs.existsSync(tts.audioPath) && connection) {
              const player = createAudioPlayer();
              const resource = createAudioResource(tts.audioPath);
              connection.subscribe(player);
              player.play(resource);
              player.on(AudioPlayerStatus.Idle, () => player.stop());
            }
            console.log("VOICE_INTENT", JSON.stringify({ vIntent, plan: result.plan }));
          } catch (e) {
            console.warn("VOICE_RECV_ERR", String(e && e.message || e));
          }
        });
        return;
      }

      if (intent.name === "leave_vc") {
        if (msg.guild) leaveVc(msg.guild.id);
        connection = null;
        await msg.reply("Left VC.");
        return;
      }

      const result = applyIntent(intent, {});
      await msg.reply(`OK \`${intent.name}\` -> \`${result.plan.action}\``);
    } catch (e) {
      console.error("VOICE_MSG_ERR", String(e && e.message || e));
      try {
        await msg.reply("Error: " + String(e && e.message || e));
      } catch (e2) {}
    }
  });

  await client.login(cfg.token);
}

if (require.main === module) {
  main().catch((e) => {
    console.error("FATAL", String(e && e.message || e));
    process.exit(1);
  });
}

module.exports = { main };
