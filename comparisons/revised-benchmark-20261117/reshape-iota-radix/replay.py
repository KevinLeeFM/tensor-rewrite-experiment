"""Fresh offline Lean replay for the reshaped Iota model cases."""
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
    for name in ('RadixSpec', 'RadixProof', 'RadixControls'):
        src = (root if '/' in name else packet) / (name + '.lean')
        file = tmp / (name + '.lean')
        file.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src, file)
        start = time.monotonic()
        res = subprocess.run([lean, '-o', name + '.olean', name + '.lean'], cwd=tmp,
                             env={**os.environ, 'LEAN_PATH': str(tmp)})
        print(f'{name} {time.monotonic() - start:.3f}s exit={res.returncode}', flush=True)
        res.check_returncode()
