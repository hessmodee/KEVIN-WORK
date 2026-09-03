"""Exercise real Git: dirty checkout, concurrent remote update, scoped commit."""
import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('publisher', Path(__file__).with_name('publish-hq-newswire.py'))
publisher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(publisher)


class PublicationTest(unittest.TestCase):
    def test_dirty_checkout_and_concurrent_commit_are_preserved(self):
        original = Path.cwd()
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            subprocess.run(['git', 'init', '--bare', str(root / 'remote.git')], check=True, capture_output=True)
            subprocess.run(['git', 'clone', str(root / 'remote.git'), str(root / 'work')], check=True, capture_output=True)
            os.chdir(root / 'work')
            try:
                g = publisher.git
                g('config', 'user.name', 'Test'); g('config', 'user.email', 'test@example.invalid')
                g('checkout', '-b', 'main')
                Path('reports').mkdir()
                Path(publisher.TARGET).write_text('{"headlines":[]}\n')
                Path('unrelated.txt').write_text('original\n')
                g('add', '.'); g('commit', '-m', 'initial'); g('push', 'origin', 'main')
                initial = g('rev-parse', 'HEAD')
                Path('unrelated.txt').write_text('local work must survive\n')
                Path('untracked.txt').write_text('also preserve me\n')
                Path(publisher.TARGET).write_text('{"headlines":["fresh"]}\n')
                # Simulate Support advancing main after the publisher's checkout.
                support_blob = g('hash-object', '-w', '--stdin', data=b'concurrent support\n')
                env = dict(os.environ, GIT_INDEX_FILE=str(root / 'other-index'))
                g('read-tree', initial, env=env)
                g('update-index', '--add', '--cacheinfo', f'100644,{support_blob},support.txt', env=env)
                remote = g('commit-tree', g('write-tree', env=env), '-p', initial, data=b'support\n')
                g('push', 'origin', f'{remote}:main')
                result = publisher.publish()
                self.assertEqual(g('rev-parse', f'{result}^'), remote)
                self.assertEqual(g('diff-tree', '--no-commit-id', '--name-only', '-r', result), publisher.TARGET)
                self.assertEqual(g('show', f'{result}:support.txt'), 'concurrent support')
                self.assertEqual(g('show', f'{result}:unrelated.txt'), 'original')
                self.assertEqual(Path('unrelated.txt').read_text(), 'local work must survive\n')
                self.assertTrue(Path('untracked.txt').exists())
                self.assertEqual(g('rev-parse', 'HEAD'), initial)
                self.assertEqual(publisher.publish(), result, 'unchanged replay must not commit')
            finally:
                os.chdir(original)


if __name__ == '__main__':
    unittest.main()
