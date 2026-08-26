---
name: self-check
description: Run helper_self_check.py when something might be broken; fix only FAIL lines via exec.
---

Exec: python C:\\Users\\hessm\\.openclaw\\workspace\\helper_self_check.py
Read reports/self-check.md. For each FAIL, run the matching helper once. Do not create new agents. Do not pull models.
