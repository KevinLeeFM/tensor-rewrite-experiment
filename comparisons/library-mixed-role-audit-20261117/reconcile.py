#!/usr/bin/env python3
"""Reconcile reviewer rows with frozen bytes and syntactic consumer inventory; not a proof audit."""
import collections,hashlib,json,pathlib,sys
root=pathlib.Path(__file__).resolve().parents[2]; here=pathlib.Path(__file__).resolve().parent
load=lambda p:json.loads(p.read_text())
frozen=load(here/'frozen-cases.json'); base=root/'comparisons/library-closure-audit-20261117/inventory.json'
if hashlib.sha256(base.read_bytes()).hexdigest()!=frozen['basis_inventory_sha256']: raise SystemExit('prior inventory hash mismatch')
expected={x['path']:x['sha256'] for x in frozen['cases']}
if len(expected)!=42 or len(frozen['cases'])!=42: raise SystemExit('frozen path count mismatch')
rows=load(here/'pilot-review.json')+load(here/'theory-review.json'); paths=[x['path'] for x in rows]
if len(rows)!=42 or len(set(paths))!=42 or set(paths)!=set(expected): raise SystemExit('review coverage mismatch')
prior={x['path']:x for x in load(base)['modules']}; reach={x['path']:x for x in load(here/'reachability.json')['rows']}
allowed={'semantic model','generic or operation-specific helper','generic/operation-specific helper','rewrite-specific proof','mixed','unresolved'}
for row in rows:
 p=row['path']; f=root/p
 if hashlib.sha256(f.read_bytes()).hexdigest()!=expected[p]: raise SystemExit('source hash mismatch: '+p)
 if row.get('role') not in allowed: raise SystemExit('unknown role: '+str(row.get('role')))
 for field in ['summary','evidence','dependencies_and_assumptions','consumer','inspection_limit']:
  if not isinstance(row.get(field),str) or not row[field].strip(): raise SystemExit('missing '+field+': '+p)
 row['sha256']=expected[p];row['reachable_root_modules']=reach[p]['reachable_root_modules'];row['direct_maintained_consumers']=prior[p]['direct_maintained_consumers'];row['direct_paper_consumers']=prior[p]['direct_paper_packet_consumers']
rows.sort(key=lambda x:x['path'])
print(json.dumps({'method':'hash, field and case-set reconciliation; descriptions are independent reviewer judgments and not mechanically proven','basis_inventory_sha256':frozen['basis_inventory_sha256'],'assigned':len(expected),'review_rows':len(rows),'unresolved':[x['path'] for x in rows if x['role']=='unresolved'],'roles':dict(collections.Counter(x['role'].replace('generic/operation-specific helper','generic or operation-specific helper') for x in rows)),'rows':rows},indent=2))
