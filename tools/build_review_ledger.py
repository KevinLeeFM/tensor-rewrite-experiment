"""Whole-file pending review packets; candidate calls are NOT rewrite obligations."""
import collections
import hashlib
import json
from pathlib import Path
import re
from check_pilot import validate_graph_context
ROOT=Path(__file__).resolve().parents[1]


def build(structural, site_map, proofs, lexical):
    bindings=collections.defaultdict(list)
    roles=collections.defaultdict(list)
    for binding in site_map['bindings']:
        role_map={r['site_id']:r['role'] for r in binding.get('site_roles',[])}
        if binding['kind']=='replacement':bindings[(binding['line'],binding['call'])].append(binding['case_id'])
        if binding['kind']=='replacement' and binding['site_id'] in role_map:
            roles[(binding['line'],binding['call'])].append({'case_id':binding['case_id'],'role':role_map[binding['site_id']]})
        for extra in binding.get('additional_sites',[]):
            bindings[(extra['line'],extra['call'])].append(binding['case_id'])
            if extra['site_id'] in role_map:
                roles[(extra['line'],extra['call'])].append({'case_id':binding['case_id'],'role':role_map[extra['site_id']]})
    proof_map=collections.defaultdict(list)
    for proof in proofs['rules']:
        if proof.get('source_case'):proof_map[proof['source_case']].append(proof['theorem'])
        for case in proof.get('additional_source_cases',[]):proof_map[case].append(proof['theorem'])
    rows=[]
    for call in structural['calls']:
        name=call['call']
        if name.startswith('mutable_'):
            category='mutable_accessor_requires_alias_write_analysis'
        elif name.startswith('set_') or name in ('UpdateLayout','SetAndSanitizeName'):
            category='metadata_or_layout_write_candidate'
        elif name.startswith('Create') or name.startswith('Clone') or name=='AddInstruction':
            category='construction_candidate_not_necessarily_rewrite'
        elif call['kind']=='replacement':category='replacement_or_rewrite_helper_candidate'
        else:category='other_mutation_or_helper_candidate'
        cases=bindings[(call['line'],name)]
        method=re.search(r'AlgebraicSimplifierVisitor::(\w+)\s*\(',call['owner_declarator'] or '')
        rows.append({'id':f"call-{call['byte_start']}-{call['byte_end']}",
                     'source_sha256':structural['source_sha256'],
                     'line':call['line'],'byte_start':call['byte_start'],'byte_end':call['byte_end'],
                     'source':call['source'],'call':name,'owner_declarator':call['owner_declarator'],
                     'visitor_method':method[1] if method else None,
                     'discovery_category':category,'syntactic_context':call['context'],
                     'enclosing_syntax_rewrite_ids':call['enclosing_syntax_rewrites'],
                     'case_schema_ids':cases,
                     'case_site_roles':roles[(call['line'],name)],
                     'related_value_theorems':sorted({p for c in cases for p in proof_map[c]}),
                     'related_graph_context_evidence':sorted([r for r in proofs['graph_context']['rules'] if r['source_case'] in cases],key=lambda r:r['theorem']),
                     'related_effectful_graph_evidence':sorted([r for r in proofs['effectful_graph_context']['rules'] if r['source_case'] in cases],key=lambda r:r['theorem']),
                     'related_control_order_diagnostics':sorted([r for r in proofs['boolean_control_family']['source_cases'] if r['source_case'] in cases],key=lambda r:r['source_case']),
                     'related_nested_slice_evidence':proofs['nested_slice'] if proofs['nested_slice']['source_case'] in cases else None,
                     'review_status':'pending_semantic_review',
                     'outstanding':['classify actual graph effect or non-rewrite role',
                                    'trace guard dataflow, early exits and called helpers',
                                    'split datatype/layout/configuration cases where required',
                                    'formulate general source-faithful Lean contract',
                                    'independent source correspondence review'],
                     'accepted_source_proof':None})
    assignments=[]
    for item in structural['assignment_expressions']:
        method=re.search(r'AlgebraicSimplifierVisitor::(\w+)\s*\(',item['owner_declarator'] or '')
        assignments.append({'id':f"assignment-{item['byte_start']}-{item['byte_end']}",
                            **item,'visitor_method':method[1] if method else None,
                            'review_status':'pending_type_alias_and_path_review','accepted_source_proof':None})
    handlers=[d for d in lexical['definitions'] if d['name'].startswith('Handle')]
    coverage=[]
    for handler in handlers:
        owned=[r for r in rows if r['visitor_method']==handler['name']]
        writes=[r for r in assignments if r['visitor_method']==handler['name']]
        coverage.append({'handler':handler['name'],'line':handler['line'],
                         'candidate_call_ids':[r['id'] for r in owned],
                         'candidate_assignment_ids':[r['id'] for r in writes],
                         'status':'pending_handler_review',
                         'zero_local_candidates_requires_delegation_review':not bool(owned or writes)})
    ordered_path=ROOT/'census/ordered-source-paths.json'
    if ordered_path.exists():
        ordered=json.loads(ordered_path.read_text())
        for row in rows:
            related=[]
            for function in ordered['source_functions']:
                for stage in function['stages']:
                    if set(stage['source_cases']) & set(row['case_schema_ids']):
                        related.append({'handler':function['name'],'stage':stage['id'],
                                        'contract':'census/ordered-source-paths.json',
                                        'status':'source_inspected_type_graph_contracts_open'})
            row['related_ordered_source_paths']=related
            if set(row['case_schema_ids']) & {'HandleCompare/nonnegative-ge','HandleCompare/nonnegative-le'}:
                row['related_ordered_nan_diagnostic']='census/ordered-compare-contract.json'
    for row in rows:
        if 'HandleDynamicSlice/nested-after-scaled-probe' in row['case_schema_ids']:
            row['related_scaled_nested_slice_counterexample']=proofs['scaled_nested_slice']
    for row in rows:
        if set(row['case_schema_ids']) & set(proofs['reducer_index']['source_cases']):
            row['related_reducer_index_evidence']=proofs['reducer_index']
    findings_path=ROOT/'census/source-review-findings.json'
    if findings_path.exists():
        findings=json.loads(findings_path.read_text())['findings']
        for row in rows:
            row['related_independent_review_findings']=[f['id'] for f in findings
                if set(f['source_cases']) & set(row['case_schema_ids'])]
    normalization_path=ROOT/'census/source-normalization-registry.json'
    if normalization_path.exists():
        normalized=json.loads(normalization_path.read_text())
        for row in rows:
            row['independent_local_source_normalization']=[r for r in normalized['records']
                if r['source_case'] in row['case_schema_ids']]
    replay=ROOT/'reports/xla-replay-v2/result.json'
    if replay.exists():
        for record in rows:
            if 'HandleMultiply/predicate-convert' in record['case_schema_ids']:
                record['related_native_replays']=['reports/xla-replay-v2/result.json','reports/xla-replay-v3/result.json']
                record['native_observation']='NaN-to-zero change for false predicate and nonfinite f32 operands; both operand orders'
                record['explicit_contract_refutation']=proofs.get('numerical_refutation')
                record['remaining_refutation_work']=['intended numerical contract review','machine-checked source/contract correspondence']
    boundary_replay=ROOT/'reports/empty-slice-replay-v2/result.json'
    if boundary_replay.exists():
        for record in rows:
            if set(record['case_schema_ids']) & {'RemoveRedundantStride/single-element-axes','TryToReorderSliceAndReverse/commute'}:
                record['related_native_replays']=['reports/empty-slice-replay-v2/result.json']
                record['native_observation']='verified s32[0] slice becomes invalid: rewritten bounds infer s32[1]'
                record['explicit_contract_refutation']=proofs.get('shape_refutation')
                record['remaining_refutation_work']=['independent source/shape-contract correspondence review','source arithmetic and signed-int64 range bridge']
    scalar_replay=ROOT/'reports/scalar-select-replay-v2/result.json'
    if scalar_replay.exists():
        for record in rows:
            if 'ScalarMultiplyReduction/target-output' in record['case_schema_ids']:
                record['related_native_replays']=['reports/scalar-select-replay-v2/result.json']
                record['native_observation']='finite f32 branch scales 2 and 3 moved to output product6: true 8->24, false12->24; disabled-option controls unchanged'
                record['explicit_contract_refutation']=proofs.get('algebraic_refutation')
                record['remaining_refutation_work']=['independent source correspondence','binary32 exact arithmetic bridge','complete caller traversal and alias contract']
    return {'schema':1,'status':'whole_file_discovery_review_backlog_not_frozen_obligations',
            'source_sha256':structural['source_sha256'],'denominator_frozen':False,
            'accepted_source_rewrites':0,'candidate_calls':rows,'assignment_candidates':assignments,'handlers':coverage,
            'discovery_counts':dict(collections.Counter(r['discovery_category'] for r in rows)),
            'unbound_extracted_replacement_cases':[b for b in site_map['bindings'] if b['kind']=='replacement' and not any(b['case_id'] in r['case_schema_ids'] for r in rows)],
            'limitations':['name-based discovery can miss indirect effects and non-matching APIs',
                           'syntax context is not a complete semantic guard',
                           'macro semantics remain in the syntax-rewrite ledger',
                           'candidate count is not the verification denominator']}


def validate(result, structural, proofs):
    validate_graph_context(proofs['graph_context'],proofs['rules'])
    expected_assignments={(a['byte_start'],a['byte_end']):a for a in structural['assignment_expressions']}
    assignments=result['assignment_candidates']
    coordinates=[(a['byte_start'],a['byte_end']) for a in assignments]
    if len(coordinates)!=len(set(coordinates)) or set(coordinates)!=set(expected_assignments):
        raise ValueError('assignment omission or duplication')
    for record in assignments:
        source=expected_assignments[(record['byte_start'],record['byte_end'])]
        if any(record[k]!=source[k] for k in ('source','target','value','operator','line','owner_declarator','context','overlapping_syntax_rewrites')):
            raise ValueError('assignment source identity mismatch')
        if record['accepted_source_proof'] is not None:
            raise ValueError('assignment promoted without review')
    expected={(c['byte_start'],c['byte_end']) for c in structural['calls']}
    found=[(c['byte_start'],c['byte_end']) for c in result['candidate_calls']]
    if len(found)!=len(set(found)) or set(found)!=expected:raise ValueError('candidate omission or duplication')
    source={(c['byte_start'],c['byte_end']):c for c in structural['calls']}
    for record in result['candidate_calls']:
        item=source[(record['byte_start'],record['byte_end'])]
        if any(record[k]!=item[k] for k in ('line','source','call')):raise ValueError('source identity mismatch')
        expected_graph=sorted([r for r in proofs['graph_context']['rules'] if r['source_case'] in record['case_schema_ids']],key=lambda r:r['theorem'])
        if record['related_graph_context_evidence']!=expected_graph:raise ValueError('graph evidence omitted or broadened')
        expected_effectful=sorted([r for r in proofs['effectful_graph_context']['rules'] if r['source_case'] in record['case_schema_ids']],key=lambda r:r['theorem'])
        if record['related_effectful_graph_evidence']!=expected_effectful:raise ValueError('effectful evidence omitted or broadened')
        expected_order=sorted([r for r in proofs['boolean_control_family']['source_cases'] if r['source_case'] in record['case_schema_ids']],key=lambda r:r['source_case'])
        if record['related_control_order_diagnostics']!=expected_order:raise ValueError('control-order diagnostic omitted or promoted')
        expected_nested=proofs['nested_slice'] if proofs['nested_slice']['source_case'] in record['case_schema_ids'] else None
        if record['related_nested_slice_evidence']!=expected_nested:raise ValueError('nested slice evidence omitted or broadened')
        if record['accepted_source_proof'] is not None:raise ValueError('pending packet promoted without acceptance')
    if result['unbound_extracted_replacement_cases']:raise ValueError('extracted schema silently unbound')


def main():
    load=lambda name:json.loads((ROOT/name).read_text())
    structural=load('census/normalized-structural-sites.json')
    proofs=load('census/pilot-value-proofs.json')
    result=build(structural,load('census/site-case-map.json'),proofs,load('census/source-sites.json'))
    validate(result,structural,proofs)
    (ROOT/'census/review-ledger.json').write_text(json.dumps(result,indent=2)+'\n')
    print(f"{len(result['candidate_calls'])} call packets and {len(result['assignment_candidates'])} assignment candidates across {len(result['handlers'])} handler records; source denominator remains open")

if __name__=='__main__':main()
