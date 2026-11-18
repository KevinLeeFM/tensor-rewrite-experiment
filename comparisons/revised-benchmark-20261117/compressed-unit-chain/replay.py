"""Fresh offline Lean replay for the compressed chain calculation."""
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
    for name in ('TensorRewrite/Pilot/Tensor', 'TensorRewrite/Pilot/Indexing', 'TensorRewrite/Pilot/Permutation', 'ChainSpec', 'ChainProof', 'RawSpec', 'RawProof', 'GuardSpec', 'BoundedSpec', 'GuardProof', 'ChainControls'):
        src = (root if '/' in name else packet) / (name + '.lean')
        file = tmp / (name + '.lean')
        file.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src, file)
        start = time.monotonic()
        res = subprocess.run([lean, '-o', name + '.olean', name + '.lean'], cwd=tmp,
                             env={**os.environ, 'LEAN_PATH': str(tmp)})
        print(f'{name} {time.monotonic() - start:.3f}s exit={res.returncode}', flush=True)
        res.check_returncode()
# The prior independent packet has overlapping module filenames. Keep its
# original unmodified source and build products in a fresh search path.
with tempfile.TemporaryDirectory() as folder:
    tmp = pathlib.Path(folder)
    for base, name in [('copy-layout-chain', 'CopySpec'), ('copy-layout-chain', 'CopyProof'),
                       ('copy-reshape-chain-terminal', 'ChainSpec'),
                       ('copy-reshape-chain-terminal', 'ChainProof'),
                       (packet.name, 'BufferEndpoint')]:
        file = name + '.lean'
        shutil.copyfile(packet.parent / base / file, tmp / file)
        start = time.monotonic()
        res = subprocess.run([lean, '-o', name + '.olean', file], cwd=tmp,
                             env={**os.environ, 'LEAN_PATH': str(tmp)})
        print(f'{base}/{name} {time.monotonic() - start:.3f}s exit={res.returncode}', flush=True)
        res.check_returncode()
