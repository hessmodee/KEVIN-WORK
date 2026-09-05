"use strict";
/**
 * P0 TEXT command bot — play directs while voice proves.
 * Prefix commands: !k follow|stop|guard|come|status|say ...
 * Requires DISCORD_BOT_TOKEN via env/credentials. Never invents token.
 */
const { Client, GatewayIntentBits, Partials } = require("discord.js");
const { getConfig, requireTokenOrExit } = require("./config");
const { parseIntent, INTENT } = require("./intent-router");
const { applyIntent } = require("./companion-bridge");

async function main() {
  const cfg = requireTokenOrExit();
  const client = new Client({
    intents: [
      GatewayIntentBits.Guilds,
      GatewayIntentBits.GuildMessages,
      GatewayIntentBits.MessageContent,
      GatewayIntentBits.DirectMessages,
    ],
    partials: [Partials.Channel],
  });

  client.once("ready", () => {
    console.log("KEVIN_DISCORD_TEXT_READY user=" + client.user.tag);
  });

  client.on("messageCreate", async (msg) => {
    try {
      if (msg.author.bot) return;
      if (cfg.ownerUserId && String(msg.author.id) !== String(cfg.ownerUserId)) {
        // If owner set, ignore others (allowlist)
        return;
      }
      const content = msg.content || "";
      if (!content.toLowerCase().startsWith(String(cfg.prefix).toLowerCase())) return;

      const intent = parseIntent(content, { prefix: cfg.prefix });
      const result = applyIntent(intent, {});
      const reply =
        intent.name === INTENT.UNKNOWN
          ? `Unknown. Try \`${cfg.prefix} follow|stop|guard|come|status|say <msg>\``
          : `OK intent=\`${intent.name}\` action=\`${result.plan.action}\` (${result.plan.status})`;
      await msg.reply({ content: reply });
      console.log("INTENT", JSON.stringify({ intent, result: result.plan }));
    } catch (e) {
      console.error("MSG_ERR", String(e && e.message || e));
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
