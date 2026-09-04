/**
 * Kevin Minecraft v0 local proof — flying-squid + mineflayer (offline only).
 * Marker: KEVIN_MC_V0_OK. No Microsoft login. No paid/public server.
 */
const path = require('path')
const fs = require('fs')
const net = require('net')
const mcServer = require('flying-squid')
const mineflayer = require('mineflayer')

const MARKER = 'KEVIN_MC_V0_OK'
const USERNAME = 'KevinBot'
const HOST = '127.0.0.1'
const VERSION = '1.16.5'
const CANDIDATE_PORTS = [25565, 25575, 25665, 25765, 25865]
const WORLD = path.join(__dirname, 'world-v0')
const LOG_PATH = path.join(__dirname, 'prove-local.log')

const lines = []
function log (msg) {
  const line = `[${new Date().toISOString()}] ${msg}`
  lines.push(line)
  console.log(line)
}

function portFree (port) {
  return new Promise((resolve) => {
    const s = net.createServer()
    s.once('error', () => resolve(false))
    s.once('listening', () => s.close(() => resolve(true)))
    s.listen(port, HOST)
  })
}

async function pickPort () {
  for (const p of CANDIDATE_PORTS) {
    if (await portFree(p)) return p
  }
  throw new Error('No free candidate port among ' + CANDIDATE_PORTS.join(','))
}

function wait (ms) {
  return new Promise((r) => setTimeout(r, ms))
}

async function main () {
  fs.mkdirSync(WORLD, { recursive: true })
  const port = await pickPort()
  log(`picked_port=${port}`)

  const server = mcServer.createMCServer({
    motd: 'Kevin local scratch v0',
    port,
    'max-players': 4,
    'online-mode': false,
    logging: false,
    gameMode: 1,
    difficulty: 0,
    worldFolder: WORLD,
    generation: {
      name: 'diamond_square',
      options: { worldHeight: 80 }
    },
    kickTimeout: 10000,
    plugins: {},
    modpe: false,
    'view-distance': 6,
    'player-list-text': { header: 'KevinScratch', footer: 'v0' },
    'everybody-op': true,
    'max-entities': 50,
    version: VERSION
  })

  await new Promise((resolve, reject) => {
    const t = setTimeout(() => reject(new Error('server ready timeout')), 60000)
    server.once('error', (e) => {
      clearTimeout(t)
      reject(e)
    })
    server.once('ready', () => {
      clearTimeout(t)
      resolve()
    })
  })
  log(`server_ready host=${HOST} port=${port} version=${VERSION}`)

  let chatSeen = false
  let spawnSeen = false

  const bot = mineflayer.createBot({
    host: HOST,
    port,
    username: USERNAME,
    auth: 'offline',
    version: VERSION,
    hideErrors: false
  })

  await new Promise((resolve, reject) => {
    const t = setTimeout(() => reject(new Error('bot spawn timeout')), 90000)
    bot.once('error', (e) => {
      clearTimeout(t)
      reject(e)
    })
    bot.once('kicked', (reason) => {
      clearTimeout(t)
      reject(new Error('bot kicked: ' + JSON.stringify(reason)))
    })
    bot.once('end', (reason) => {
      if (!spawnSeen) {
        clearTimeout(t)
        reject(new Error('bot ended before spawn: ' + reason))
      }
    })
    bot.once('spawn', async () => {
      spawnSeen = true
      log('bot_spawned')
      try {
        bot.chat(MARKER)
        log(`bot_chat_sent marker=${MARKER}`)
        await wait(1500)
        bot.quit('proof done')
        log('bot_quit')
        clearTimeout(t)
        resolve()
      } catch (e) {
        clearTimeout(t)
        reject(e)
      }
    })
    bot.on('message', (jsonMsg) => {
      const text = jsonMsg.toString()
      if (text.includes(MARKER)) {
        chatSeen = true
        log(`marker_observed_in_message=${MARKER}`)
      }
    })
  })

  await wait(500)
  try {
    await server.destroy()
    log('server_destroyed')
  } catch (e) {
    log('server_destroy_warn=' + e.message)
  }

  const result = {
    ok: spawnSeen,
    marker: MARKER,
    port,
    host: HOST,
    username: USERNAME,
    version: VERSION,
    chatSeen,
    packages: {
      'flying-squid': require('flying-squid/package.json').version,
      mineflayer: require('mineflayer/package.json').version,
      'mineflayer-pathfinder': require('mineflayer-pathfinder/package.json').version
    },
    node: process.version,
    logTail: lines.slice(-20)
  }

  fs.writeFileSync(LOG_PATH, lines.join('\n') + '\n' + JSON.stringify(result, null, 2) + '\n')
  log(`result_ok=${result.ok} wrote=${LOG_PATH}`)

  if (!result.ok) process.exit(2)
  process.exit(0)
}

main().catch((e) => {
  log('FAIL ' + (e && e.stack ? e.stack : String(e)))
  try {
    fs.writeFileSync(LOG_PATH, lines.join('\n') + '\n')
  } catch (_) {}
  process.exit(1)
})
