"""Check exact pointwise convolution against an independent finite integer oracle.

This checks mathematical model instances only. It does not inspect C++ or run XLA.
The unbounded result is proved in Lean; finite controls help review model meaning.
"""
from itertools import product
import hashlib
import json
from pathlib import Path
import re
import subprocess

from convolution_examples import evaluate

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = 'census/convolution-pointwise-v1.json'
PROFILES = [
    dict(name='one_channel', shape=(3,), channels=1),
    dict(name='grouped_two_dimensional', shape=(2, 2), channels=3,
         batch_groups=2, batches=2, feature_groups=2, features=2),
    dict(name='reversed_kernel_dilation', shape=(3,), channels=2,
         features=2, dilation=7, reverse=True),
    dict(name='zero_channels', shape=(3,), channels=0),
    dict(name='empty_spatial', shape=(0, 0), channels=2),
    dict(name='rank_zero', shape=(), channels=2),
    dict(name='rank_zero_no_channels', shape=(), channels=0),
    dict(name='no_batch_groups', shape=(3,), channels=2, batch_groups=0),
]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def expected():
    counts = []; rows = []
    for profile in PROFILES:
        name = profile['name']; shape = profile['shape']; rank = len(shape)
        channels = profile['channels']; batches = profile.get('batches', 1)
        coordinates = product(range(profile.get('batch_groups', 1)), range(batches),
                              range(profile.get('feature_groups', 1)),
                              range(profile.get('features', 1)),
                              product(*(range(n) for n in shape)))
        results = []
        for group, batch, feature_group, feature, spatial in coordinates:
            value = evaluate(inputs=shape, kernels=(1,)*rank,
                             dilations=(profile.get('dilation', 1),)*rank,
                             reverse=profile.get('reverse', False),
                             batch_group=group*batches+batch, feature_group=feature_group,
                             channels=channels, output=spatial, channel_weight_base=3,
                             output_feature_factor=feature+1, scale=group+1)
            assert value is not None
            results.append(value)
        counts.append((name, str(len(results))))
        rows.extend((name, str(i), str(v), str(v)) for i, v in enumerate(results))
    return counts, rows


def validate_result(result):
    assert result['status'] == 'kernel_checked_pointwise_convolution_to_channel_sum'
    assert result['scalar_contract'] == 'exact_semiring'
    for key in ('full_convolution_family_complete', 'dot_tensor_bridge_proved',
                'physical_layout_modeled', 'precision_conversions_modeled',
                'ieee_accumulation_contract_proved', 'independently_reviewed_statements',
                'code_correspondence_performed'):
        assert result[key] is False, key
    assert result['code_correspondence_future_work'] is True
    assert result['whole_benchmark_records_closed'] == 0
    counts, rows = expected()
    assert result['profile_counts'] == [dict(name=n, count=int(c)) for n, c in counts]
    assert result['controls'] == [dict(name=n, index=int(i), convolution=int(c), channel_sum=int(s))
                                  for n, i, c, s in rows]
    assert result['semantic_profile_count'] == len(counts) == 8
    assert result['semantic_output_count'] == len(rows) == 78
    assert result['checked_statement_count'] == len(result['certificate_axioms']) == 13
    assert all(set(a) <= {'propext', 'Quot.sound', 'Classical.choice'}
               for a in result['certificate_axioms'].values())


def main():
    manifest = json.loads((ROOT/MANIFEST).read_text())
    for file in manifest['files']:
        assert digest(ROOT/file['path']) == file['sha256'], file['path']
    build = subprocess.run(['lake', 'build', 'TensorRewriteTheory'], cwd=ROOT,
                           text=True, capture_output=True)
    assert build.returncode == 0, build.stdout + build.stderr
    controls = subprocess.run(['lake', 'env', 'lean',
                               'tests/fixtures/ConvolutionPointwiseControls.lean'],
                              cwd=ROOT, text=True, capture_output=True)
    assert controls.returncode == 0, controls.stdout + controls.stderr
    counts = re.findall(r'^POINTWISE_COUNT case=(\w+) count=(\d+)$', controls.stdout, re.M)
    rows = re.findall(r'^POINTWISE case=(\w+) index=(\d+) conv=(-?\d+) channels=(-?\d+)$',
                      controls.stdout, re.M)
    assert (counts, rows) == expected(), (counts, rows)
    theory = json.loads((ROOT/'reports/theory-progress.json').read_text())
    for file in theory['files']:
        assert digest(ROOT/file['path']) == file['sha256'], file['path']
    certificates = {name: axioms for name, axioms in theory['axiom_dependencies'].items()
                    if '.ConvolutionPointwise.' in name}
    assert set(certificates) == set(manifest['certificates']) and len(certificates) == 13
    assert all(set(a) <= {'propext', 'Quot.sound', 'Classical.choice'}
               for a in certificates.values())
    result = dict(status='kernel_checked_pointwise_convolution_to_channel_sum',
                  manifest=MANIFEST, manifest_sha256=digest(ROOT/MANIFEST),
                  certificate_axioms=certificates, checked_statement_count=len(certificates),
                  semantic_profile_count=len(counts), semantic_output_count=len(rows),
                  controls_stdout=controls.stdout,
                  profile_counts=[dict(name=n, count=int(c)) for n, c in counts],
                  controls=[dict(name=n, index=int(i), convolution=int(c), channel_sum=int(s))
                            for n, i, c, s in rows],
                  scalar_contract='exact_semiring', full_convolution_family_complete=False,
                  dot_tensor_bridge_proved=False, physical_layout_modeled=False,
                  precision_conversions_modeled=False, ieee_accumulation_contract_proved=False,
                  whole_benchmark_records_closed=0, independently_reviewed_statements=False,
                  code_correspondence_performed=False, code_correspondence_future_work=True)
    validate_result(result)
    (ROOT/'reports/convolution-pointwise.json').write_text(json.dumps(result, indent=2)+'\n')
    print(f'Pointwise convolution passed: 13 statements, {len(counts)} profiles, '
          f'{len(rows)} oracle-agreeing outputs; exact semiring only.')


if __name__ == '__main__':
    main()
