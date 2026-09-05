# READY_FOR_OWNER_TOKEN

Matt phone-ok steps (parent owns secret-request widget):
1. Discord Developer Portal -> New Application Kevin
2. Bot create; Message Content Intent ON
3. OAuth2: bot + applications.commands; perms View/Send/Connect/Speak
4. Invite private server; note guild/user/text/voice channel IDs:
5. Deliver bot credential via owner secret card into machine-local .openclaw env (key name matches existing text PLAN) or credentials/kevin-discord file
6. Set owner user id + voice channel allowlist env vars (non-secret IDs)
7. Run token-gate script; then nmp run start:text
Never paste credential into git/chat/MEMORY/HQ.
