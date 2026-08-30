from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path

p = Path(__file__).with_name('test_integration_contract.py')
spec = spec_from_file_location('integration_tests', p)
mod = module_from_spec(spec)
spec.loader.exec_module(mod)
tests = sorted(name for name in dir(mod) if name.startswith('test_'))
for name in tests:
    getattr(mod, name)()
    print('PASS', name)
print(f'PASS {len(tests)}/{len(tests)}')
