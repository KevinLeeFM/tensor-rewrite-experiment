"""Rebuild comparison imports, then independently recheck every local comparison module."""
import concurrent.futures
import hashlib
import json
import re
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
IMPORT = re.compile(r'^\s*(?:public\s+)?import\s+(TensorRewrite(?:\.\w+)*)\s*$', re.M)
AXIOM = re.compile(r'depends on axioms: \[([^]]*)\]')
ALLOWED = {'propext', 'Quot.sound', 'Classical.choice'}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def run_module(path):
    start = time.monotonic()
    result = subprocess.run(['lake', 'env', 'lean', str(path.relative_to(ROOT))], cwd=ROOT,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    output = result.stdout
    reported = re.findall(r"^'[^']+' (?:does not depend on any axioms|depends on axioms: \[)",
                          output, flags=re.M)
    axioms = {item.strip() for match in AXIOM.findall(output)
              for item in match.split(',') if item.strip()}
    ok = (result.returncode == 0 and bool(reported) and axioms <= ALLOWED and
          not any(s in output for s in ['sorryAx', 'error:', 'warning:']))
    print(f"{'PASS' if ok else 'FAIL'} {path.name}", flush=True)
    return {'module': str(path.relative_to(ROOT)), 'source_sha256': sha(path.read_bytes()),
            'exit_code': result.returncode, 'elapsed_seconds': round(time.monotonic()-start, 3),
            'axioms': sorted(axioms), 'axiom_reports': len(reported), 'passed': ok,
            'output_sha256': sha(output.encode()), 'output': output}


def main():
    start = time.monotonic()
    modules = sorted(OUT.glob('*.lean'))
    imports = sorted({m for path in modules for m in IMPORT.findall(path.read_text())})
    print(f'Rebuilding {len(imports)} direct custom imports for {len(modules)} modules', flush=True)
    build = subprocess.run(['lake', 'build', *('+' + m + ':olean' for m in imports)], cwd=ROOT,
                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    (OUT / 'replay-build.log').write_text(build.stdout)
    if build.returncode:
        print(f'Import build failed: {build.returncode}; see replay-build.log', flush=True)
        raise SystemExit(build.returncode)
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        results = list(pool.map(run_module, modules))
    data = {'schema': 1, 'completed_utc': datetime.now(timezone.utc).isoformat(),
            'method': 'Lake rebuilt direct custom imports and dependencies; each comparison '
                      'module was then checked in a separate Lean process, at most three in parallel.',
            'lean_toolchain': (ROOT / 'lean-toolchain').read_text().strip(),
            'lake_manifest_sha256': sha((ROOT / 'lake-manifest.json').read_bytes()),
            'build_targets': imports, 'build_exit_code': build.returncode,
            'build_output_sha256': sha(build.stdout.encode()),
            'elapsed_seconds': round(time.monotonic()-start, 3),
            'allowed_axioms': sorted(ALLOWED), 'modules': results}
    (OUT / 'replay-audit.json').write_text(json.dumps(data, indent=2) + '\n')
    if not all(r['passed'] for r in results):
        raise SystemExit('One or more comparison modules failed replay')
    print(f'All {len(results)} comparison modules passed fresh Lean checks', flush=True)


if __name__ == '__main__':
    main()
