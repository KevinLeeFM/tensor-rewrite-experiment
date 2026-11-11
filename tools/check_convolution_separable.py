"""Check exact mixed-window product/reduction semantics and retained mathematical partitions."""
from collections import Counter
from itertools import product
import hashlib
import json
from math import prod
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = 'census/convolution-separable-v1.json'
DOMAINS = 'census/convolution-mathematical-domains-v1.json'
PROFILES = [
    dict(name='spanning', shape=(3,), spanning=(True,), reverse=(False,)),
    dict(name='spanning_reversed', shape=(3,), spanning=(True,), reverse=(True,)),
    dict(name='mixed_grouped', shape=(3, 4), spanning=(False, True), reverse=(False, False),
         batch_groups=2, batches=2, feature_groups=2, features=2),
    dict(name='mixed_grouped_reversed', shape=(3, 4), spanning=(False, True), reverse=(False, True),
         batch_groups=2, batches=2, feature_groups=2, features=2),
    dict(name='three_axes', shape=(2, 3, 4), spanning=(False, True, False),
         reverse=(False, True, False), features=2),
    dict(name='all_spanning', shape=(2, 3), spanning=(True, True), reverse=(True, True)),
    dict(name='all_unit', shape=(2, 3), spanning=(False, False), reverse=(True, True)),
    dict(name='rank_zero', shape=(), spanning=(), reverse=()),
    dict(name='empty_kernel', shape=(0,), spanning=(True,), reverse=(False,)),
    dict(name='empty_output', shape=(0,), spanning=(False,), reverse=(False,)),
    dict(name='no_batch_groups', shape=(3,), spanning=(True,), reverse=(False,), batch_groups=0),
]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def expected():
    counts = []; rows = []
    for p in PROFILES:
        shape = p['shape']; rank = len(shape); batches = p.get('batches', 1)
        kernels = tuple(n if mode else 1 for n, mode in zip(shape, p['spanning']))
        output_sizes = tuple(max(0, n-k+1) for n, k in zip(shape, kernels))
        values = []
        for group, batch, feature_group, feature, output in product(
                range(p.get('batch_groups', 1)), range(batches), range(p.get('feature_groups', 1)),
                range(p.get('features', 1)), product(*(range(n) for n in output_sizes))):
            total = 0
            for kernel in product(*(range(n) for n in kernels)):
                spatial = tuple(o+(kmax-1-k if reverse else k)
                                for o, k, kmax, reverse in zip(output, kernel, kernels, p['reverse']))
                assert all(0 <= x < n for x, n in zip(spatial, shape))
                value = (group*batches+batch)*100+feature_group*10+1
                value += sum(x*10**(rank-1-i) for i, x in enumerate(spatial))
                linear = 0
                for extent, coordinate in zip(kernels, kernel):
                    linear = linear*extent+coordinate
                weight = (group+1)*(feature+1)*(linear+1)
                total += value*weight
            values.append(total)
        counts.append((p['name'], str(sum(k != 1 for k in kernels)),
                       str(prod(k for k in kernels if k != 1)), str(len(values))))
        rows.extend((p['name'], str(i), str(v), str(v)) for i, v in enumerate(values))
    return counts, rows


def validate_domains(root=ROOT):
    domains = json.loads((root/DOMAINS).read_text())
    assert domains['status'] == 'mathematical_domain_worksheet_not_a_frozen_obligation_denominator'
    assert domains['mathematical_obligation_denominator'] is None
    assert not domains['independently_reviewed'] and not domains['code_correspondence_performed']
    assert domains['code_correspondence_future_work']
    assert digest(root/domains['retained_batch']) == domains['retained_batch_sha256']
    corpus = json.loads((root/domains['retained_batch']).read_text())['cases']
    records = domains['records']
    assert len(records) == len(corpus) == domains['benchmark_record_count'] == 31
    assert sorted(r['benchmark_id'] for r in records) == sorted(r['id'] for r in corpus)
    assert all(not r['whole_benchmark_record_closed'] and r['remaining_mathematical_partitions']
               for r in records)
    assert Counter(r['kind'] for r in records)['composition_reference'] == 7
    variants = [r for r in records if r['kind'] == 'mixed_window_multiply_reduce']
    assert len(variants) == 12
    assert sum(r['partition_flags']['input_conversion'] or r['partition_flags']['kernel_conversion']
               for r in variants) == 9
    assert all(not r['existing_or_current_exact_model_evidence']
               for r in variants if r['partition_flags']['input_conversion']
               or r['partition_flags']['kernel_conversion'])
    return domains


def check_inputs(root=ROOT):
    manifest = json.loads((root/MANIFEST).read_text())
    for file in manifest['files']:
        assert digest(root/file['path']) == file['sha256'], file['path']
    for key in ('base_model_manifest', 'channel_model_manifest'):
        path = manifest[key]
        assert digest(root/path) == manifest[key+'_sha256']
        predecessor = json.loads((root/path).read_text())
        for file in predecessor.get('files', predecessor.get('model_files', [])):
            assert digest(root/file['path']) == file['sha256'], file['path']
    validate_domains(root)
    return manifest


def validate_result(result):
    assert result['status'] == 'kernel_checked_mixed_window_product_reduction'
    assert result['scalar_contract'] == 'exact_semiring_single_input_channel'
    assert result['nonunit_axes_only'] and result['kernel_reversal_reindexed']
    for key in ('full_convolution_family_complete', 'precision_conversions_modeled',
                'ieee_accumulation_contract_proved', 'physical_layout_modeled',
                'independently_reviewed_statements', 'code_correspondence_performed'):
        assert result[key] is False, key
    assert result['whole_benchmark_records_closed'] == 0
    assert result['code_correspondence_future_work']
    counts, rows = expected()
    assert result['profile_counts'] == [dict(name=n, axes=int(a), domain=int(d), outputs=int(o))
                                         for n, a, d, o in counts]
    assert result['controls'] == [dict(name=n, index=int(i), convolution=int(c), product=int(p))
                                   for n, i, c, p in rows]
    assert result['semantic_profile_count'] == 11
    assert result['semantic_output_count'] == len(rows)
    assert result['checked_statement_count'] == len(result['certificate_axioms']) == 11
    assert all(set(a) <= {'propext', 'Quot.sound', 'Classical.choice'}
               for a in result['certificate_axioms'].values())


def main():
    manifest = check_inputs()
    build = subprocess.run(['lake', 'build', 'TensorRewriteTheory'], cwd=ROOT,
                           text=True, capture_output=True)
    assert build.returncode == 0, build.stdout + build.stderr
    run = subprocess.run(['lake', 'env', 'lean', 'tests/fixtures/ConvolutionSeparableControls.lean'],
                         cwd=ROOT, text=True, capture_output=True)
    assert run.returncode == 0, run.stdout + run.stderr
    counts = re.findall(r'^SEP_COUNT case=(\w+) axes=(\d+) domain=(\d+) outputs=(\d+)$',run.stdout,re.M)
    rows = re.findall(r'^SEP case=(\w+) index=(\d+) conv=(-?\d+) product=(-?\d+)$',run.stdout,re.M)
    assert (counts, rows) == expected(), (counts, rows)
    theory = json.loads((ROOT/'reports/theory-progress.json').read_text())
    for file in theory['files']:
        assert digest(ROOT/file['path']) == file['sha256'], file['path']
    certificates = {n:a for n,a in theory['axiom_dependencies'].items() if '.ConvolutionSeparable.' in n}
    assert set(certificates) == set(manifest['certificates']) and len(certificates) == 11
    result = dict(status='kernel_checked_mixed_window_product_reduction',
                  manifest=MANIFEST, manifest_sha256=digest(ROOT/MANIFEST),
                  scalar_contract='exact_semiring_single_input_channel',
                  nonunit_axes_only=True, kernel_reversal_reindexed=True,
                  checked_statement_count=11, certificate_axioms=certificates,
                  semantic_profile_count=11, semantic_output_count=len(rows),controls_stdout=run.stdout,
                  profile_counts=[dict(name=n,axes=int(a),domain=int(d),outputs=int(o)) for n,a,d,o in counts],
                  controls=[dict(name=n,index=int(i),convolution=int(c),product=int(p)) for n,i,c,p in rows],
                  full_convolution_family_complete=False,precision_conversions_modeled=False,
                  ieee_accumulation_contract_proved=False,physical_layout_modeled=False,
                  independently_reviewed_statements=False,whole_benchmark_records_closed=0,
                  code_correspondence_performed=False,code_correspondence_future_work=True)
    validate_result(result)
    (ROOT/'reports/convolution-separable.json').write_text(json.dumps(result,indent=2)+'\n')
    print(f'Mixed-window reduction passed:11 statements,11 profiles,{len(rows)} oracle-agreeing outputs; '
          'all31 convolution records retained in a non-final domain worksheet.')


if __name__ == '__main__':
    main()
