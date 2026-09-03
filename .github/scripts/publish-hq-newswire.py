"""Publish only the validated newswire; never rebase or stage the checkout.

The repository contains historical CRLF blobs with LF attributes. A clean
checkout can therefore look dirty. An isolated index also preserves concurrent
Support commits without importing unrelated files into this publication.
"""
from __future__ import annotations

import os
from pathlib import Path
import subprocess
import tempfile

TARGET = 'reports/newswire-latest.json'


def git(*args: str, data: bytes | None = None, env=None) -> str:
    return subprocess.check_output(['git', *args], input=data, env=env).decode().strip()


def publish() -> str:
    content = Path(TARGET).read_bytes()
    blob = git('hash-object', '-w', '--stdin', data=content)
    with tempfile.TemporaryDirectory(prefix='kevin-news-index-') as temp:
        env = dict(os.environ, GIT_INDEX_FILE=str(Path(temp) / 'index'))
        for attempt in range(3):
            git('fetch', 'origin', 'main')
            parent = git('rev-parse', 'FETCH_HEAD')
            if git('rev-parse', f'{parent}:{TARGET}') == blob:
                print('NEWSWIRE_PUBLISH_UNCHANGED')
                return parent
            git('read-tree', parent, env=env)
            git('update-index', '--add', '--cacheinfo', f'100644,{blob},{TARGET}', env=env)
            tree = git('write-tree', env=env)
            commit = git('commit-tree', tree, '-p', parent, data=b'kevin hq newswire\n', env=env)
            changed = git('diff-tree', '--no-commit-id', '--name-only', '-r', commit)
            if changed != TARGET:
                raise RuntimeError('Publication touched an unexpected path')
            pushed = subprocess.run(['git', 'push', 'origin', f'{commit}:refs/heads/main'])
            if pushed.returncode == 0:
                print(f'NEWSWIRE_PUBLISHED {commit}')
                return commit
            print(f'NEWSWIRE_PUBLISH_RETRY {attempt + 1}/3')
    raise RuntimeError('Newswire publication failed after three bounded attempts')


if __name__ == '__main__':
    publish()
