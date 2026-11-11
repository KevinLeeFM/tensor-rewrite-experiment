"""Validate raw Pad/window-to-Broadcast composition; no C++ or native correspondence tasks."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
from pad_broadcast_examples import expected

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = 'census/pad-broadcast-v1.json'
ALLOWED = {'propext', 'Quot.sound', 'Classical.choice'}
TRUE_FIELDS = ('raw_coverage_derived', 'retained_edge_cancellation_derived',
               'complete_fused_attribute_equality', 'actual_pad_window_graph',
               'actual_reshape_broadcast_graph', 'derived_shapes_and_axis_maps',
               'converted_fill_equality_required', 'two_sided_identity_required',
               'combined_pad_broadcast_composition_proved')
FALSE_FIELDS = ('associativity_assumed', 'sample_equivalence_postulated',
                'all_window_rewrites_proved', 'full_workload_complete',
                'independently_reviewed_statements', 'benchmark_correspondence_certified',
                'code_correspondence_performed', 'external_ir_admission_proved')


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def check_inputs():
    frozen = json.loads((ROOT / MANIFEST).read_text())
    for row in frozen['files']:
        assert digest(ROOT / row['path']) == row['sha256'], row['path']
    for row in frozen['predecessor_manifests']:
        assert digest(ROOT / row['path']) == row['sha256'], row['path']
    assert digest(ROOT / 'lake-manifest.json') == frozen['lake_manifest_sha256']
    assert frozen['geometry_contract'] == 'raw singleton occupied-offset first/last coverage with unit kernel dilation; retained unit spacing/base/stride/kernel and signed edge cancellation; actual empty-safe fused attributes derived'
    assert frozen['value_contract'] == 'two-sided initializer identities; explicit direct fill equals initializer or actual converted fill equals result initializer; arbitrary pure conversion; original ordered fold'
    assert frozen['sample_equivalence_postulated'] is False
    domains = json.loads((ROOT / frozen['window_domain_worksheet']).read_text())
    prior = domains['supersedes']
    assert digest(ROOT / prior['path']) == prior['sha256']
    old = json.loads((ROOT / prior['path']).read_text())
    assert {r['benchmark_id'] for r in domains['records']} == {r['benchmark_id'] for r in old['records']}
    assert len(domains['records']) == sum(bool(r['core_evidence']) for r in domains['records']) == 31
    assert all(not r['whole_record_closed'] for r in domains['records'])
    return frozen


def parse_controls(raw):
    axes = [dict(profile=int(p), pad_low=int(l), pad_high=int(h), spacing=int(d), kernel=int(k),
                 stride=int(s), base=int(b), low=int(lo), high=int(hi), reversed=r == 'true',
                 outputs=int(o), eligible=e == 'true') for p,l,h,d,k,s,b,lo,hi,r,o,e in re.findall(
        r'^PAD_BROADCAST_AXIS profile=(\d+) pad_low=(\d+) pad_high=(\d+) spacing=(\d+) kernel=(\d+) stride=(\d+) base=(\d+) low=(-?\d+) high=(-?\d+) reversed=(true|false) outputs=(\d+) eligible=(true|false)$', raw, re.M)]
    counts = [dict(profile=int(p), rank=int(r), inputs=int(i), padded=int(d), outputs=int(o),
                   kernels=int(k), axes=json.loads(a)) for p,r,i,d,o,k,a in re.findall(
        r'^PAD_BROADCAST_COUNT profile=(\d+) rank=(\d+) inputs=(\d+) padded=(\d+) outputs=(\d+) kernels=(\d+) axes=(\[[\d, ]*\])$', raw, re.M)]
    rows = [dict(profile=int(p), output=int(o), trace=json.loads(t), shifted_trace=json.loads(h),
                 source=int(s), target=int(v), converted=int(c), converted_target=int(d))
            for p,o,t,h,s,v,c,d in re.findall(
        r'^PAD_BROADCAST profile=(\d+) output=(\d+) trace=(\[[\d, ]*\]) shifted_trace=(\[[\d, ]*\]) source=(\d+) target=(\d+) converted=(\d+) converted_target=(\d+)$', raw, re.M)]
    return axes, counts, rows


def validate_result(result):
    frozen = check_inputs()
    assert result['status'] == 'kernel_checked_raw_pad_window_broadcast_composition'
    assert result['manifest'] == MANIFEST and result['manifest_sha256'] == digest(ROOT / MANIFEST)
    assert result['checked_statement_count'] == len(result['certificate_axioms']) == 13
    assert set(result['certificate_axioms']) == set(frozen['certificates'])
    assert all(set(a) <= ALLOWED for a in result['certificate_axioms'].values())
    assert result['counterexample_certificates'] == frozen['counterexample_certificates']
    assert len(result['counterexample_certificates']) == 3
    groups = expected()
    for key, values in zip(('axis_controls', 'profile_counts', 'controls'), groups):
        assert result[key] == values, key
    assert tuple(map(len, groups)) == (14400, 3785, 1805)
    for key in TRUE_FIELDS: assert result[key] is True, key
    for key in FALSE_FIELDS: assert result[key] is False, key
    assert result['whole_benchmark_records_closed'] == 0
    assert result['mathematical_obligation_denominator'] is None


def main():
    frozen = check_inputs()
    run = subprocess.run(['lake', 'env', 'lean', 'tests/fixtures/PadBroadcastControls.lean'],
                         cwd=ROOT, text=True, capture_output=True)
    assert run.returncode == 0 and 'warning:' not in run.stdout+run.stderr, run.stdout+run.stderr
    axes, counts, rows = parse_controls(run.stdout)
    theory = json.loads((ROOT / 'reports/theory-progress.json').read_text())
    for row in theory['files']: assert digest(ROOT / row['path']) == row['sha256'], row['path']
    axioms = {n:a for n,a in theory['axiom_dependencies'].items() if '.PadBroadcast.' in n}
    domains = json.loads((ROOT / frozen['window_domain_worksheet']).read_text())
    assert {n for r in domains['records'] for n in r['core_evidence']} <= theory['axiom_dependencies'].keys()
    result = dict(status='kernel_checked_raw_pad_window_broadcast_composition',manifest=MANIFEST,
                  manifest_sha256=digest(ROOT / MANIFEST),checked_statement_count=len(axioms),
                  certificate_axioms=axioms,counterexample_certificates=frozen['counterexample_certificates'],
                  axis_controls=axes,profile_counts=counts,controls=rows,control_stdout=run.stdout,
                  whole_benchmark_records_closed=0,mathematical_obligation_denominator=None)
    result.update({key:True for key in TRUE_FIELDS})
    result.update({key:False for key in FALSE_FIELDS})
    validate_result(result)
    (ROOT / 'reports/pad-broadcast.json').write_text(json.dumps(result,indent=2)+'\n')
    print('Pad/window-to-Broadcast composition:13 statements;14400 raw axis configurations;'
          '3785 profiles/1805 outputs agree with materialized-Pad oracle. Full family/workload open.')


if __name__ == '__main__': main()
