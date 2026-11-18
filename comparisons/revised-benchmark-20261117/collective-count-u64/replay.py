"""Fresh offline Lean replay for uniform collective sum."""
import os
import pathlib
import shutil
import subprocess
import tempfile
import time

packet = pathlib.Path(__file__).resolve().parent
root = packet.parents[2]
lean = os.environ.get('LEAN', 'lean')
subprocess.run(['sha256sum', '-c', str(packet / 'SHA256SUMS')], cwd=root, check=True)
with tempfile.TemporaryDirectory() as folder:
    tmp = pathlib.Path(folder)
    for name in ('ExchangeSpec', 'PrefixSpec', 'PrefixProof', 'GroupSpec', 'GroupProof', 'GroupControls'):
        src = (root if '/' in name else packet) / (name + '.lean')
        if name in ('PrefixSpec','PrefixProof'): src = packet.parent / 'prefix-wide-count' / (name + '.lean')
        if name == 'ExchangeSpec': src = packet.parent / 'uniform-exchange' / (name + '.lean')
        file = tmp / (name + '.lean')
        file.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src, file)
        start = time.monotonic()
        res = subprocess.run([lean, '-o', name + '.olean', name + '.lean'], cwd=tmp,
                             env={**os.environ, 'LEAN_PATH': str(tmp)})
        print(f'{name} {time.monotonic() - start:.3f}s exit={res.returncode}', flush=True)
        res.check_returncode()
