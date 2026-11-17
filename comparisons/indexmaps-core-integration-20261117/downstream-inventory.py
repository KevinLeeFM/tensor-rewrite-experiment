#!/usr/bin/env python3
"""Inventory paper modules whose syntactic local import closure reaches IndexMaps."""
import hashlib,importlib.util,json,pathlib
root=pathlib.Path(__file__).resolve().parents[2];p=root/'comparisons/tensorright-v1/measure_dependencies.py';s=importlib.util.spec_from_file_location('dependency_measure',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);target=root/'TensorRewrite/Pilot/IndexMaps.lean';rows=[]
for f in sorted((root/'comparisons/tensorright-v1').glob('*.lean')):
 c=m.closure(f)
 if target not in c:continue
 external=[]
 for x in sorted(c):
  for line in m.IMPORT.findall(x.read_text()):
   for module in line.split('--',1)[0].split():
    if module.startswith('Mathlib.'):external.append({'importer':str(x.relative_to(root)),'module':module})
 rows.append({'paper_target':str(f.relative_to(root)),'source_sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'local_closure_module_count':len(c),'mathlib_imports':external})
print(json.dumps({'method':'syntactic transitive TensorRewrite imports from paper modules; import reachability is not proof-term use, non-Mathlib external dependencies not classified','total':len(rows),'without_mathlib_imports':sum(not r['mathlib_imports'] for r in rows),'targets':rows},indent=2))
