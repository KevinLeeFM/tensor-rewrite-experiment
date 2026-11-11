"""Replay one frozen fixed-tactic comparison; every proof attempt gets a fresh Lean process."""
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import time

ROOT=Path(__file__).resolve().parents[1]
PACKET='comparisons/fixed-tactics-v1'
MANIFEST=PACKET+'/manifest.json'
ALLOWED={'propext','Quot.sound','Classical.choice'}
CANDIDATE='FixedTacticTrial.candidate'


def read(path):return json.loads((ROOT/path).read_text())
def digest(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def check_inputs():
    frozen=read(MANIFEST)
    for row in frozen['files']:assert digest(ROOT/row['path'])==row['sha256'],row['path']
    assert digest(ROOT/'lake-manifest.json')==frozen['lake_manifest_sha256']
    assert frozen['measured_targets']==44 and frozen['reviewed_foundation_targets']==89
    assert frozen['target_population']=='reviewed statements, definitions-only restatement subset'
    assert frozen['agent_arm']=='historical solution-informed proof replay; no blinded discovery claim'
    assert len(read(PACKET+'/forbidden.json'))==835
    targets=read(PACKET+'/targets.json')['targets'];policies=read(PACKET+'/policies.json')
    assert len(targets)==44 and len({r['original'] for r in targets})==44
    assert len(read(PACKET+'/targets.json')['exclusions'])==45
    assert [p['id'] for p in policies['policies']]==['rfl','simp','funext_simp','aesop']
    assert policies['heartbeats']==400000 and policies['max_rec_depth']==4096
    assert policies['per_process_timeout_seconds']==45 and policies['parallel_processes']==2
    return frozen,targets,policies


def run(command,timeout=45):
    begin=time.monotonic()
    process=subprocess.Popen(command,cwd=ROOT,text=True,stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT,start_new_session=True)
    timeout_hit=False
    try:stdout,_=process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        timeout_hit=True;os.killpg(process.pid,signal.SIGKILL);stdout,_=process.communicate()
    return dict(command=command,returncode=process.returncode,stdout=stdout,
                timeout=timeout_hit,elapsed_seconds=round(time.monotonic()-begin,4))


def axioms(stdout,name):
    match=re.search(re.escape(name)+r"' depends on axioms: \[([^\]]*)\]",stdout)
    if match:values=sorted(x.strip() for x in match[1].split(',') if x.strip())
    else:
        assert name+"' does not depend on any axioms" in stdout,name
        values=[]
    assert set(values)<=ALLOWED,(name,values)
    return values


def classify(result):
    output=result['stdout']
    if result['timeout']:return 'configured_wall_budget_exhausted'
    if result['returncode']<0 or 'PANIC' in output:return 'infrastructure_failure'
    if result['returncode']==0:
        assert 'FIXED_BASELINE_GUARD absent=835 present=0' in output
        axioms(output,CANDIDATE)
        return 'kernel_checked'
    assert re.search(r'error(?:\(|:)',output),output[-3000:]
    if any(token in output for token in ('FIXED_BASELINE_LEAK','object file','unknown module',
                                        'Unknown identifier','unexpected token','SIGNATURE_MISMATCH')):
        return 'infrastructure_failure'
    if any(token in output for token in ('maximum number of heartbeats','maximum recursion depth',
                                        'deterministic timeout','maxRuleApplications')):
        return 'configured_search_budget_exhausted'
    return 'fixed_tactic_unsuccessful'


def source(target,policy,policies):
    return ('import TensorRewrite.Comparisons.FixedTacticsGuard\n\n'
            'set_option maxHeartbeats '+str(policies['heartbeats'])+'\n'
            'set_option maxRecDepth '+str(policies['max_rec_depth'])+'\n'
            '-- The same uniform list intentionally contains unused definitions for some goals.\n'
            'set_option linter.unusedSimpArgs false\n\n'
            'run_cmd TensorRewrite.Comparisons.FixedTactics.noCampaignProofs\n\n'
            'namespace FixedTacticTrial\n\n'
            '/-- One frozen-policy attempt at the unchanged reviewed proposition. -/\n'
            'theorem candidate : '+target['statement']+' := by\n'
            '  unfold '+target['statement']+'\n  intros\n  '+policy['script']+'\n\n'
            'end FixedTacticTrial\n\n#print axioms '+CANDIDATE+'\n')


def main():
    frozen,targets,policies=check_inputs()
    destination=ROOT/(PACKET+'/results')
    assert not destination.exists(),'Preserve the first run; use a separately versioned replay directory.'
    destination.mkdir()
    preflight=[]
    jobs=[('build',['lake','build','TensorRewrite.Comparisons.FixedTacticsGuard'],0,None),
          ('basis',['lake','env','lean',PACKET+'/BasisAudit.lean'],0,'absent=835 present=0'),
          ('signatures',['lake','env','lean',PACKET+'/SignatureAudit.lean'],0,'exact=44'),
          ('agent',['lake','env','lean',PACKET+'/AgentReplay.lean'],0,'exact=44'),
          ('policy_smoke',['lake','env','lean',PACKET+'/PolicySmoke.lean'],0,'absent=835 present=0'),
          ('leak_negative',['lake','env','lean',PACKET+'/LeakNegativeControl.lean'],1,'FIXED_BASELINE_LEAK'),
          ('signature_negative',['lake','env','lean',PACKET+'/SignatureNegativeControl.lean'],1,'FIXED_BASELINE_SIGNATURE_MISMATCH')]
    for identifier,command,code,token in jobs:
        result=run(command,120 if identifier=='build' else 45)
        (destination/(identifier+'.log')).write_text(result['stdout'])
        preflight.append(dict(id=identifier,**{k:v for k,v in result.items() if k!='stdout'}))
        (destination/'preflight.json').write_text(json.dumps(preflight,indent=2)+'\n')
        assert not result['timeout'] and result['returncode']==code,(identifier,result['stdout'][-4000:])
        if token:assert token in result['stdout'],identifier
        if identifier=='agent':
            for target in targets:axioms(result['stdout'],target['original'])
    tasks=[(target,policy,False) for target in targets for policy in policies['policies']]
    negatives=[dict(id='invalid_nat',statement='((1 : Nat) + 1 = 3)'),
               dict(id='invalid_int',statement='(∀ x : Int, x - x = x)')]
    tasks += [(target,policy,True) for target in negatives for policy in policies['policies']]
    def attempt(task):
        target,policy,negative=task
        identity=target['id']+'__'+policy['id']
        path=destination/(identity+'.lean');path.write_text(source(target,policy,policies))
        relative=str(path.relative_to(ROOT))
        result=run(['lake','env','lean',relative],policies['per_process_timeout_seconds'])
        (destination/(identity+'.log')).write_text(result['stdout'])
        status=classify(result)
        if negative:assert status!='kernel_checked','Invalid proposition accepted: '+identity
        return dict(target=target['id'],original=target.get('original'),policy=policy['id'],
                    negative_control=negative,status=status,
                    axioms=axioms(result['stdout'],CANDIDATE) if status=='kernel_checked' else None,
                    source=relative,source_sha256=digest(path),
                    log=str((destination/(identity+'.log')).relative_to(ROOT)),
                    log_sha256=digest(destination/(identity+'.log')),
                    **{k:v for k,v in result.items() if k!='stdout'})
    outcomes=[]
    with ThreadPoolExecutor(max_workers=policies['parallel_processes']) as pool:
        for row in pool.map(attempt,tasks):
            outcomes.append(row)
            (destination/'attempts.json').write_text(json.dumps(outcomes,indent=2)+'\n')
            if len(outcomes)%16==0:print('Completed',len(outcomes),'/',len(tasks),'fixed attempts',flush=True)
    accepted=[r for r in outcomes if not r['negative_control'] and r['status']=='kernel_checked']
    counts={p['id']:sum(r['policy']==p['id'] for r in accepted) for p in policies['policies']}
    result=dict(status='completed_fixed_tactic_subset_comparison',manifest=MANIFEST,
        manifest_sha256=digest(ROOT/MANIFEST),selected_targets=44,excluded_reviewed_targets=45,
        target_policy_attempts=176,negative_tactic_controls=8,agent_replay_targets=44,
        accepted_by_policy=counts,union_accepted_targets=len({r['target'] for r in accepted}),
        outcome_counts=dict(Counter(r['status'] for r in outcomes)),attempts=outcomes,preflight=preflight,
        historical_solution_informed_agent_replay=True,fresh_blinded_agent_comparison=False,
        whole_workload_compared=False,independent_comparison_review=False,code_correspondence_performed=False)
    (destination/'summary.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps({k:result[k] for k in ['accepted_by_policy','union_accepted_targets','outcome_counts']},indent=2))


if __name__=='__main__':main()
