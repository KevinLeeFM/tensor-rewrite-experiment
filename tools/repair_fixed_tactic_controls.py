"""Repair only the invalid-control source generator; preserve all 176 frozen measured attempts."""
from concurrent.futures import ThreadPoolExecutor
import json
from pathlib import Path
import run_fixed_tactics as run

ROOT=run.ROOT
DEST=run.PACKET+'/negative-repair-v2'


def main():
    frozen,targets,policies=run.check_inputs()
    original=run.read(run.PACKET+'/results/summary.json')
    assert len([r for r in original['attempts'] if not r['negative_control']])==176
    assert all(r['status']=='infrastructure_failure' for r in original['attempts'] if r['negative_control'])
    destination=ROOT/DEST
    assert not (destination/'results.json').exists(),'Keep repair results immutable.'
    refutation=run.run(['lake','env','lean',DEST+'/Refutations.lean'])
    (destination/'refutations.log').write_text(refutation['stdout'])
    assert refutation['returncode']==0 and not refutation['timeout'],refutation['stdout']
    for name in ['invalid_nat_refutation','invalid_int_refutation']:run.axioms(refutation['stdout'],name)
    tasks=[]
    for target in [dict(id='invalid_nat',statement='((1 : Nat) + 1 = 3)'),
                   dict(id='invalid_int',statement='(∀ x : Int, x - x = x)')]:
        for policy in policies['policies']:
            text=run.source(target,policy,policies)
            text=text.replace('  unfold '+target['statement']+'\n','')
            path=destination/(target['id']+'__'+policy['id']+'.lean')
            path.write_text(text)
            tasks.append((target,policy,path))
    manifest=dict(status='repair_control_syntax_only_before_rejection_recheck',
        measured_attempts_unchanged=176,policies_and_selected_statements_unchanged=True,
        original_summary_sha256=run.digest(ROOT/(run.PACKET+'/results/summary.json')),
        correction='Do not issue unfold on a raw proposition expression; preserve its exact type and fixed policy.',
        files=[dict(path=str(path.relative_to(ROOT)),sha256=run.digest(path)) for _,_,path in tasks]+[
          dict(path=DEST+'/Refutations.lean',sha256=run.digest(destination/'Refutations.lean')),
          dict(path='tools/repair_fixed_tactic_controls.py',sha256=run.digest(ROOT/'tools/repair_fixed_tactic_controls.py'))])
    (destination/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    def execute(task):
        target,policy,path=task
        result=run.run(['lake','env','lean',str(path.relative_to(ROOT))],45)
        log=path.with_suffix('.log');log.write_text(result['stdout'])
        status=run.classify(result)
        assert status=='fixed_tactic_unsuccessful',(path,status,result['stdout'])
        assert 'FIXED_BASELINE_GUARD absent=835 present=0' in result['stdout']
        return dict(target=target['id'],policy=policy['id'],status=status,
                    source=str(path.relative_to(ROOT)),source_sha256=run.digest(path),
                    log=str(log.relative_to(ROOT)),log_sha256=run.digest(log),
                    **{k:v for k,v in result.items() if k!='stdout'})
    with ThreadPoolExecutor(max_workers=2) as pool:rows=list(pool.map(execute,tasks))
    result=dict(status='all_eight_corrected_false_proposition_controls_rejected',
        manifest_sha256=run.digest(destination/'manifest.json'),controls=rows,
        original_bad_control_trials_preserved=True,measured_attempts_changed=False,
        policies_changed=False,refutation_axioms={name:run.axioms(refutation['stdout'],name)
        for name in ['invalid_nat_refutation','invalid_int_refutation']})
    (destination/'results.json').write_text(json.dumps(result,indent=2)+'\n')
    print('Corrected all eight control sources; all eight well-formed false goals rejected. Measured176 unchanged.')


if __name__=='__main__':main()
