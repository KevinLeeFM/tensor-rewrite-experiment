"""Check covered singleton-window broadcasts and a closed singleton-tuple value family."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
from broadcast_window_examples import expected

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = 'census/broadcast-window-v1.json'
FAMILY = 'census/window-tuple-family-v1.json'
ALLOWED = {'propext', 'Quot.sound', 'Classical.choice'}
TRUE_FIELDS = ('coverage_from_attributes', 'exactly_one_live_contribution',
               'two_sided_identity_required', 'actual_reshape_broadcast_graph',
               'derived_compact_shape_and_ordered_axes', 'state_initial_padding_transport',
               'binary32_tuple_stored_bits', 'existing_operand_broadcast_core')
FALSE_FIELDS = ('associativity_assumed', 'combined_pad_broadcast_composition_proved',
                'all_window_rewrites_proved', 'full_workload_complete',
                'independently_reviewed_statements', 'benchmark_correspondence_certified',
                'code_correspondence_performed', 'external_ir_admission_proved')


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def family_inputs():
    frozen = json.loads((ROOT / FAMILY).read_text())
    for row in frozen['model_files']:
        assert digest(ROOT / row['path']) == row['sha256'], row['path']
    assert digest(ROOT / 'lake-manifest.json') == frozen['lake_manifest_sha256']
    assert frozen['profile_unit_count'] == len(frozen['profile_units']) == 1
    profile = frozen['profile_units'][0]
    assert profile['rule'] == 'singleton' and profile['tuple_arity'] == 1
    assert profile['domain'] == 'all_pure_value_types' and profile['side_condition'] == 'True'
    assert profile['observation'] == 'tuple_of_tensor_values'
    assert profile['source_input_count'] == profile['target_output_tuple_count'] == 1
    return frozen


def check_inputs():
    family_inputs()
    manifest = json.loads((ROOT / MANIFEST).read_text())
    for row in manifest['files']:
        assert digest(ROOT / row['path']) == row['sha256'], row['path']
    assert digest(ROOT / 'lake-manifest.json') == manifest['lake_manifest_sha256']
    assert manifest['geometry_contract'] == 'singleton expansions: kernel dilation1, arbitrary positive stride/base dilation and reversal, signed padding; explicit first/last covering inequalities or empty output; other axes pointwise'
    assert manifest['reducer_contract'] == 'two-sided identity initializer, also actual padding; no associativity assumption'
    assert manifest['shape_or_sample_equivalence_postulated'] is False
    domains = json.loads((ROOT / manifest['window_domain_worksheet']).read_text())
    previous = domains['supersedes']
    assert digest(ROOT / previous['path']) == previous['sha256']
    old = json.loads((ROOT / previous['path']).read_text())
    assert {r['benchmark_id'] for r in domains['records']} == {r['benchmark_id'] for r in old['records']}
    assert len(domains['records']) == 31
    assert sum(bool(r['core_evidence']) for r in domains['records']) == 29
    assert all(not r['whole_record_closed'] for r in domains['records'])
    return manifest


def parse_controls(raw):
    axes = [dict(profile=int(p), kernel=int(k), stride=int(s), base=int(b), low=int(l), high=int(h),
                 reversed=r == 'true', outputs=int(o), eligible=e == 'true') for p,k,s,b,l,h,r,o,e in
            re.findall(r'^BROADCAST_AXIS profile=(\d+) kernel=(\d+) stride=(\d+) base=(\d+) low=(-?\d+) high=(-?\d+) reversed=(true|false) outputs=(\d+) eligible=(true|false)$', raw, re.M)]
    counts = [dict(profile=int(p), rank=int(r), inputs=int(i), outputs=int(o), kernels=int(k),
                   compact_rank=int(c), axes=json.loads(a)) for p,r,i,o,k,c,a in
              re.findall(r'^BROADCAST_COUNT profile=(\d+) rank=(\d+) inputs=(\d+) outputs=(\d+) kernels=(\d+) compact_rank=(\d+) axes=(\[[\d, ]*\])$', raw, re.M)]
    rows = [dict(profile=int(p), output=int(o), trace=json.loads(t), live=int(l), source=int(s),
                 target=int(v), bool_source=b == 'true', bool_target=c == 'true') for p,o,t,l,s,v,b,c in
            re.findall(r'^BROADCAST profile=(\d+) output=(\d+) trace=(\[[\d, ]*\]) live=(\d+) source=(\d+) target=(\d+) bool_source=(true|false) bool_target=(true|false)$', raw, re.M)]
    tuple_counts = [dict(name=n, outputs=int(o)) for n,o in
                    re.findall(r'^TUPLE_COUNT name=(\w+) outputs=(\d+)$', raw, re.M)]
    tuples = [dict(name=n, output=int(o), source=int(s), target=int(t), scalar=int(c), shifted=int(h))
              for n,o,s,t,c,h in re.findall(r'^TUPLE name=(\w+) output=(\d+) source=(-?\d+) target=(-?\d+) scalar=(-?\d+) shifted=(-?\d+)$', raw, re.M)]
    floats = [dict(name=n, source=int(s), target=int(t)) for n,s,t in
              re.findall(r'^TUPLE_F32 name=(\w+) source=(\d+) target=(\d+)$', raw, re.M)]
    rules = re.findall(r'^TUPLE_RULE (\w+)$', raw, re.M)
    return axes, counts, rows, tuple_counts, tuples, floats, rules


def validate_family_result(result):
    frozen = family_inputs()
    assert result['manifest'] == FAMILY and result['manifest_sha256'] == digest(ROOT / FAMILY)
    assert result['status'] == 'kernel_complete_declared_mathematical_value_family'
    assert result['profile_unit_count'] == 1 and result['profile_units'] == frozen['profile_units']
    assert result['enumerated_rules'] == ['singleton']
    assert set(result['certificate_axioms']) == set(frozen['certificates'])
    assert all(set(a) <= ALLOWED for a in result['certificate_axioms'].values())
    assert result['covered_candidate_benchmark_labels'] == ['HandleReduceWindow/singleton-tuple']
    assert result['code_correspondence_performed'] is False
    assert result['code_correspondence_future_work'] is True
    assert result['whole_benchmark_records_closed'] == 0
    assert result['observations'] == frozen['observations']
    assert result['independent_statement_review'] == 'pending'


def validate_result(result):
    manifest = check_inputs()
    assert result['status'] == 'kernel_checked_covered_singleton_broadcast_and_state_transport'
    assert result['manifest'] == MANIFEST and result['manifest_sha256'] == digest(ROOT / MANIFEST)
    assert result['checked_statement_count'] == len(result['certificate_axioms']) == 36
    assert set(result['certificate_axioms']) == set(manifest['certificates'])
    assert result['counterexample_certificates'] == manifest['counterexample_certificates']
    assert len(result['counterexample_certificates']) == 3
    assert all(set(a) <= ALLOWED for a in result['certificate_axioms'].values())
    groups = expected()
    for key, rows in zip(('axis_controls', 'profile_counts', 'controls', 'tuple_counts',
                          'tuple_controls', 'float_controls'), groups):
        assert result[key] == rows, key
    assert tuple(map(len, groups)) == (3780, 1277, 440, 5, 10, 8)
    assert result['enumerated_rules'] == ['singleton']
    for key in TRUE_FIELDS:
        assert result[key] is True, key
    for key in FALSE_FIELDS:
        assert result[key] is False, key
    assert result['whole_benchmark_records_closed'] == 0
    assert result['mathematical_obligation_denominator'] is None


def main():
    manifest = check_inputs()
    run = subprocess.run(['lake', 'env', 'lean', 'tests/fixtures/BroadcastWindowControls.lean'],
                         cwd=ROOT, text=True, capture_output=True)
    assert run.returncode == 0 and 'warning:' not in run.stdout+run.stderr, run.stdout+run.stderr
    axes, counts, rows, tuple_counts, tuples, floats, rules = parse_controls(run.stdout)
    theory = json.loads((ROOT / 'reports/theory-progress.json').read_text())
    for row in theory['files']:
        assert digest(ROOT / row['path']) == row['sha256']
    axioms = {n:a for n,a in theory['axiom_dependencies'].items() if any(
        group in n for group in ('.BroadcastWindow.', '.WindowTransport.', '.WindowTupleFamily.',
                                 '.WindowTupleFloat.'))}
    domains = json.loads((ROOT / manifest['window_domain_worksheet']).read_text())
    assert {n for r in domains['records'] for n in r['core_evidence']} <= theory['axiom_dependencies'].keys()
    result = dict(status='kernel_checked_covered_singleton_broadcast_and_state_transport',
                  manifest=MANIFEST, manifest_sha256=digest(ROOT / MANIFEST), certificate_axioms=axioms,
                  checked_statement_count=len(axioms), counterexample_certificates=manifest['counterexample_certificates'],
                  axis_controls=axes, profile_counts=counts, controls=rows, tuple_counts=tuple_counts,
                  tuple_controls=tuples, float_controls=floats, enumerated_rules=rules,
                  control_stdout=run.stdout, whole_benchmark_records_closed=0,
                  mathematical_obligation_denominator=None)
    result.update({key:True for key in TRUE_FIELDS})
    result.update({key:False for key in FALSE_FIELDS})
    validate_result(result)
    frozen = family_inputs()
    family = dict(status='kernel_complete_declared_mathematical_value_family',manifest=FAMILY,
                  manifest_sha256=digest(ROOT / FAMILY),profile_unit_count=1,profile_units=frozen['profile_units'],
                  enumerated_rules=rules,observations=frozen['observations'],
                  certificate_axioms={n:a for n,a in axioms.items() if '.WindowTupleFamily.' in n},
                  covered_candidate_benchmark_labels=['HandleReduceWindow/singleton-tuple'],
                  code_correspondence_performed=False,code_correspondence_future_work=True,
                  whole_benchmark_records_closed=0,independent_statement_review='pending')
    validate_family_result(family)
    (ROOT / 'reports/broadcast-window.json').write_text(json.dumps(result,indent=2)+'\n')
    (ROOT / 'reports/window-tuple-family.json').write_text(json.dumps(family,indent=2)+'\n')
    print('Covered singleton windows:36 statements;3780 axis controls;1277 profiles/440 outputs; '
          '10 tuple and8 finite binary32 outputs agree. One declared tuple value profile complete; '
          'Pad-combined branches/full workload remain open.')


if __name__ == '__main__':
    main()
