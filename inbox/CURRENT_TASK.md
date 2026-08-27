# Current task 2026-08-26 20:35

1. Pull workspace/helper_board.py
2. Run python helper_board.py — must print board.json path
3. Add this line to kevin-publish.ps1 if missing:
   Publish-Gh "reports/board.json" (Join-Path $ws "reports\board.json")
4. Run pull-inbox / publish once
5. Do not give Qwen exec/write tonight
