"use strict";
/**
 * Join Discord voice ONLY when channel is on owner allowlist.
 * Uses @discordjs/voice >=0.19 + davey for DAVE E2EE.
 */
const {
  joinVoiceChannel,
  getVoiceConnection,
  VoiceConnectionStatus,
  entersState,
} = require("@discordjs/voice");

function assertAllowlisted(channelId, allowlist) {
  const id = String(channelId || "");
  const list = Array.isArray(allowlist) ? allowlist.map(String) : [];
  if (!list.length) {
    const err = new Error("VOICE_ALLOWLIST_EMPTY — set DISCORD_VOICE_CHANNEL_ALLOWLIST before join");
    err.code = "VOICE_ALLOWLIST_EMPTY";
    throw err;
  }
  if (!list.includes(id)) {
    const err = new Error("VOICE_CHANNEL_DENIED id=" + id);
    err.code = "VOICE_CHANNEL_DENIED";
    throw err;
  }
}

async function joinVc({ channel, adapterCreator, allowlist, selfDeaf = false, selfMute = false }) {
  if (!channel || !channel.id || !channel.guild) {
    throw new Error("INVALID_VOICE_CHANNEL");
  }
  assertAllowlisted(channel.id, allowlist);

  const existing = getVoiceConnection(channel.guild.id);
  if (existing) {
    try { existing.destroy(); } catch (e) {}
  }

  const connection = joinVoiceChannel({
    channelId: channel.id,
    guildId: channel.guild.id,
    adapterCreator: adapterCreator || channel.guild.voiceAdapterCreator,
    selfDeaf,
    selfMute,
  });

  await entersState(connection, VoiceConnectionStatus.Ready, 30_000);
  return connection;
}

function leaveVc(guildId) {
  const connection = getVoiceConnection(guildId);
  if (connection) {
    connection.destroy();
    return { ok: true, status: "LEFT" };
  }
  return { ok: true, status: "NOT_CONNECTED" };
}

module.exports = { joinVc, leaveVc, assertAllowlisted };
