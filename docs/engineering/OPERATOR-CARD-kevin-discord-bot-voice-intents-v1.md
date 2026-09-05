# OPERATOR CARD Kevin Discord bot voice+text v1

Status: READY_FOR_OWNER_TOKEN (parent owns secret-request UI)

## Create + invite
1. Discord Developer Portal -> New Application Kevin
2. Bot -> Message Content Intent ON
3. OAuth2 scopes bot + applications.commands
4. Perms: View, Send, Read History, Connect, Speak
5. Invite private server; make #kevin-chat + kevin-vc
6. Copy User/Server/Text/Voice channel IDs (non-secret)

## Owner secret card only
Land into machine-local .openclaw env (same key as text PLAN) OR credentials/kevin-discord file. Never git/chat/MEMORY/HQ.

## After landing
cd scratch/kevin-discord-voice-v0
install-deps.cmd
nm run start:text
Commands: !k follow | stop | guard | come | status | say hi
Voice later: npm run start:voice then !k join vc (allowlisted VC only)

## Notes
Dedicated bot app recommended. Never hessmodee. ffmpeg already on PATH.
