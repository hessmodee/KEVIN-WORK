# Browser / Computer Use qualification design brief

**WorkInstance:** autonomy-browser-computer-qualification-fresh-2026-09-11-v1
**Predecessor:** autonomy-browser-computer-qualification-v1 (BOUNDED; no history reset)
**Actor:** GROKBOT_ACTED staging (not Kevin-learned)
**Notepad:** banned | **Chat/tool widen:** forbidden in this pack
**Primitives:** create_spreadsheet + create_text only
**Production upgrade:** NONE

## Plan
1. Inventory installed OpenClaw/browser/computer-use evidence without credentials or protected config changes.
2. Compare to isolated managed-browser and Windows Computer Use contracts.
3. Reversible qualification with explicit rollback, model/tool prerequisites, negative tests, and no-personal-browser / no-credential-handling boundary.
4. Do not blindly upgrade production; stage and independently prove before any later promotion.