from pathlib import Path

worker = Path('control-plane/dispatcher/kevin-mission-worker-v0.1.ps1').read_text(encoding='utf-8')
dispatcher = Path('control-plane/dispatcher/kevin-mission-dispatcher-v0.1.ps1').read_text(encoding='utf-8')
if 'Parse-ReviewStructuredFallback' in worker and '$State.failure_family -eq $family' in dispatcher:
    print('PATCH_V13_ALREADY_APPLIED')
    raise SystemExit(0)

p = Path('.github/scripts/patch-control-plane-v13-review-contract.py')
src = p.read_text(encoding='utf-8')
for old, new in [("old_failure = '''", "old_failure = r'''"), ("new_failure = '''", "new_failure = r'''")]:
    if src.count(old) != 1:
        raise SystemExit(f'patch runner expected one marker: {old}')
    src = src.replace(old, new, 1)
exec(compile(src, str(p), 'exec'), {'__name__': '__main__'})
