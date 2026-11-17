#!/usr/bin/env python3
"""Syntactic transitive reachability from the three maintained Lean root modules."""
import hashlib,json,pathlib,re,sys
root=pathlib.Path(__file__).resolve().parents[2]
items=json.loads((root/'comparisons/library-mixed-role-audit-20261117/frozen-cases.json').read_text())['cases']
pattern=re.compile(r'^\s*(?:public\s+)?import\s+([^\n]+)',re.M)
def imports(p):
    for line in pattern.findall(p.read_text()):
        for name in line.split('--',1)[0].split():
            if name.startswith('TensorRewrite.'):
                q=root/(name.replace('.','/')+'.lean')
                if not q.is_file(): raise SystemExit('missing internal import '+str(q))
                yield q
roots=['TensorRewrite.lean','TensorRewriteTheory.lean','TensorRewriteLibraries.lean']
closures={}
for r in roots:
    seen=set(); stack=[root/r]
    while stack:
        p=stack.pop()
        if p in seen: continue
        seen.add(p);stack.extend(imports(p))
    closures[r]=seen
rows=[]
for item in items:
    path=root/item['path']; digest=hashlib.sha256(path.read_bytes()).hexdigest()
    if digest!=item['sha256']: raise SystemExit('hash mismatch '+item['path'])
    rows.append({'path':item['path'],'sha256':digest,'reachable_root_modules':[name for name,ps in closures.items() if path in ps]})
print(json.dumps({'method':'transitive syntactic internal import closure; reachable does not establish public re-export or proof-term use','roots':roots,'reachable_at_least_one':sum(bool(x['reachable_root_modules']) for x in rows),'rows':rows},indent=2))
