# PLAN - Kevin Super-AI north star MAX (sequenced faculties)

Date: 2026-09-04 ~11:15 MT (America/Denver)
Author: Grok Bot (web research + HESS-PC inventory)
Audience: Matt / Davy / Kevin / Cursor slack agents
Auth: UNDYING GREEN+YELLOW docs/engineering/OWNER-UNDYING-GREEN-YELLOW-AUTH-2026-09-04.md
Charter: docs/engineering/KEVIN-SUPER-AI-NORTH-STAR-CHARTER-v1.md
Teach-and-transfer: docs/engineering/KEVIN-TEACH-AND-TRANSFER-RULE-v1.md
Handover: AI-HANDOVER.md only (no GROK-HANDOVER). Cold-start: docs/engineering/KEVIN-TURNOVER-LATEST.md. Execution contract: inbox/CURRENT_TASK.md.

Owner ask (Matt ~11:04 MT): full PC agency (open/control apps, build/create); Minecraft as a player/friend on Discord headset; email/SMS/phone; crypto trading on his accounts; independent online businesses; spawn useful subagents; connect hardware. GO MAX via deep research of successful LOCAL AI agent builds.

## 0. Hardware truth (do not fight)

- CPU: Ryzen 7 3700X. Fine for Node gateways + Mineflayer + flying-squid.
- GPU: RTX 3060 12GB (~11GB usable). Qwen 2.5 14B Q4 ~9GB is the ceiling. ONE 14B resident.
- RAM: 32GB. Context 16k is feasible. RAM is not a VRAM substitute.
- OS: Windows 11. OpenClaw + Ollama CUDA.
- Main model: ollama-chat-16k/qwen2.5:14b canary OMEN_PROVEN. Do not dual-load a second 14B.
- Also cached: llama3.1:8b (Aider scratch). Prefer 8B for side brains while Chat holds 14B.
- Chat 18789 / Reader 19001: do not kill. Operator isolated 19101 only.
- Desktop exact-4 LIVE (PR 77): kevin_system_status, kevin_desktop_find_folder, kevin_desktop_open_folder, kevin_app_launch. openclaw.json SHA256 4126AFE6. Do not break or widen.

VRAM rule: Chat 14B + Mineflayer-LLM + Discord-STT + Aider 14B = thrash. Sequence. Side faculties use 8B, public APIs, or idle windows.

## 1. What actually works offline on this box (research)

Sources: Open Interpreter issues 1577/1599/1652; OpenClaw computer-use + Discord docs (2026); Mineflayer / flying-squid / yearn-for-mines / mc-agent / Amelia; Coinbase Advanced sandbox docs; Aider+Ollama 2026 guides; Open WebUI Windows 2026; prior Kevin PLAN-kevin-peer-local-ai-stack-2026-09-02.md.

### 1.1 Coding / OS agents

- Aider + Ollama: YES. Use ollama_chat prefix. Python must be less than 3.13. ALREADY INSTALLED at scratch/aider-ollama-demo (aider-chat 0.86.2, Python 3.12). Recipe KEVIN-RECIPE-aider-ollama-scratch-v1.md. Best local coder for this GPU.
- Continue.dev / Cline: YES with context cap; Cline hungrier. SHOULD later. Not today.
- Open Interpreter classic: FRAGILE. Qwen often emits JSON tool-calls and does not execute unless llm_supports_functions is disabled. Unattended OS mode is too eager for an always-on coworker. SKIP unattended. Supervised scratch only if Aider is insufficient.
- OpenHands: Docker sandbox; 14B SWE-bench weak; heavy. SKIP on this GPU.
- AutoGPT / MetaGPT / CrewAI free-form: peers report circular tools and handoff drift. SKIP. Kevin already has Reader/Operator/Chat + Forge + Skill Lab.
- Open WebUI desktop: works with Ollama. SKIP because Control UI already covers owner chat.

### 1.2 Computer use / PC agency

- Kevin Desktop v0.1 LIVE: typed allowlist. Find/open Desktop child folders. Launch notepad, calculator, paint, explorer. This is the P0 path. Chat must actually call these tools. Other worker owns live prove. Do not rewrite the plugin or openclaw.json.
- OpenClaw computer / CUA: Windows cua-computer plugin is experimental. Needs computer.act plus screen.snapshot, pairing, and a vision model. Qwen 2.5 14B is not a reliable CUA driver. Enabling it would widen Chat tools. Destination / later YELLOW. Do not enable while exact-4 is LIVE. Prefer typed tools (P1) over screenshot-click.
- ui_notepad_write: GREEN primitive PROVEN via Action Era UI Bridge. Skill Lab / Green Operator, not Chat fixed:main. Do not confuse with kevin_app_launch notepad.

Peer lesson: scoped typed effectors beat unattended OS agents on always-on coworkers.

### 1.3 Minecraft player

- Mineflayer + pathfinder: YES. Node 18+. auth offline on a local server. P2 v0. JS bot uses no GPU. Brain via Ollama OpenAI-compat when idle or on 8B.
- flying-squid: YES. JS server, online-mode false, localhost 25565. Preferred v0 server. No paid host. No Microsoft login.
- Baritone: Java client-side; hard to drive from Mineflayer. SKIP v0. Pathfinder is enough.
- yearn-for-mines / Amelia / mc-agent: architecture references (perceive, plan, execute). Steal the loop; do not vendor the whole monorepo.
- Matt Minecraft server: USER.md and workspace do not document host/port/version. Use local flying-squid until Matt documents a server. Then auth is a separate named gate.

LLM on 14B: high-level chat and goals only. Movement must be deterministic pathfinder, not free-form JSON. Do not keep 14B loaded just for the bot.

### 1.4 Discord (text then voice / headset)

- OpenClaw native Discord channel: text works once a bot token is in env SecretRef, never in the repo. P3 destination. Kevin-owned token. Pairing plus guild allowlist. Do not patch openclaw.json today.
- discord.js scratch: library-only, no login. SAFE install for experiments.
- OpenClaw Discord voice: realtime default wants paid OpenAI/Gemini realtime. ffmpeg required. Voice later. Paid realtime is RED / purchasing.
- Local STT/TTS: Whisper.cpp + Piper (OpenClaw-Discord-Voice pattern). FREE local headset path after text works. Needs ffmpeg plus local models (disk/VRAM budget).
- followUsers: OpenClaw can join Matt voice channel when he is in it. Headset destination after local STT/TTS, not cloud TTS.

### 1.5 Email / SMS / phone

- IMAP/SMTP OpenClaw plugins exist. Need app password or local mailer. Secrets not in repo. P4. Kevin-owned secret store. Allowlist senders.
- Gmail API: OAuth with Kevin-local token. Destination variant. Same secret rules as Drive PLAN.
- Local smtp4dev / hMailServer: optional lab. Not required if a Gmail app password exists later.
- SMS / paid voice calls: Twilio and similar are paid. RED. No paid phone/SMS without a separate named go-ahead.

### 1.6 Crypto

- Kevin paper journal v0 at reports/coinbase-paper-v0: public ticker GET only; 45/45 tests; COINBASE_* and MOONSHOT_* env refuse. P5 already GREEN harness.
- crypto-research-paper-trading-pack@1 Skill Lab PROVEN ~08:57 MT. Do not re-prove.
- Coinbase Advanced sandbox: static mocked responses, no auth, not real paper fills. Optional shape-test only.
- Live Coinbase / Moonshot: HARD NO. No login, scrape, wallet export, live orders.

### 1.7 Business / subagents / hardware

- GREEN composites: proven_count 20 (dealer, appliance@3, creator, crypto paper, dealership-friction, and more). P6 already a GREEN lane. Keep authoring unproven owner packs.
- OpenClaw sessions_spawn: native subagents. Windows reports of gateway crash when combined with sessions_yield; prefer list/poll. Dual 14B impossible. Chat tools currently exact-4 only. Destination: spawn 8B or sequential. Do not add sessions_spawn to Chat today.
- Hardware: no Kevin typed USB/serial/printer faculty yet. Destination after P1 typed PC agency. Never generic shell.

## 2. Standing HARD NOS (do not weaken)

- No live Coinbase or Moonshot trades. Paper and read-only only. Moonshot: no login, scrape, or wallet export.
- No paid phone calls or purchases without a separate named go-ahead.
- No kevin_shell. No widening Chat tools beyond the proof bar of the current phase.
- Desktop exact-4 already LIVE. Do not break it. Chat 18789 and Reader 19001 do not kill.
- Teach-and-transfer. AI-HANDOVER via CURRENT_TASK. No GROK-HANDOVER.
- Kevin must own faculties (not CoS proxy). Secrets stay in Kevin-local store, never git, MEMORY, or HQ.
- Natural language is intent, never raw shell authority.
- A model turn, hash match, or green dashboard is NOT_OUTCOME_PROOF.

## 3. Sequenced faculties

Progress equals isolated proof, then a recipe Kevin can re-run, then a typed crossing if production Chat tools change. Never skip a proof bar by relabeling.

### P0 TODAY - Chat must actually use Desktop tools

- Owner value: Matt can ask Kevin to find or open a Desktop folder or launch Notepad, Calc, Paint, or Explorer from Chat, and it happens.
- Existing Kevin code: YES. Plugin kevin-work-repo/extensions/kevin-desktop (desktop.ts). LIVE exact-4 on fixed:main. kevin_app_launch allowlist already includes notepad, calculator, paint, explorer.
- Free/safe install: none. Already installed.
- Proof bar: other worker owns LIVE PROVE. Independent checks: two fresh owner-intent Chat turns invoke a Desktop tool (not just list tools); Explorer or app window observed; Benchmark 30/30; openclaw.json still 4126AFE6; Chat 18789 and Reader 19001 alive. Contract: KEVIN-DESKTOP-TYPED-CROSSING-CONTRACT-2026-09-03.md positive proofs.
- RED gates: do not widen tools; do not rewrite Desktop, openclaw.json, Chat, or Owl; do not launch caller-selected executables; do not race the live-prove worker.
- This run: PLAN plus pointer only. Destination-only for this worker.

### P1 - Typed tools: notepad, explorer, chrome-url (YELLOW, proof bar)

- Owner value: reliable open Notepad, open Explorer at a bounded folder, open one allowlisted URL in Chrome, without generic computer-use.
- Existing Kevin code: PARTIAL. notepad and explorer already inside kevin_app_launch and kevin_desktop_open_folder. chrome-url does NOT exist. Proven-primitives registry lists browser as NOT_YET_PROVEN. Green Operator ui_notepad_write is a different surface (Skill Lab), not Chat.
- Free/safe install: no new app. Chrome assumed present. Faculty is typed plugin args: https only, host allowlist (start with localhost, later Matt-approved).
- Proof bar (YELLOW): isolated plugin tests allow notepad/explorer; deny unsafe executables; chrome-url opens one allowlisted URL; deny file schemes, javascript schemes, unknown hosts, argv injection. Then a SEPARATE typed Chat crossing (exact new tool id only) with rollback. Not today.
- RED gates: no generic browser; no downloads; no profile takeover; no CUA enable; no Chat widen until P0 live-prove is GREEN and a typed packet exists.
- This run: design in this PLAN. No Chat config.

### P2 - Minecraft player v0 (Mineflayer, local server)

- Owner value: Kevin can join a world as a player/friend: chat, pathfind, follow, basic gather. Later the same character on Discord headset.
- Existing Kevin code: NO Mineflayer bot in the workspace.
- Free/safe install: YES. mineflayer plus mineflayer-pathfinder plus flying-squid in scratch/kevin-minecraft-v0. Local offline-mode. No paid server. No Microsoft login.
- Proof bar v0: packages in scratch; local JS server on localhost; offline username KevinBot joins, sends chat marker KEVIN_MC_V0_OK, leaves, server stops, receipt. LLM brain deferred until idle 8B or Chat 14B free.
- RED gates: no paid or public server; no Microsoft credentials in repo; no grief or spam; no Chat tool; do not bind Chat, Reader, or Ollama ports; stop the local server after proof.
- Matt server: not documented. Stay local until host, port, version, and auth are written by Matt in USER.md or a private receipt.

### P3 - Discord text first, voice later (headset)

- Owner value: talk to Kevin from Discord; later hear him in the same voice channel as Matt headset.
- Existing Kevin code: OpenClaw supports Discord natively. Kevin workspace has no connected Discord config in repo (correct: secrets must not live there). No discord.js project yet.
- Free/safe install: YES library discord.js in scratch/kevin-discord-text-v0. No login. OpenClaw channel enable later with env SecretRef.
- Proof bar text: scratch client constructs without login. Later: Kevin-owned secret on disk, pairing DM, allowlisted guild reply KEVIN_DISCORD_TEXT_OK. Secret never in git.
- Proof bar voice (later): local Whisper plus Piper, or OpenClaw stt-tts with local media tools. ffmpeg present. followUsers equals Matt. Not paid realtime.
- RED gates: no secret in repo; no connect unless Kevin-owned secret already on disk; no paid TTS/STT; no Chat widen; no bot-to-bot loops.

### P4 - Email send/read (local SMTP/IMAP or Kevin-owned Gmail API)

- Owner value: Kevin reads Matt-allowlisted mail and can send to allowlisted recipients.
- Existing Kevin code: NO IMAP helper. Drive PLAN is the closest secret-store pattern.
- Free/safe install: plugin later. Lab smtp4dev optional. Gmail app password in Kevin-local store.
- Proof bar: dry parse fixture eml, allowlist pass/fail, no network. Then IMAP list one allowlisted folder with Kevin-owned secret; send one mail to Matt only; receipt with hashes not bodies.
- RED gates: no secrets in repo; no send-all; no paid mail APIs; SMS/phone still RED; CoS must not hold Kevin mail token.

### P5 - Paper crypto only

- Owner value: research plus paper journal; never live money until a separate named go-ahead.
- Existing Kevin code: YES GREEN. reports/coinbase-paper-v0 (public ticker, local JSONL, Moonshot equals human mark only). Pack crypto-research-paper-trading-pack@1 PROVEN. Yellow Y5 forty-five of forty-five.
- Free/safe install: none required. Optional unauthenticated Coinbase sandbox shape tests.
- Proof bar: re-run the paper journal unit suite with trade keys unset. Expect 45/45. No authenticated accounts or orders paths.
- RED gates: live Coinbase/Moonshot; any key in env during market calls (helper refuses, keep that); wallet export; Hummingbot/Freqtrade.

### P6 - Business research packs (already GREEN composites)

- Owner value: independent online businesses, dealership, appliance, creator. Replayable workbooks Matt can use.
- Existing Kevin code: YES. Skill Lab primitives create_spreadsheet plus create_text (and ui_notepad_write). proven_count 20. Recipe KEVIN-RECIPE-stage-prove-green-composite-v1.md.
- Free/safe install: none. Author next unproven owner pack (sheet cap 1 to 5, ASCII, unique Kevin-* filenames). Not appliance@3 (MIN_REPEAT).
- Proof bar: Relay STAGED then Skill Lab PROVEN plus registry count bump plus outputs under Documents/Kevin Outputs.
- RED gates: Relay shell; live spend/ads; secrets in sheets; overwrite proven filenames.

## 4. Later destination (not this sequence P0 to P6)

- SMS and paid phone: RED until named go-ahead plus typed allowlist plus spend cap.
- OpenClaw CUA computer-use: after P1 typed chrome-url plus a vision model pin; never as a Chat widen sneak.
- Subagent spawn: sessions_spawn with 8B side model; on Windows avoid yield-crash; not on exact-4 Chat until typed crossing.
- Hardware: typed USB/serial/printer tools, deny generic paths.
- Social post, Amazon, pizza: commerce charter items; each needs its own proof plus paid gate.
- Drive read-only: already YELLOW PLAN; Destination A then C; CoS interim only.

## 5. Recommended next proofs (priority)

1. P0 live prove (other worker): Chat actually calls Desktop tools.
2. P6 GREEN (this lane): stage one unproven owner pack (independent online business research). Does not touch Chat.
3. P2 scratch install plus local join proof when Node is free: Mineflayer to flying-squid marker KEVIN_MC_V0_OK.
4. P5 refresh (anytime, short): paper 45/45.
5. P1 design packet (YELLOW source only) for kevin_chrome_open_url after P0 prove.
6. P3 only after a Kevin-owned Discord secret is confirmed on disk (do not hunt secrets).

## 6. Install policy this run

Allowed without asking (UNDYING GREEN+YELLOW, FREE+SAFE):
- Scratch Node projects under scratch/ that never touch Chat, Desktop, openclaw.json, or Supervisor.
- Recipes, LESSONS, and this PLAN.
- GREEN composite author/stage (sheet cap at most 5).

Not this run:
- Discord or email login.
- Chat tool policy edits.
- CUA plugin enable.
- Paid models, paid voice, paid phone.
- Live brokerage.

## 7. Teach-and-transfer

Kevin re-runs this PLAN by reading:
1. inbox/CURRENT_TASK.md north-star section
2. This file
3. Recipes: Aider, Mineflayer, discord.js scratch, GREEN composite
4. Paper crypto README plus REFUSALS
5. Desktop crossing contract (exact-4)

Independence test: CoS offline, Kevin can pick the next P-item, run its proof bar, and write a receipt.

## 8. Explicit non-actions this run

- No openclaw.json, Desktop plugin, Chat port, or Owl geometry edits
- No kevin_shell, no sessions_spawn on Chat
- No Discord or email connect
- No live trades or Moonshot scrape
- No GROK-HANDOVER
- No competing P0 list (CURRENT_TASK remains P0 authority)
