"""Check exact/word remainder graphs and a fixed-order floating sum diagnostic; no source processing."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
from remainder_examples import expected

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = 'census/remainder-v1.json'
ALLOWED = {'propext', 'Quot.sound', 'Classical.choice'}
TRUE_FIELDS = ('all_width_word_graphs', 'actual_signed_select_negate_mask',
               'bounded_axis_iota', 'unsigned_offset_no_wrap_required',
               'signed_offset_nonnegative_range_required', 'actual_truncating_word_remainder',
               'zero_divisor_total_model_disclosed', 'uniform_fixed_order_bit_equality_refuted')
FALSE_FIELDS = ('floating_truncating_remainder_formalized', 'uniform_collective_refinement_refuted',
                'collective_communication_model_complete', 'full_family_complete',
                'full_workload_complete', 'independently_reviewed_statements',
                'benchmark_correspondence_certified', 'code_correspondence_performed',
                'external_ir_admission_proved')


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def check_inputs():
    frozen = json.loads((ROOT / MANIFEST).read_text())
    for row in frozen['files']:
        assert digest(ROOT / row['path']) == row['sha256'], row['path']
    assert digest(ROOT / 'lake-manifest.json') == frozen['lake_manifest_sha256']
    assert frozen['operator_contract'] == 'Nat-style unsigned remainder or BitVec.srem truncating signed remainder; exact Int.tmod; total encoded zero-divisor behavior disclosed; actual Select/Negate/And mask and same-width Iota'
    assert frozen['range_contract'] == 'unsigned power exponent<width; signed power exponent+1<width; Iota axis extent<=decoded nonnegative divisor; offset sums strictly below unsigned modulus or nonnegative signed half'
    domains = json.loads((ROOT / frozen['domain_worksheet']).read_text())
    assert digest(ROOT / domains['retained_batch']) == domains['retained_batch_sha256']
    old = json.loads((ROOT / domains['retained_batch']).read_text())['cases']
    assert {r['benchmark_id'] for r in domains['records']} == {r['id'] for r in old}
    assert len(domains['records']) == 17
    assert sum(bool(r['core_evidence']) for r in domains['records']) == 8
    assert domains['source_guards_adopted_as_proof_assumptions'] is False
    assert domains['mathematical_obligation_denominator'] is None
    assert not any(r['whole_record_closed'] for r in domains['records'])
    return frozen


def parse_controls(raw):
    prefixes = ('REM_PAIR', 'REM_INT', 'REM_IOTA_COUNT', 'REM_IOTA', 'REM_UNIFORM')
    groups = []
    for prefix in prefixes:
        rows = []
        for line in raw.splitlines():
            if line.startswith(prefix+' '):
                rows.append({key:json.loads(value) for key,value in
                             re.findall(r'(\w+)=(\[[\d, ]*\]|true|false|-?\d+)', line)})
        groups.append(rows)
    return tuple(groups)


def validate_result(result):
    frozen = check_inputs()
    assert result['status'] == 'kernel_checked_remainder_domains_and_uniform_sum_diagnostic'
    assert result['manifest'] == MANIFEST and result['manifest_sha256'] == digest(ROOT / MANIFEST)
    assert result['new_checked_statement_count'] == len(result['certificate_axioms']) == 28
    assert set(result['certificate_axioms']) == set(frozen['certificates'])
    assert result['counterexample_certificates'] == frozen['counterexample_certificates']
    assert len(result['counterexample_certificates']) == 4
    assert all(set(a) <= ALLOWED for a in result['certificate_axioms'].values())
    assert set(result['reused_axioms']) == set(frozen['reused_certificates'])
    assert all(set(a) <= ALLOWED for a in result['reused_axioms'].values())
    groups = expected()
    for key,rows in zip(('word_controls','integer_controls','iota_counts','iota_controls',
                         'uniform_float_controls'),groups): assert result[key] == rows, key
    assert tuple(map(len,groups)) == (5461,361,2350,2368,30)
    for key in TRUE_FIELDS: assert result[key] is True, key
    for key in FALSE_FIELDS: assert result[key] is False, key
    assert result['whole_benchmark_records_closed'] == 0
    assert result['mathematical_obligation_denominator'] is None


def main():
    frozen = check_inputs()
    run = subprocess.run(['lake','env','lean','tests/fixtures/RemainderControls.lean'],
                         cwd=ROOT,text=True,capture_output=True)
    assert run.returncode == 0 and 'warning:' not in run.stdout+run.stderr, run.stdout+run.stderr
    pairs,integers,counts,rows,floats = parse_controls(run.stdout)
    theory = json.loads((ROOT / 'reports/theory-progress.json').read_text())
    for row in theory['files']: assert digest(ROOT / row['path']) == row['sha256'], row['path']
    axioms = {n:a for n,a in theory['axiom_dependencies'].items()
              if '.Remainder.' in n or '.UniformSum.' in n}
    domains = json.loads((ROOT / frozen['domain_worksheet']).read_text())
    assert {n for r in domains['records'] for n in r['core_evidence']} <= theory['axiom_dependencies'].keys()
    result = dict(status='kernel_checked_remainder_domains_and_uniform_sum_diagnostic',manifest=MANIFEST,
                  manifest_sha256=digest(ROOT / MANIFEST),new_checked_statement_count=len(axioms),
                  certificate_axioms=axioms,counterexample_certificates=frozen['counterexample_certificates'],
                  reused_axioms={n:theory['axiom_dependencies'][n] for n in frozen['reused_certificates']},
                  word_controls=pairs,integer_controls=integers,iota_counts=counts,iota_controls=rows,
                  uniform_float_controls=floats,control_stdout=run.stdout,
                  whole_benchmark_records_closed=0,mathematical_obligation_denominator=None)
    result.update({key:True for key in TRUE_FIELDS})
    result.update({key:False for key in FALSE_FIELDS})
    validate_result(result)
    (ROOT / 'reports/remainder.json').write_text(json.dumps(result,indent=2)+'\n')
    print('28 new statements;5461 exhaustive small word pairs;361 integers;2350 Iota profiles/'
          '2368 outputs;30 binary32 controls agree. Floating remainder, collective contracts/full workload open.')


if __name__ == '__main__': main()
