#!/usr/bin/env python3
"""Inventory frozen custom Lean modules and syntactic import consumers; no proof audit."""
import collections, hashlib, json, pathlib, re, sys
root=pathlib.Path(__file__).resolve().parents[2]
frozen=json.loads((root/'comparisons/tensorright-v1/dependency-costs.json').read_text())['files']
paths={x['path'] for x in frozen}
if len(paths)!=109 or len(frozen)!=109: raise SystemExit('frozen inventory is not 109 unique paths')
imports=re.compile(r'^\s*(?:public\s+)?import\s+([^\n]+)',re.M)
def dependencies(path):
    result=[]
    for line in imports.findall(path.read_text()):
        for name in line.split('--',1)[0].split():
            if name=='TensorRewrite' or name.startswith('TensorRewrite.'):
                result.append(name.replace('.','/')+'.lean')
    return result
maintained=sorted((root/'TensorRewrite').rglob('*.lean'))
packet=sorted((root/'comparisons/tensorright-v1').glob('*.lean'))
consumers=collections.defaultdict(lambda: {'maintained':[],'paper_packet':[]})
for kind, files in [('maintained',maintained),('paper_packet',packet)]:
    for f in files:
        for dep in dependencies(f):
            if dep in paths: consumers[dep][kind].append(str(f.relative_to(root)))
# An intentionally conservative, reproducible first-pass classification. Exact source
# inspection overrides module-name suggestions; 'operation' includes specialized semantics.
generic={'Tensor','Indexing','Permutation','FiniteProduct','FiniteProductLemmas','LinearIndex','LinearIndexLemmas','SliceIndexBounds','LatticeIndex','FiniteSum','ShapeTransport','ShapeTransportLemmas'}
rewrite={'ContractionRules','ReductionRules','DynamicSliceCompositionLemmas','ArithmeticFamily','ArithmeticFamilyProof','LogicalFamily','LogicalFamilyProof','OrderFamily','OrderFamilyProof','ConcatenationAdjacent','ConcatenationGraphLemmas','ConcatenationGraphs','ConcatenationMerge','ConcatenationPad','ConcatenationPadLemmas','ConcatenationProof','ConcatenationSlice','ConvolutionSeparable','ConvolutionSeparableLemmas','ConvolutionSeparableReindex','DynamicUpdateProof','DynamicUpdateStatic','PadWindowProof','RemainderLemmas','SlicePadLemmas'}
rows=[]; bad=[]
for x in sorted(frozen,key=lambda v:v['path']):
    path=x['path']; p=root/path
    if not p.is_file() or hashlib.sha256(p.read_bytes()).hexdigest()!=x['sha256']: bad.append(path)
    stem=p.stem
    if path.startswith('comparisons/'): role='paper_packet_case_or_witness'
    elif stem in generic: role='generic_index_or_algebra_infrastructure_candidate'
    elif stem in rewrite: role='rewrite_family_or_proof_candidate'
    else: role='operation_domain_or_mixed_support_unresolved'
    user=consumers[path]
    src=p.read_text(); intro=re.search(r'/\-!([\s\S]*?)-/',src); description=' '.join(intro.group(1).split()) if intro else ''; declarations=len(re.findall(r'^\s*(?:private |protected |noncomputable |public )*(?:theorem|lemma)\s+',src,re.M))
    rows.append({'path':path,'sha256':x['sha256'],'frozen_code_lines':x['code_lines'],'location':x['category'],'provisional_role':role,'module_documentation':description,'theorem_declaration_count_lexical':declarations,'direct_maintained_consumers':user['maintained'],'direct_paper_packet_consumers':user['paper_packet'],'scope_note':'module-name triage only; actual declarations may mix roles'})
if bad: raise SystemExit('missing or changed frozen inputs: '+repr(bad))
summary={'total':len(rows),'by_location':dict(collections.Counter(x['location'] for x in rows)),'by_provisional_role':dict(collections.Counter(x['provisional_role'] for x in rows)), 'direct_maintained_used':sum(bool(x['direct_maintained_consumers']) for x in rows),'direct_paper_used':sum(bool(x['direct_paper_packet_consumers']) for x in rows),'direct_both':sum(bool(x['direct_maintained_consumers']) and bool(x['direct_paper_packet_consumers']) for x in rows)}
print(json.dumps({'basis_manifest':'comparisons/tensorright-v1/dependency-costs.json','method':'verified frozen file hashes, lexical imports only; zero direct consumers does not imply dead code; classifications provisional','summary':summary,'modules':rows},indent=2))
