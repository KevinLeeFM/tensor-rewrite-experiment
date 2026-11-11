"""Verify the mathematical pointwise-convolution/Dot bridge and finite model meaning."""
from itertools import product
import hashlib
import json
from math import prod
from pathlib import Path
import re
import subprocess

from convolution_examples import evaluate
from check_convolution_pointwise import PROFILES as CHANNEL_PROFILES

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = 'census/convolution-dot-v1.json'
PROFILES = [dict(p, shape=(2, 3)) if p['name'] == 'grouped_two_dimensional' else dict(p)
            for p in CHANNEL_PROFILES] + [
    dict(name='no_batches', shape=(3,), channels=2, batches=0),
    dict(name='no_feature_groups', shape=(3,), channels=2, feature_groups=0),
    dict(name='no_output_features', shape=(3,), channels=2, features=0),
]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def expected():
    counts = []; rows = []
    for p in PROFILES:
        name = p['name']; shape = p['shape']; rank = len(shape)
        spatial = list(product(*(range(n) for n in shape)))
        spatial_count = prod(shape)
        batches = p.get('batches', 1); features = p.get('features', 1)
        batch_groups = p.get('batch_groups', 1); feature_groups = p.get('feature_groups', 1)
        for direction in ('convolution', 'matrix'):
            if direction == 'convolution':
                coordinates = [(g, b, h, o, x, b*spatial_count+i)
                               for g, b, h, o, (i, x) in product(
                                   range(batch_groups), range(batches), range(feature_groups),
                                   range(features), enumerate(spatial))]
            else:
                coordinates = [(g, row//spatial_count, h, o, spatial[row % spatial_count], row)
                               for g, h, row, o in product(range(batch_groups), range(feature_groups),
                                                          range(batches*spatial_count), range(features))]
            counts.append((name, direction, str(len(coordinates))))
            for i, (group, batch, feature_group, feature, position, row) in enumerate(coordinates):
                value = evaluate(inputs=shape, kernels=(1,)*rank,
                                 dilations=(p.get('dilation', 1),)*rank,
                                 reverse=p.get('reverse', False),
                                 batch_group=group*batches+batch, feature_group=feature_group,
                                 channels=p['channels'], output=position, channel_weight_base=3,
                                 output_feature_factor=feature+1, scale=group+1)
                assert value is not None
                rows.append((name, direction, str(i), str(value), str(value), str(row), str(feature)))
    return counts, rows


def check_inputs(root=ROOT):
    manifest = json.loads((root/MANIFEST).read_text())
    for file in manifest['files']:
        assert digest(root/file['path']) == file['sha256'], file['path']
    # Validate both frozen predecessor models, including all their recorded source pins.
    for key in ('base_model_manifest', 'channel_model_manifest'):
        path = manifest[key]
        assert digest(root/path) == manifest[key+'_sha256'], path
        predecessor = json.loads((root/path).read_text())
        for file in predecessor.get('files', predecessor.get('model_files', [])):
            assert digest(root/file['path']) == file['sha256'], file['path']
    return manifest


def validate_result(result):
    assert result['status'] == 'kernel_checked_pointwise_convolution_as_existing_dot'
    assert result['scalar_contract'] == 'exact_semiring'
    assert result['dot_tensor_bridge_proved'] is True
    assert result['both_coordinate_round_trips_proved'] is True
    for key in ('full_convolution_family_complete', 'physical_layout_modeled',
                'precision_conversions_modeled', 'ieee_accumulation_contract_proved',
                'independently_reviewed_statements', 'code_correspondence_performed'):
        assert result[key] is False, key
    assert result['code_correspondence_future_work'] is True
    assert result['whole_benchmark_records_closed'] == 0
    counts, rows = expected()
    assert result['profile_counts'] == [dict(name=n, direction=d, count=int(c)) for n, d, c in counts]
    assert result['controls'] == [dict(name=n, direction=d, index=int(i), convolution=int(c),
                                      dot=int(v), row=int(r), feature=int(o))
                                  for n, d, i, c, v, r, o in rows]
    assert result['semantic_profile_count'] == 11
    assert result['semantic_direction_count'] == 2
    assert result['semantic_output_comparisons'] == len(rows) == 220
    assert result['checked_statement_count'] == len(result['certificate_axioms']) == 12
    assert all(set(a) <= {'propext', 'Quot.sound', 'Classical.choice'}
               for a in result['certificate_axioms'].values())


def main():
    manifest = check_inputs()
    build = subprocess.run(['lake', 'build', 'TensorRewriteTheory'], cwd=ROOT,
                           text=True, capture_output=True)
    assert build.returncode == 0, build.stdout + build.stderr
    controls = subprocess.run(['lake', 'env', 'lean', 'tests/fixtures/ConvolutionDotControls.lean'],
                              cwd=ROOT, text=True, capture_output=True)
    assert controls.returncode == 0, controls.stdout + controls.stderr
    counts = re.findall(r'^DOT_COUNT case=(\w+) direction=(\w+) count=(\d+)$', controls.stdout, re.M)
    rows = re.findall(r'^DOT case=(\w+) direction=(\w+) index=(\d+) conv=(-?\d+) dot=(-?\d+) '
                      r'row=(\d+) feature=(\d+)$', controls.stdout, re.M)
    assert (counts, rows) == expected(), (counts, rows)
    theory = json.loads((ROOT/'reports/theory-progress.json').read_text())
    for file in theory['files']:
        assert digest(ROOT/file['path']) == file['sha256'], file['path']
    certificates = {n: a for n, a in theory['axiom_dependencies'].items() if '.ConvolutionDot.' in n}
    assert set(certificates) == set(manifest['certificates']) and len(certificates) == 12
    result = dict(status='kernel_checked_pointwise_convolution_as_existing_dot',
                  manifest=MANIFEST, manifest_sha256=digest(ROOT/MANIFEST),
                  scalar_contract='exact_semiring', dot_tensor_bridge_proved=True,
                  both_coordinate_round_trips_proved=True, certificate_axioms=certificates,
                  checked_statement_count=len(certificates), controls_stdout=controls.stdout,
                  semantic_profile_count=11, semantic_direction_count=2,
                  semantic_output_comparisons=len(rows),
                  profile_counts=[dict(name=n, direction=d, count=int(c)) for n, d, c in counts],
                  controls=[dict(name=n, direction=d, index=int(i), convolution=int(c), dot=int(v),
                                 row=int(r), feature=int(o)) for n, d, i, c, v, r, o in rows],
                  full_convolution_family_complete=False, physical_layout_modeled=False,
                  precision_conversions_modeled=False, ieee_accumulation_contract_proved=False,
                  independently_reviewed_statements=False, whole_benchmark_records_closed=0,
                  code_correspondence_performed=False, code_correspondence_future_work=True)
    validate_result(result)
    (ROOT/'reports/convolution-dot.json').write_text(json.dumps(result, indent=2)+'\n')
    print('Convolution/Dot bridge passed: 12 statements, 11 profiles, 220 bidirectional '
          'oracle-agreeing value/index comparisons; exact semiring only.')


if __name__ == '__main__':
    main()
