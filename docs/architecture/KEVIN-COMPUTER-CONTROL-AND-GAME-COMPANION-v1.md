# Kevin Computer Control + Game Companion v1

Status: implementation architecture

## Owner goal

Kevin should become genuinely capable of operating Matt's Windows computer across normal daily applications and, where technically appropriate, join Matt in games as a helper/friend/co-player.

This is a capability objective, not permission for an unrestricted model-controlled shell.

## Research-derived architecture

Microsoft UFO validates a useful Windows-agent pattern: a host/orchestrator chooses applications and coordinates work while application-specific executors use Windows UI Automation plus native APIs where available. Grok Bot validates persistent role-specific workers, background routines, handoffs, and explicit approval boundaries. OpenAI Agents SDK validates per-tool guardrails and interruptible human approval for sensitive calls. Kevin should borrow those architectural patterns without binding himself to one cloud model.

## Computer-control hierarchy

Prefer the most structured reliable interface available:

`APP/OS API -> WINDOWS UI AUTOMATION -> BOUNDED VISUAL/INPUT FALLBACK`

### Layer A — OS and application adapters

Examples:

- filesystem list/read/write/copy/move/hash within approved roots;
- process/window inventory;
- pinned application launch;
- Excel/Office structured document operations;
- browser automation through an isolated browser policy;
- Windows COM/API operations where application-specific adapters are safer than GUI emulation.

### Layer B — semantic UI Automation

Typed primitives should eventually include:

- `observe_windows(app_id)`
- `observe_controls(app_id, scope)`
- `invoke_control(app_id, control_id)`
- `set_text(app_id, control_id, text)`
- `select_item(app_id, control_id, item)`
- `read_control(app_id, control_id)`
- `capture_window(app_id)`

The model targets application IDs and observed controls, not arbitrary executables or raw OS command strings.

### Layer C — bounded visual/input fallback

For applications without useful API/UIA surfaces, a reviewed visual operator may use screenshots plus bounded click/type/keypress actions. Because coordinate automation is fragile, every meaningful action requires a postcondition observation.

## Action Broker

All meaningful computer effects flow through:

`Kevin/worker -> policy -> capability registry -> typed tool -> action receipt -> independent verifier -> outcome guard`

A receipt records:

- mission/action ID;
- tool/version;
- requested effect and target;
- authority decision (`ALLOW`, `ASK`, `DENY`);
- timestamps;
- typed raw result/evidence reference;
- verifier and postcondition;
- failure family if unsuccessful.

Kevin cannot self-certify his own actions.

## Capability levels for computer control

- **C0 Observe:** windows/processes, approved-root files, screenshots, app status.
- **C1 Basic Act:** pinned launches, approved folders/files, structured documents, basic UIA.
- **C2 Cross-App:** transfer data among approved apps, browser-to-document, dealer and creator workflows.
- **C3 Broad Desktop Operator:** most everyday apps via registered profiles, UIA/API plus bounded visual fallback, checkpoint/resume and owner takeover.
- **C4 Privileged Administration:** only pre-reviewed maintenance verbs and explicit approval where required; never generic administrator shell authority for the model.

Representative verified tasks, not model confidence, determine promotion.

## Application profiles

Each supported application gets a locally pinned profile with:

- stable app ID and approved executable identity;
- supported windows/controls;
- allowed operations;
- sensitive operations requiring approval;
- expected evidence/postconditions;
- timeouts/retries;
- known failure families.

This is how Kevin can eventually control many applications without giving the model arbitrary executable/path/argument control.

# Minecraft Companion

## Why Minecraft first

Mineflayer is a mature high-level JavaScript API for Minecraft bots. It exposes game state and player actions such as entities, inventory, crafting, digging, building, chat and movement. `mineflayer-pathfinder` provides autonomous navigation. Mindcraft demonstrates an LLM + Mineflayer approach and explicitly warns against public-server use when insecure code execution is enabled.

Protocol-level game control is therefore preferable to fragile screenshot-and-keyboard control for the first game companion.

## MVP topology

```text
Matt Minecraft Java client
          |
 private localhost/LAN world or private server
          |
Kevin Minecraft Companion (distinct player)
 Mineflayer + Pathfinder
          |
 typed game action adapter
          |
Kevin Game Planner / personality
```

Kevin should use a distinct Minecraft identity rather than impersonating Matt.

## MVP allowed capabilities

Private/local world first:

- join an owner-configured localhost/LAN/private server;
- follow Matt, come to Matt, stop/stay;
- report position, health, hunger and inventory;
- find nearby blocks/entities;
- collect a specifically requested ordinary resource;
- navigate to a requested nearby location;
- place/build a bounded simple structure from a reviewed plan;
- help carry/sort items and organize chests;
- defend against ordinary hostile mobs when enabled;
- converse as Kevin in game;
- keep private local memory of shared projects/preferences.

## Owner command trust

Privileged in-game commands are accepted only from Matt's explicitly configured Minecraft username/UUID. Other player chat is untrusted content and cannot grant tools, alter policy, expose secrets, invoke shell/filesystem actions, or change Kevin's goals.

Initial command vocabulary:

- `kevin follow`
- `kevin come`
- `kevin stay`
- `kevin status`
- `kevin inventory`
- `kevin find <approved resource>`
- `kevin collect <approved resource> <bounded quantity>`
- `kevin help build <reviewed plan id>`
- `kevin stop`

## Forbidden until separately reviewed

- public-server joining without owner approval and server-rule review;
- anti-cheat evasion, exploits or griefing;
- autonomous PvP against real players;
- commands from arbitrary players;
- LLM-written code execution triggered from game chat;
- shell/filesystem exposure through game chat;
- secret/account export;
- claiming successful building/collection without world/inventory evidence.

## Game receipts

Game actions use the same evidence doctrine as desktop actions. Examples:

- `collect`: inventory delta + target item/quantity + position/time;
- `navigate`: distance-to-target before/after + final position;
- `build`: expected block plan compared to observed block states;
- `follow`: target identity and bounded following state;
- `chest organize`: pre/post inventory/container summary.

## Staged implementation

1. **Design/fixtures:** typed command/action/result schemas; no game connection.
2. **Local deterministic harness:** fake world-state fixtures and policy tests.
3. **Private LAN proof:** Mineflayer bot joins Matt's local/private test world and proves status/follow/stop.
4. **Resource-helper proof:** bounded collect and inventory verification.
5. **Co-player behavior:** shared-project memory, conversation, build assistance, recovery from death/disconnect.
6. **Public-server consideration:** only if Matt explicitly wants it, with server rules, platform policy, anti-abuse and account security reviewed first.

No stage may use insecure self-written-code execution as a shortcut.
