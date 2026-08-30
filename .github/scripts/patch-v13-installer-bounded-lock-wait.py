from pathlib import Path

p=Path('control-plane/install/KEVIN-CONTROL-PLANE-v1.3-REVIEW-CONTRACT-REPAIR.ps1')
s=p.read_text(encoding='utf-8')
old="""  Step 'Acquire engineering and dispatcher maintenance locks'\n  $engOwned=$engMutex.WaitOne(0);if(-not $engOwned){throw 'Engineering worker is active. Retry after the current candidate run finishes.'}\n  $dispatchOwned=$dispatchMutex.WaitOne(0);if(-not $dispatchOwned){throw 'Mission dispatcher is active. Retry after the current dispatch finishes.'};Good 'Both maintenance locks acquired.'"""
new="""  Step 'Acquire engineering and dispatcher maintenance locks'\n  Note 'Waiting up to 12 minutes for any in-flight engineering/dispatch work to finish.'\n  $engOwned=$engMutex.WaitOne([TimeSpan]::FromMinutes(12));if(-not $engOwned){throw 'Timed out waiting for the engineering worker maintenance lock.'}\n  $dispatchOwned=$dispatchMutex.WaitOne([TimeSpan]::FromMinutes(2));if(-not $dispatchOwned){throw 'Timed out waiting for the mission dispatcher maintenance lock.'};Good 'Both maintenance locks acquired.'"""
if new in s:
    print('BOUNDED_LOCK_WAIT_ALREADY_APPLIED');raise SystemExit(0)
if s.count(old)!=1: raise SystemExit(f'lock anchor count={s.count(old)}')
s=s.replace(old,new,1)
p.write_text(s,encoding='utf-8')
print('BOUNDED_LOCK_WAIT_PATCHED')
