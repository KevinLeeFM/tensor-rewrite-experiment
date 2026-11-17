#!/usr/bin/env python3
"""Read-only audit of recorded 19-target replay; does not execute Lean or validate caches."""
import collections,hashlib,json,pathlib,re,subprocess
root=pathlib.Path(__file__).resolve().parents[3]; p=root/'comparisons/indexmaps-core-integration-20261117/snork-full-downstream-replay'
sums=json.loads((p/'SHA256SUMS.json').read_text()); bad=[f for f,h in sums.items() if hashlib.sha256((p/f).read_bytes()).hexdigest()!=h];assert not bad,bad
r=json.loads((p/'receipt.json').read_text()); assert r['result']=='passed_all_19_targets_baseline_and_integration';assert r['baseline']=='28b4bf12be2f2252d6422270b0927d5aed631ac6' and r['integration']=='938b193d4fadbd5e3209b775a88823b9d114715e'
targets=r['targets'];inventory=json.loads((root/'comparisons/indexmaps-core-integration-20261117/downstream-inventory.json').read_text());assert len(targets)==len(set(targets))==19 and set(targets)=={x['paper_target'] for x in inventory['targets']}
rows=r['records'];assert len(rows)==150;allowed={'propext','Classical.choice','Quot.sound'};summary={}
for mode,revision in [('baseline',r['baseline']),('integration',r['integration'])]:
 records=[x for x in rows if x['mode']==mode];lookup={x['file']:x for x in records};assert len(lookup)==len(records) and set(targets)<=set(lookup)
 for x in records:
  b=subprocess.check_output(['git','show',revision+':'+x['file']],cwd=root);assert hashlib.sha256(b).hexdigest()==x['source_sha256'],x['file']
  assert x['returncode']==0 and 'sorryAx' not in x['output'] and not re.search(r'(?i)\bwarning\b',x['output']),x['file']
 count=0
 for t in targets:
  o=lookup[t]['output'];matches=re.findall(r"^'[^']+' (?:does not depend on any axioms|depends on axioms: \[)",o,re.M);assert matches,t;count+=len(matches)
  for group in re.findall(r'depends on axioms: \[([^\]]*)\]',o): assert {x.strip() for x in group.split(',') if x.strip()}<=allowed,(t,group)
 summary[mode]={'compiled_modules':len(records),'targets':len(targets),'axiom_reports':count}
base={x['file']:x for x in rows if x['mode']=='baseline'};new={x['file']:x for x in rows if x['mode']=='integration'}
assert all(base[t]['output']==new[t]['output'] for t in targets)
cases=json.loads((root/'comparisons/tensorright-v1/cases.json').read_text())['cases'];assert len(cases)==118
for c in cases:assert hashlib.sha256((root/c['lean_proof_file']).read_bytes()).hexdigest()==c['lean_proof_sha256'],c['id']
print(json.dumps({'result':'receipt_integrity_passed_not_cache_validation','artifact_hashes_checked':len(sums),'records':len(rows),'modes':summary,'target_outputs_identical':True,'paper_proof_hashes_checked':len(cases),'direct_external_artifact_hashes_recorded':len(r['external_direct_artifacts']),'cache_artifacts_locally_verified':False,'package_pin_attestations_in_receipt':False,'prior_reported_seconds':r['seconds']},indent=2))
