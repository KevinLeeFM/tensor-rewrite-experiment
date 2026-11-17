"""Build an honest ID-preserving status overlay; does not alter historical ledgers."""
import collections, hashlib, json, pathlib
root = pathlib.Path(__file__).resolve().parents[2]
source = root / 'census/mathematical-ledger.json'
paper = root / 'comparisons/tensorright-v1/cases.json'
site = root / 'census/site-case-map.json'
load = lambda p: json.loads(p.read_text())
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
a, b, c = load(source), load(paper), load(site)
records, cases, bindings = a['benchmark_records'], b['cases'], c['bindings']
assert len(records) == len(bindings) == 488 and len(cases) == 118
ids = [r['benchmark_id'] for r in records]
assert len(set(ids)) == len(ids) and set(ids) == {r['case_id'] for r in bindings}
assert len({r['id'] for r in cases}) == len(cases)
modern = []
for r in records:
    modern.append({'id': r['benchmark_id'], 'outcome': 'unresolved',
        'reason': r['mathematical_target_status'],
        'work_state': 'inherited_checked_partial_evidence' if r['evidence'] else 'no_attempt_evidence_in_inherited_ledger',
        'scope': 'complete retained source record; formulation/domain coverage not yet established',
        'existing_evidence': r['evidence'], 'whole_record_closed_in_inherited_ledger': r['whole_record_mathematically_closed'],
        'effort': {'active_seconds': None, 'elapsed_seconds': None, 'reason': 'not measured per record in inherited ledger'}})
assert not any(x['whole_record_closed_in_inherited_ledger'] for x in modern)
accepted = {
    'HandleTranspose/space-depth-user-mutation': ['space-depth-frozen-nat-model'],
    'BroadcastReduce/single': ['BroadcastReduce/single-empty-input-or-output'],
    'HandleReduce/same-element-count': ['HandleReduce/same-element-count-single-output-left-identity'],
    'ReplaceReduceWithReshape/single': ['HandleReduce/same-element-count-single-output-left-identity'],
    'HandleSlice/compose-unstrided': ['HandleSlice/compose-unstrided-static-tensor-model'],
}
for row in modern:
    if row['id'] in accepted:
        row['work_state'] = 'revised_model_partition_verified_whole_record_open'
        row['accepted_model_partitions'] = accepted[row['id']]
# Evidence for precise source-record observations lives alongside the inherited whole-record state.
packet = pathlib.Path(__file__).resolve().parent
followup = load(packet / 'record-outcomes.json')
source_manifest = load(root / followup['inventory_versions']['manifest'])
assert source_manifest['xla_commit'] == followup['inventory_versions']['retained_xla_commit']
assert source_manifest['historical_artifact'] == followup['inventory_versions']['paper_artifact']
indexed = {row['id']: row for row in modern}
for observation in followup['observations']:
    for review in observation['reviews']:
        assert (packet / review).is_file(), review
    for case_id, branches in observation['record_branches'].items():
        row = indexed[case_id]
        assert 'reviewed_record_observation' not in row, case_id
        row['reviewed_record_observation'] = {
            'id': observation['name'], 'branches': branches,
            'accepted_models': sorted({observation['models'][b] for b in branches}),
            'outcome': 'proved_in_declared_logical_value_model',
            'scope': observation['scope'], 'residual': observation['residual'],
            'reviews': observation['reviews']}
        row['work_state'] = 'revised_model_partition_verified_whole_record_open'
for result in followup.get('counterexamples', []):
    assert (packet / result['review']).is_file(), result['review']
    indexed[result['record']].setdefault('reviewed_model_counterexamples', []).append(result)

historical = []
for r in cases:
    old = r['lean_result']
    outcome = {'proved': 'proved_model_inherited', 'disproved_in_model': 'disproved_model_inherited',
               'vacuous_in_paper_model': 'unresolved_vacuous_model'}[old]
    historical.append({'id': r['id'], 'outcome': outcome, 'historical_result': old,
        'work_state': 'historical_model_result_with_checked_evidence_not_fresh_trial',
        'evidence_theorems': r['lean_theorems'], 'proof_file': r['lean_proof_file'],
        'proof_sha256': r['lean_proof_sha256'], 'scope': r['translation_confidence'],
        'effort': {'active_seconds': None, 'elapsed_seconds': None, 'reason': 'per-case development effort not recovered'}})
out = {'schema': 1, 'status': 'initial_reconciliation_not_final_scope_selection',
 'scope_note': 'Two separate inventories; do not sum or infer one-to-one correspondence. Source candidates are lexical records, not automatically distinct mathematical statements.',
 'sources': {str(p.relative_to(root)): sha(p) for p in [source, paper, site]},
 'source_candidates': {'records': modern, 'counts': dict(collections.Counter(r['outcome'] for r in modern)),
    'inherited_status_counts': dict(collections.Counter(r['reason'] for r in modern))},
 'historical_cases': {'records': historical, 'counts': dict(collections.Counter(r['outcome'] for r in historical))},
 'slice_tensor_partition': {'source_record': 'HandleSlice/compose-unstrided', 'case_id': 'HandleSlice/compose-unstrided-static-tensor-model', 'status': 'proved_model_independently_reviewed', 'scope': 'arbitrary-rank logical tensor model; Int attributes; no source correspondence or full-record claim', 'proof_commit': '29dd0d804b6896f0723f3b0d19920af93065a346', 'review': 'comparisons/revised-benchmark-20261117/slice-compose-rank/TENSOR-REVIEW.md', 'effort': {'active_seconds': None, 'reason': 'historical discovery and active reasoning not measured'}},
 'slice_validity_partition': {'source_record': 'HandleSlice/compose-unstrided', 'case_id': 'HandleSlice/compose-unstrided-validity-one-axis', 'status': 'proved_model_independently_reviewed', 'scope': 'one-axis mathematical Int attribute validity, not whole tensor/source rewrite', 'proof_commit': '4369484cedd5e367b4bdcdf3134509eb9360068d', 'review': 'comparisons/revised-benchmark-20261117/slice-compose-static/REVIEW.md', 'effort': {'active_seconds': None, 'reason': 'worker active time not instrumented'}},
 'same_count_partition': {'source_records': ['HandleReduce/same-element-count', 'ReplaceReduceWithReshape/single'], 'case_id': 'HandleReduce/same-element-count-single-output-left-identity', 'status': 'proved_model_independently_reviewed_reuse', 'scope': 'single-output logical value with actual initializer left-identity; whole source records unresolved', 'proof_commit': '2ac92cde1e3d1ae1bb4db3e7527c7c1d1057954e', 'review': 'comparisons/revised-benchmark-20261117/reduce-same-count/REVIEW.md', 'effort': {'historical_discovery_seconds': None, 'reason': 'direct reuse; not measured as fresh proof'}},
 'empty_reduction_partition': {'source_record': 'BroadcastReduce/single', 'case_id': 'BroadcastReduce/single-empty-input-or-output', 'status': 'proved_model_independently_reviewed_reuse', 'scope': 'single-output logical value, empty input or empty output; output-empty branch vacuous; whole source record unresolved', 'proof_commit': '7725b5b6156fc776ca0673483c2030abcf02994f', 'review': 'comparisons/revised-benchmark-20261117/broadcast-reduce-single/REVIEW.md', 'effort': {'historical_discovery_seconds': None, 'reason': 'direct reuse; not measured as fresh proof'}},
 'space_depth_partition': {'source_record': 'HandleTranspose/space-depth-user-mutation', 'status': 'proved_model_independently_reviewed_revised_policy',
    'scope': 'frozen layout-insensitive Nat model with outerRankAtLeast; not full source record/correspondence',
    'candidate_commit': 'aa5521b38e8304a14350a684f9cef914d1f65158',
    'revised_review': 'comparisons/revised-benchmark-20261117/space-depth-review/REVIEW.md',
    'final_guard_history': 'failed final environment: five generic campaign inventory names; revised policy permits reuse and does not make that check pass',
    'effort': {'active_seconds': None, 'elapsed_seconds': None, 'reason': 'partial phase records, downtime and overlap preclude defensible aggregate'}}}
out['status'] = 'versioned_inventories_with_reviewed_record_observations'
out['inventory_versions'] = followup['inventory_versions']
out['sources'][str((packet / 'record-outcomes.json').relative_to(root))] = sha(packet / 'record-outcomes.json')
out['sources'][followup['inventory_versions']['manifest']] = sha(root / followup['inventory_versions']['manifest'])
out['source_candidates']['work_state_counts'] = dict(collections.Counter(row['work_state'] for row in modern))
out['source_candidates']['records_with_reviewed_record_observation'] = sum('reviewed_record_observation' in row for row in modern)
(root/'comparisons/revised-benchmark-20261117/outcome-ledger.json').write_text(json.dumps(out, indent=2)+'\n')
print('source',out['source_candidates']['counts'],'inherited',out['source_candidates']['inherited_status_counts'])
print('historical',out['historical_cases']['counts'])
