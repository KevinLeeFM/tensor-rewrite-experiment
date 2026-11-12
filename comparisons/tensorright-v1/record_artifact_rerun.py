"""Validate and summarize the saved offline rerun of the frozen TensorRight sources."""
import hashlib
import json
import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
SOURCE = ROOT / 'sources/tensorright/artifact/tr-artifact'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def typed_outcomes(block):
    results = {}
    for status, kind, line in re.findall(
            r'^\[(SUCCESS|FAIL)(?:-(Bool|Int|Real))?\]:(.*)$', block, re.M):
        if status == 'SUCCESS':
            outcome = 'proved'
        elif 'Not verified forall' in line:
            # Core/Verify.hs emits this only in the Right model branch.
            outcome = 'counterexample'
        elif 'solver failure' in line:
            outcome = 'inconclusive_solver_failure'
        else:
            outcome = 'failure_unclassified'
        results[kind or 'default'] = outcome
    return results


def main():
    rows = json.loads((OUT / 'cases.json').read_text())['cases']
    stdout = (OUT / 'artifact-rerun.stdout').read_text()
    stderr = (OUT / 'artifact-rerun.stderr').read_text()
    manifest = (OUT / 'artifact-rerun-frozen-sources.sha256').read_text()
    assert 'FROZEN_BUILD_COMPLETE\n' in stdout
    assert 'Total success: 115\nTotal failed: 3\n' in stdout
    for line in manifest.splitlines():
        expected, relative = line.split('  ', 1)
        assert sha((SOURCE / relative).read_bytes()) == expected, relative
    blocks = re.split(r'^====> ', stderr, flags=re.M)[1:]
    assert len(blocks) == len(rows) == 118
    archived_blocks = re.split(r'^====> ', (SOURCE / 'plot/result.txt').read_text(), flags=re.M)[1:]
    assert len(archived_blocks) == len(blocks)
    cases = []
    for row, block, archived_block in zip(rows, blocks, archived_blocks):
        labels = block.splitlines()
        label = labels[0]
        if row['id'] != 'reduce/rule03':
            assert label == row['reported_label'], (row['id'], label)
        else:
            # The artifact's unquoted echo expands the star to container-local filenames.
            assert label.startswith('Const ') and ' Reduce(X) ' in label
        status = re.findall(r'^\[(SUCCESS|FAIL)(?:-Overall)?\]:', block, re.M)
        assert status, row['id']
        outcome = 'proved' if status[-1] == 'SUCCESS' else 'not_proved'
        assert (outcome == 'proved') == (row['archived_result'] == 'proved'), row['id']
        cases.append({'id': row['id'], 'outcome': outcome,
                      'archived_outcome': 'proved' if row['archived_result'] == 'proved' else 'not_proved',
                      'archived_type_outcomes': typed_outcomes(archived_block),
                      'rerun_type_outcomes': typed_outcomes(block),
                      'label': label, 'result_block_sha256': sha(block.encode())})
    counts = Counter(row['outcome'] for row in cases)
    assert counts == {'proved': 115, 'not_proved': 3}
    result = {
        'schema': 1,
        'date': '2026-11-12',
        'image': 'lsrcz/tensor-right@sha256:2bff63d64900e2206d97666db503507abe16a898603b2eb2108422625afea047',
        'image_id': 'sha256:dd89a651d37ec14736680045400cb42b8b5330103117f3e84d73502315d67e66',
        'method': 'Copied the frozen source and rule trees plus package.yaml, stack.yaml and '
                  'runall.sh into the authors image, rebuilt with stack build, then ran '
                  './runall.sh in an offline disposable container. Reproduction script: '
                  'rerun_tensorright.sh. The image bundled different source files; the '
                  'recorded frozen and image manifests document those differences.',
        'environment': {'platform': 'Linux x86_64', 'ghc_used_by_stack': '9.8.2',
                        'stack': '3.1.1', 'z3': '4.8.12', 'cvc5': '1.2.0'},
        'source_manifest_sha256': sha(manifest.encode()),
        'image_source_manifest_sha256': sha((OUT / 'artifact-rerun-image-sources.sha256').read_bytes()),
        'stdout_sha256': sha(stdout.encode()), 'stderr_sha256': sha(stderr.encode()),
        'counts': dict(counts), 'matches_archived_outcomes': 118,
        'matching_scope': 'Aggregate success versus not-proved only; per-type counterexample and solver-failure outcomes can differ.',
        'label_exception': 'reduce/rule03: unquoted shell wildcard expands to directory-specific filenames',
        'cases': cases,
    }
    (OUT / 'artifact-rerun.json').write_text(json.dumps(result, indent=2, ensure_ascii=False) + '\n')
    print(f"{len(cases)} case outcomes match archive: {dict(counts)}")


if __name__ == '__main__':
    main()
