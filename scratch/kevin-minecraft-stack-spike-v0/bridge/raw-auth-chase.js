"use strict";
/**
 * Realms locomotion via player_auth_input (Prismarine #724 / protocol 1.26.45).
 *
 * NEVER enable bedrockflayer physicsEnabled on Realms inject (createPacketBuffer crash).
 * NEVER invent position from scratch — seed from start_game / server move_player, predict small steps only.
 * move_player-only chase is insufficient; auth_input is required for visible movement.
 *
 * 1.26.45 packet shape (gym serializer):
 *  - yaw / head_yaw in DEGREES
 *  - move_vector / analogue_move_vector / raw_move_vector = {x,z} (vec2f), NOT {x,y}
 *  - input_data = option(array of InputData names) e.g. ["up","sprinting"]
 *    (#724 bitflag object {_value, up} is for older InputFlag; we prefer array for 1.26.45)
 *  - include input_mode touch, play_mode, interaction_model, interact_rotation,
 *    camera_orientation, delta, incrementing BigInt tick, presence bools
 */
const EYE = 1.62;
const STEP = 0.28; // small predicted step per 50ms tick (~5.6 blocks/s walk-ish)
const FORWARD = 0.4;

function ensureSerializer(client) {
  if (client && client.serializer && typeof client.serializer.createPacketBuffer === "function") {
    return { ok: true, repaired: false };
  }
  try {
    const path = require("path");
    const { GYM_ROOT } = require("./paths");
    const serPath = path.join(GYM_ROOT, "node_modules", "bedrock-protocol", "src", "transforms", "serializer.js");
    const { createSerializer, createDeserializer } = require(serPath);
    const ver = (client.options && client.options.version) || process.env.KEVIN_MC_VERSION || "1.26.45";
    client.serializer = createSerializer(ver);
    if (!client.deserializer) client.deserializer = createDeserializer(ver);
    return { ok: true, repaired: true, version: ver };
  } catch (e) {
    return { ok: false, reason: String(e && e.message || e) };
  }
}

function getAuthPos(bot) {
  return bot && bot._kevinAuthPos;
}

function setAuthPos(bot, x, y, z, source) {
  if (!bot) return;
  bot._kevinAuthPos = { x, y, z, source: source || "unknown", at: Date.now() };
  // Mirror into bot.entity when present (feet ≈ eye - EYE for flayer convention)
  if (bot.entity && bot.entity.position) {
    bot.entity.position.x = x;
    bot.entity.position.y = y - EYE;
    bot.entity.position.z = z;
  }
  if (bot.position) {
    bot.position.x = x;
    bot.position.y = y - EYE;
    bot.position.z = z;
  }
}

function syncSelfFromStartGame(bot, client) {
  const sg = (client && (client._kevinStartGame || client.startGameData)) || {};
  const pos = sg.player_position;
  if (!pos || typeof pos.x !== "number") return false;
  // start_game player_position is body/eye-ish; keep as auth packet position
  setAuthPos(bot, pos.x, pos.y, pos.z, "start_game");
  if (sg.runtime_entity_id != null) {
    bot._runtimeEntityId = typeof sg.runtime_entity_id === "bigint"
      ? Number(sg.runtime_entity_id)
      : sg.runtime_entity_id;
  }
  return true;
}

function attachSelfPosMirror(client, bot) {
  if (!client || !bot || client._kevinSelfPosMirror) return;
  client._kevinSelfPosMirror = true;
  client.on("move_player", (packet) => {
    try {
      if (!packet || !packet.position) return;
      const rid = packet.runtime_id != null ? packet.runtime_id : packet.runtime_entity_id;
      let selfId = bot._runtimeEntityId;
      if (selfId == null && client.startGameData && client.startGameData.runtime_entity_id != null) {
        selfId = client.startGameData.runtime_entity_id;
        bot._runtimeEntityId = typeof selfId === "bigint" ? Number(selfId) : selfId;
      }
      if (selfId == null) {
        // First move_player often is self before we know id — seed once if no auth pos yet
        if (!getAuthPos(bot)) {
          setAuthPos(bot, packet.position.x, packet.position.y, packet.position.z, "move_player_seed");
          if (rid != null) bot._runtimeEntityId = typeof rid === "bigint" ? Number(rid) : rid;
        }
        return;
      }
      const same = String(rid) === String(selfId) || String(rid) === String(BigInt(selfId));
      if (!same) return;
      setAuthPos(bot, packet.position.x, packet.position.y, packet.position.z, "move_player");
      if (typeof packet.yaw === "number") {
        bot._kevinAuthYawDeg = packet.yaw;
        if (bot.entity) bot.entity.yaw = packet.yaw * Math.PI / 180;
      }
      if (typeof packet.pitch === "number") {
        bot._kevinAuthPitchDeg = packet.pitch;
        if (bot.entity) bot.entity.pitch = packet.pitch * Math.PI / 180;
      }
    } catch (e) {}
  });
}

function sendSpawnHelpers(client, bot) {
  if (!client || client._kevinSpawnHelpersSent) return { ok: false, reason: "already_or_no_client" };
  client._kevinSpawnHelpersSent = true;
  const rid = (bot && bot._runtimeEntityId != null)
    ? bot._runtimeEntityId
    : (client.startGameData && client.startGameData.runtime_entity_id);
  const results = [];
  try {
    client.queue("request_chunk_radius", { chunk_radius: 8 });
    results.push("request_chunk_radius");
  } catch (e) { results.push("request_chunk_radius_fail:" + String(e && e.message || e)); }
  try {
    client.queue("tick_sync", {
      request_time: BigInt(Date.now()),
      response_time: BigInt(Date.now()),
    });
    results.push("tick_sync");
  } catch (e) { results.push("tick_sync_fail:" + String(e && e.message || e)); }
  if (rid != null) {
    try {
      client.queue("set_local_player_as_initialized", {
        runtime_entity_id: typeof rid === "bigint" ? rid : BigInt(rid),
      });
      results.push("set_local_player_as_initialized");
    } catch (e) {
      try {
        client.queue("set_local_player_as_initialized", { runtime_entity_id: String(rid) });
        results.push("set_local_player_as_initialized_str");
      } catch (e2) {
        results.push("init_fail:" + String(e2 && e2.message || e2));
      }
    }
  }
  return { ok: true, results };
}

function buildInputDataArray(forward, sprint, jump) {
  const flags = [];
  if (forward) flags.push("up");
  if (sprint) flags.push("sprinting");
  if (jump) flags.push("jumping");
  // Prefer 1.26.45 option(array). Keep #724-shaped object as secondary attempt in safeQueue.
  return flags.length ? flags : undefined;
}

function buildAuthPacket(authPos, yawDeg, pitchDeg, moving, jump, tick, delta) {
  const mv = { x: 0, z: moving ? FORWARD : 0 };
  const inputArr = buildInputDataArray(moving, moving, jump);
  return {
    pitch: pitchDeg,
    yaw: yawDeg,
    head_yaw: yawDeg,
    position: { x: authPos.x, y: authPos.y, z: authPos.z },
    move_vector: mv,
    analogue_move_vector: { x: mv.x, z: mv.z },
    raw_move_vector: { x: mv.x, z: mv.z },
    // 1.26.45: option(array of InputData). Also acceptable to omit when idle.
    input_data: inputArr,
    input_mode: "touch", // mapper 2
    play_mode: 0, // normal
    interaction_model: 1, // crosshair
    interact_rotation: { x: pitchDeg, z: yawDeg },
    tick,
    delta: delta || { x: 0, y: 0, z: 0 },
    transaction_presence: false,
    item_stack_request_presence: false,
    block_action_presence: false,
    vehicle_rotation_presence: false,
    predicted_vehicle_presence: false,
    camera_orientation: { x: 0, y: 0, z: 0 },
  };
}

function safeQueue(client, name, params) {
  const ser = ensureSerializer(client);
  if (!ser.ok) return { ok: false, reason: "NO_SERIALIZER:" + ser.reason };
  try {
    if (typeof client.queue === "function") {
      client.queue(name, params);
      return { ok: true, via: "queue", repaired: !!ser.repaired };
    }
    if (typeof client.write === "function") {
      client.write(name, params);
      return { ok: true, via: "write", repaired: !!ser.repaired };
    }
    return { ok: false, reason: "NO_QUEUE_OR_WRITE" };
  } catch (e) {
    const msg = String(e && e.message || e);
    // Fallback: #724 bitflag object if array shape rejected at runtime
    if (name === "player_auth_input" && params && Array.isArray(params.input_data)) {
      try {
        const alt = Object.assign({}, params, {
          input_data: { _value: 0n, up: true, sprinting: params.input_data.indexOf("sprinting") >= 0 },
        });
        if (typeof client.queue === "function") client.queue(name, alt);
        else client.write(name, alt);
        return { ok: true, via: "queue_bitset_fallback", repaired: !!ser.repaired };
      } catch (e2) {
        return { ok: false, reason: msg + " | fallback:" + String(e2 && e2.message || e2) };
      }
    }
    return { ok: false, reason: msg };
  }
}

/**
 * One chase tick: face Matt, send #724-shaped auth input. Predict small steps only.
 */
function authInputChaseTick(bot, client, opts = {}) {
  const { findMattEntity } = require("./find-matt");
  if (!bot || !client) return { ok: false, status: "NOT_PROVEN", reason: "NO_BOT_OR_CLIENT" };

  if (!getAuthPos(bot)) syncSelfFromStartGame(bot, client);
  const authPos = getAuthPos(bot);
  if (!authPos || typeof authPos.x !== "number") {
    return { ok: false, status: "NOT_PROVEN", reason: "NO_SELF_POS" };
  }

  const matt = findMattEntity(bot, opts);
  if (!matt) return { ok: false, status: "NOT_PROVEN", reason: "MATT_NOT_FOUND", self: { x: authPos.x, y: authPos.y, z: authPos.z } };
  const target = matt.position || (matt.entity && matt.entity.position);
  if (!target || typeof target.x !== "number") {
    return { ok: false, status: "NOT_PROVEN", reason: "MATT_POS_MISSING", self: { x: authPos.x, y: authPos.y, z: authPos.z } };
  }

  // Target may be feet; auth pos is server body/eye — compare XZ only
  const dx = target.x - authPos.x;
  const dz = target.z - authPos.z;
  const dy = (target.y || authPos.y) - authPos.y;
  const dist = Math.sqrt(dx * dx + dz * dz);
  const range = opts.range != null ? opts.range : 3;
  const moving = dist > range;

  // #724: yaw in degrees
  const yawDeg = Math.atan2(-dx, dz) * (180 / Math.PI);
  const pitchDeg = Math.atan2(-dy, Math.max(0.001, dist)) * (180 / Math.PI);
  bot._kevinAuthYawDeg = yawDeg;
  bot._kevinAuthPitchDeg = pitchDeg;
  if (bot.entity) {
    bot.entity.yaw = yawDeg * Math.PI / 180;
    bot.entity.pitch = pitchDeg * Math.PI / 180;
    bot.entity.headYaw = bot.entity.yaw;
  }

  const tick = BigInt(bot._kevinAuthTick = (bot._kevinAuthTick || 0) + 1);
  const jump = moving && dist > range + 1.5 && (Number(tick) % 8 === 0);

  let delta = { x: 0, y: 0, z: 0 };
  if (moving) {
    const yawRad = yawDeg * Math.PI / 180;
    delta = {
      x: -Math.sin(yawRad) * STEP,
      y: 0,
      z: Math.cos(yawRad) * STEP,
    };
    // Predict small step only; server move_player will resync
    setAuthPos(bot, authPos.x + delta.x, authPos.y + delta.y, authPos.z + delta.z, "predict");
  }

  const posNow = getAuthPos(bot);
  const params = buildAuthPacket(posNow, yawDeg, pitchDeg, moving, jump, tick, delta);
  const sent = safeQueue(client, "player_auth_input", params);
  if (!sent.ok) {
    return {
      ok: false,
      status: "NOT_PROVEN",
      reason: sent.reason,
      dist,
      action: "authInput.fail",
      self: { x: posNow.x, y: posNow.y, z: posNow.z },
    };
  }
  return {
    ok: false,
    status: "WIRED_NOT_PROVEN",
    action: moving ? "authInput.chase" : "authInput.near",
    dist,
    via: sent.via,
    repaired: sent.repaired,
    self: { x: posNow.x, y: posNow.y, z: posNow.z },
    yawDeg,
    source: posNow.source,
  };
}

function startAuthChaseLoop(bot, client, opts = {}) {
  const ms = opts.intervalMs != null ? opts.intervalMs : 50;
  attachSelfPosMirror(client, bot);
  syncSelfFromStartGame(bot, client);
  const helpers = sendSpawnHelpers(client, bot);
  const ser = ensureSerializer(client);
  try {
    console.log("[auth-chase] start ser=", ser, "helpers=", helpers, "self=", getAuthPos(bot));
  } catch (e) {}

  // Periodic tick_sync keeps some Realms sessions happier (#724)
  const syncTimer = setInterval(() => {
    try {
      client.queue("tick_sync", {
        request_time: BigInt(Date.now()),
        response_time: BigInt(Date.now()),
      });
    } catch (e) {}
  }, 1000);
  if (syncTimer.unref) syncTimer.unref();

  const timer = setInterval(() => {
    try {
      const r = authInputChaseTick(bot, client, opts);
      if (!bot._kevinLastChaseLog || Date.now() - bot._kevinLastChaseLog > 2000) {
        bot._kevinLastChaseLog = Date.now();
        const self = r.self || getAuthPos(bot) || {};
        console.log(
          "[auth-chase]",
          r.action || r.reason,
          "dist=", r.dist,
          "via=", r.via,
          "serOK=", !!(ser && ser.ok),
          "serRepaired=", !!(ser && ser.repaired),
          "self=", self.x, self.y, self.z,
          "src=", self.source || r.source
        );
      }
    } catch (e) {
      console.log("[auth-chase] tick err", String(e && e.message || e));
    }
  }, ms);
  if (timer.unref) timer.unref();
  return { timer, syncTimer, serializer: ser, helpers };
}

module.exports = {
  ensureSerializer,
  syncSelfFromStartGame,
  attachSelfPosMirror,
  sendSpawnHelpers,
  authInputChaseTick,
  startAuthChaseLoop,
  safeQueue,
  buildAuthPacket,
  getAuthPos,
};
