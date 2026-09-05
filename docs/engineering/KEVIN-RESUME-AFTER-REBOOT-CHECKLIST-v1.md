# Kevin resume after reboot checklist v1

After HESS-PC reboot + interactive login (Owner Autologon or manual):

1. Confirm session unlocked (interactive desktop).
2. Do **not** kill Chat 18789 / Reader 19001 / Operator 19101 if already healthy.
3. Check listeners: Chat 18789, Reader 19001, Operator 19101.
4. Optional: `kevin_system_status` / board health.
5. For Realms stay: `KEVIN_ALLOW_CLOSE_MC=1` then `scratch\kevin-minecraft-stack-spike-v0\rejoin-companion.cmd`
   - Kevin closes Minecraft.Windows himself via `kevin-app-close.ps1` / typed `kevin_app_close`.
6. Xbox as hessmodee joins Realm; Kevin is kevinsk8erkid only.
7. Receipts: JOIN_OK / FOLLOW_OK / COMBAT_OK only with live proof.

Unattended restart script (candidate): announce reboot, `shutdown /r /t 60`, post-boot wait for explorer.exe + user session, then print this checklist. **No password handling.**
