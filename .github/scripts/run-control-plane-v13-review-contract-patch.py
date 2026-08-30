from pathlib import Path

p = Path('.github/scripts/patch-control-plane-v13-review-contract.py')
src = p.read_text(encoding='utf-8')
for old, new in [("old_failure = '''", "old_failure = r'''"), ("new_failure = '''", "new_failure = r'''")]:
    if src.count(old) != 1:
        raise SystemExit(f'patch runner expected one marker: {old}')
    src = src.replace(old, new, 1)
exec(compile(src, str(p), 'exec'), {'__name__': '__main__'})
