# West Motor Transport Dispatch - fictional operating note

GREEN example board for daily vehicle-transport dispatch. Generic example data only.
No customer PII, no live VIN, no purchases, sends, or DMS writes.

## How Matt can use it
1. Sort by Priority then Target Date/Time.
2. Assign Driver/Assignee on PLANNED rows before departure.
3. Move Status PLANNED -> ASSIGNED -> IN_TRANSIT -> DONE.
4. Put blockers in Exception / Completion; do not invent live facts.

## This example
- Rows: 6
- Still open: 5
- Skill bind: vehicle-transport-mission-pack@1 (already PROVEN create_spreadsheet+create_text).
- Authority: GREEN fictional rehearsal only.
