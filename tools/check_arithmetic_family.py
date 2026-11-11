"""Check closed exact-ring profiles, actual Broadcast corollaries and separate IEEE refutations."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
from arithmetic_examples import expected, labels, DOMAINS
from ordered_float_examples import add, multiply

ROOT=Path(__file__).resolve().parents[1]
MANIFEST='census/arithmetic-values-family-v1.json'
TRUE_FIELDS=('all_rule_orders_enumerated','complete_duplicate_free_family',
             'integer_real_complex_and_all_width_word_instances','arbitrary_finite_tensor_shapes',
             'actual_bounded_broadcast_graphs','concrete_ieee_counterexamples_checked')
FALSE_FIELDS=('ieee_commutative_ring_assumed','all_ieee_arithmetic_profiles_complete',
              'effects_or_layout_preservation_proved','full_workload_complete',
              'independently_reviewed_statements','benchmark_correspondence_certified',
              'code_correspondence_performed')
ALLOWED={'propext','Quot.sound','Classical.choice'}


def digest(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def profile_units():
    return [dict(id=domain+'/'+r['key'],domain=domain,rule=r['key'],side_condition='True',
      candidate_benchmark_labels=labels(r['key']),label_correspondence_certified=False)
      for r in expected()[0] for domain in DOMAINS]


def check_inputs():
    frozen=json.loads((ROOT/MANIFEST).read_text())
    for row in frozen['files']:assert digest(ROOT/row['path'])==row['sha256'],row['path']
    assert digest(ROOT/'lake-manifest.json')==frozen['lake_manifest_sha256']
    assert frozen['family']=='typed_commutative_ring_values_v1'
    assert frozen['profile_units']==profile_units()
    assert frozen['profile_unit_count']==172 and frozen['rule_order_instance_count']==43
    assert frozen['mathematical_family_denominator_frozen'] is True
    assert frozen['full_mathematical_workload_denominator_frozen'] is False
    worksheet=json.loads((ROOT/frozen['domain_worksheet']).read_text())
    assert len(worksheet['records'])==34
    for batch in worksheet['retained_batches']:assert digest(ROOT/batch['path'])==batch['sha256']
    assert worksheet['source_guards_adopted_as_proof_assumptions'] is False
    assert not any(r['whole_record_closed'] for r in worksheet['records'])
    catalog=json.loads((ROOT/frozen['worksheet_catalog']).read_text());old=catalog['supersedes']
    assert digest(ROOT/old['path'])==old['sha256']
    prior=json.loads((ROOT/old['path']).read_text())
    assert catalog['worksheets']==prior['worksheets']+[dict(path=frozen['domain_worksheet'],
      sha256=digest(ROOT/frozen['domain_worksheet']),retained_record_count=34)]
    return frozen


def parse_controls(raw):
    groups=[[] for _ in range(6)]
    for line in raw.splitlines():
        if line.startswith('ARITH_TREE '):
            match=re.fullmatch(r'ARITH_TREE key=(\w+) lhs=(.*?) \| rhs=(.*)',line);assert match
            groups[0].append(dict(key=match[1],lhs=match[2],rhs=match[3]));continue
        if not line.startswith('ARITH_'):continue
        row={k:(v if k in ('domain','key') else json.loads(v)) for k,v in
             re.findall(r'(\w+)=(\[[\d, -]*\]|true|false|-?\d+|[\w_]+)',line)}
        for index,prefix in enumerate(('ARITH_PROFILE ','ARITH_VALUE ','ARITH_GRAPH_COUNT ',
                                       'ARITH_GRAPH ','ARITH_FLOAT '),1):
            if line.startswith(prefix):groups[index].append(row);break
    return tuple(groups)


def validate_result(result):
    frozen=check_inputs()
    assert result['status']=='kernel_complete_declared_mathematical_value_family'
    assert result['manifest']==MANIFEST and result['manifest_sha256']==digest(ROOT/MANIFEST)
    assert result['profile_units']==profile_units() and result['profile_unit_count']==172
    axioms=result['certificate_axioms']
    assert result['checked_statement_count']==len(axioms)==19
    assert set(axioms)==set(frozen['certificates'])
    assert all(set(a)<=ALLOWED for a in axioms.values())
    assert result['counterexample_certificates']==frozen['counterexample_certificates']
    for key,rows in zip(('expression_trees','profile_controls','value_controls','graph_counts','graph_controls'),expected()):
        assert result[key]==rows,key
    assert tuple(map(len,expected()))==(43,172,28638,10,480)
    a,b,c=0x4b800000,0x3f800000,0xcb800000
    x,y,z=1,0x3f000000,0x40000000
    assert result['float_controls'][:2]==[
      dict(key='add_assoc_00',lhs=add(add(a,b),c),rhs=add(a,add(b,c))),
      dict(key='mul_assoc_00',lhs=multiply(multiply(x,y),z),rhs=multiply(x,multiply(y,z)))]
    nan=result['float_controls'][2]
    assert nan['key']=='mul_zero_right' and nan['rhs']==0
    assert nan['lhs']&0x7f800000==0x7f800000 and nan['lhs']&0x7fffff!=0
    assert result['negative_float_ring']['exit_code']!=0
    assert 'CommRing' in result['negative_float_ring']['output']
    for key in TRUE_FIELDS:assert result[key] is True,key
    for key in FALSE_FIELDS:assert result[key] is False,key
    assert result['whole_benchmark_records_closed']==0
    assert result['mathematical_obligation_denominator'] is None


def main():
    frozen=check_inputs()
    run=subprocess.run(['lake','env','lean','tests/fixtures/ArithmeticFamilyControls.lean'],cwd=ROOT,
                       text=True,capture_output=True)
    assert run.returncode==0 and 'warning:' not in run.stdout+run.stderr,run.stdout+run.stderr
    controls=parse_controls(run.stdout)
    negative=subprocess.run(['lake','env','lean','tests/fixtures/InvalidArithmeticFloatRing.lean'],
                            cwd=ROOT,text=True,capture_output=True)
    assert negative.returncode!=0 and 'error:' in negative.stdout,negative.stdout+negative.stderr
    theory=json.loads((ROOT/'reports/theory-progress.json').read_text())
    for row in theory['files']:assert digest(ROOT/row['path'])==row['sha256']
    axioms={n:a for n,a in theory['axiom_dependencies'].items() if '.ArithmeticFamily.' in n}
    result=dict(status='kernel_complete_declared_mathematical_value_family',manifest=MANIFEST,
      manifest_sha256=digest(ROOT/MANIFEST),profile_units=profile_units(),profile_unit_count=172,
      covered_candidate_benchmark_labels=sorted({x for r in profile_units() for x in r['candidate_benchmark_labels']}),
      certificate_axioms=axioms,checked_statement_count=len(axioms),
      counterexample_certificates=frozen['counterexample_certificates'],
      whole_benchmark_records_closed=0,mathematical_obligation_denominator=None,
      negative_float_ring=dict(exit_code=negative.returncode,output=negative.stdout+negative.stderr),
      code_correspondence_future_work=True,independent_statement_review='pending',
      observations='exact commutative-ring pure tensor values; actual shared-axis Broadcast corollaries; IEEE/effects/layout partitions remain separate',
      control_stdout=run.stdout)
    result.update(dict(zip(('expression_trees','profile_controls','value_controls','graph_counts','graph_controls','float_controls'),controls)))
    result.update({key:True for key in TRUE_FIELDS});result.update({key:False for key in FALSE_FIELDS})
    validate_result(result)
    (ROOT/'reports/arithmetic-values-family.json').write_text(json.dumps(result,indent=2)+'\n')
    print('43 exact arithmetic rule/order instances across4 concrete tracks:172 complete declared '
          'profiles;28638 scalar and480 Broadcast controls agree;3 IEEE refutations and no Float ring instance;full campaign open.')


if __name__=='__main__':main()
