"""Build an honest ID-preserving status overlay; does not alter historical ledgers."""
import collections, hashlib, json, pathlib
from model_cases import attach_model_cases
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
            'outcome': observation.get('outcome', 'proved_in_declared_logical_value_model'),
            'effort_groups': sorted({observation['effort_by_model'][observation['models'][b]] for b in branches}
                | set(observation.get('additional_effort_groups', []))),
            'scope': observation['scope'], 'residual': observation['residual'],
            'reviews': observation['reviews']}
        row['work_state'] = 'revised_model_partition_verified_whole_record_open'
for result in followup.get('counterexamples', []):
    assert (packet / result['review']).is_file(), result['review']
    row = indexed[result['record']]
    witness = result.get('archived_native_witness')
    if witness:
        receipt = root / witness['receipt']
        assert load(receipt)['source_commit'] == source_manifest['xla_commit']
        row.setdefault('archived_configured_native_counterexamples', []).append({
            **witness, 'receipt_sha256': sha(receipt), 'review': result['review']})
    row.setdefault('reviewed_model_counterexamples', []).append(result)
    row['work_state'] = 'revised_model_partition_verified_whole_record_open'

for diagnostic in followup.get('guard_diagnostics', []):
    assert (packet / diagnostic['review']).is_file(), diagnostic['review']
    row = indexed[diagnostic['record']]
    row.setdefault('reviewed_guard_diagnostics', []).append(diagnostic)
    if row['work_state'] != 'revised_model_partition_verified_whole_record_open':
        row['work_state'] = 'attempted_guard_diagnostic_source_obligation_open'

crosswalk_path = packet / 'recovered-witnesses/heldout-crosswalk.json'
crosswalk = load(crosswalk_path)
assert crosswalk['xla_commit'] == source_manifest['xla_commit']
site_by_case = {binding['case_id']: binding['site_id'] for binding in bindings if 'site_id' in binding}
seen_earlier = set()
for entry in crosswalk['rows']:
    case_id = entry['source_id']
    assert case_id not in seen_earlier and site_by_case[case_id] == entry['site_id']
    assert entry['whole_source_record_closed'] is False
    seen_earlier.add(case_id)
    row = indexed[case_id]
    row['earlier_reviewed_partition'] = entry
    if row['work_state'] in {'no_attempt_evidence_in_inherited_ledger', 'inherited_checked_partial_evidence'}:
        row['work_state'] = 'earlier_independently_accepted_model_partition_whole_record_open'

# Full mathematical record outcomes supplement the immutable inherited inventory.
verdict_path = packet / 'whole-record-audit/record-verdicts.json'
verdicts = load(verdict_path)
effort_path = packet / 'whole-record-audit/effort.json'
record_effort = load(effort_path)
assert len({v['id'] for v in verdicts}) == len(verdicts)
for verdict in verdicts:
    row = indexed[verdict['id']]
    assert sha(packet / verdict['review']) == verdict['review_sha256']
    assert verdict['effort_group'] in record_effort
    if verdict['outcome'] == 'disproved_record_preservation':
        receipt = root / verdict['receipt']
        assert sha(receipt) == verdict['receipt_sha256']
        evidence = load(receipt)
        assert evidence['source_commit'] == source_manifest['xla_commit']
        assert evidence['exit_code'] == 0 and evidence['test_passed']
        assert all(sha(root / f['path']) == f['sha256'] for f in evidence['files'])
        matches = [c for c in evidence['cases'] if all(
            c.get(k) == v for k, v in verdict['selector'].items())]
        assert len(matches) == 1
        witness = matches[0]
        if 'before' in witness:
            assert witness['rewritten_verified'] and witness['before'] != witness['after']
        else:
            assert witness['original_verified'] and not witness['rewritten_verified']
    else:
        assert verdict['outcome'] == 'proved_shape_inferred_operator_model'
        assert sha(packet / verdict['proof']) == verdict['proof_sha256']
        frozen = {}
        for line in (packet / verdict['manifest']).read_text().splitlines():
            digest, name = line.split(maxsplit=1)
            assert sha(root / name) == digest
            frozen[name] = digest
        assert str((packet / verdict['spec']).relative_to(root)) in frozen
        row['shape_inferred_operator_verdict'] = verdict
        row['work_state'] = 'revised_model_partition_verified_whole_record_open'
        continue
    row['complete_record_verdict'] = verdict
    row['outcome'] = verdict['outcome']
    row['reason'] = verdict['scope']
    row['scope'] = verdict['scope']
    row['prior_partition_work_state'] = row['work_state']
    row['work_state'] = 'reviewed_complete_record_outcome'

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
    'inherited_status_counts': dict(collections.Counter(r['mathematical_target_status'] for r in records))},
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
out['whole_record_review_effort_groups'] = record_effort
out['sources'][str(effort_path.relative_to(root))] = sha(effort_path)
out['sources'][str(verdict_path.relative_to(root))] = sha(verdict_path)
out['sources'][str(crosswalk_path.relative_to(root))] = sha(crosswalk_path)
out['source_candidates']['records_with_earlier_reviewed_partition'] = len(seen_earlier)
out['source_candidates']['records_with_any_reviewed_partition'] = sum(
    row.get('prior_partition_work_state', row['work_state']) == 'revised_model_partition_verified_whole_record_open' or
    bool(row.get('complete_record_verdict')) or 'earlier_reviewed_partition' in row for row in modern)
out['inventory_versions'] = followup['inventory_versions']
out['revised_effort_groups'] = followup['effort_groups']
for row in modern:
    logical = row.get('reviewed_record_observation', {})
    groups = set(logical.get('effort_groups', []))
    groups.update(x['effort_group'] for x in row.get('reviewed_model_counterexamples', []))
    groups.update(x['effort_group'] for x in row.get('reviewed_guard_diagnostics', []))
    if groups:
        assert groups <= followup['effort_groups'].keys()
        row['effort']['new_shared_measurement_groups'] = sorted(groups)
for group in followup['effort_groups'].values():
    assert (packet / group['review']).is_file(), group['review']
out['sources'][str((packet / 'record-outcomes.json').relative_to(root))] = sha(packet / 'record-outcomes.json')
out['sources'][followup['inventory_versions']['manifest']] = sha(root / followup['inventory_versions']['manifest'])
out['source_candidates']['records_with_archived_configured_native_counterexample'] = sum(
    bool(row.get('archived_configured_native_counterexamples')) for row in modern)
out['source_candidates']['records_with_reviewed_counterexample'] = sum(bool(r.get('reviewed_model_counterexamples')) for r in modern)
out['source_candidates']['reviewed_observation_outcomes'] = dict(collections.Counter(r['reviewed_record_observation']['outcome'] for r in modern if 'reviewed_record_observation' in r))
out['source_candidates']['work_state_counts'] = dict(collections.Counter(row['work_state'] for row in modern))
out['source_candidates']['records_with_reviewed_record_observation'] = sum('reviewed_record_observation' in row for row in modern)
attach_model_cases(out, packet, root, modern, crosswalk)
out['status'] = 'reviewed_mathematical_cases_with_separate_whole_source_assurance'
(root/'comparisons/revised-benchmark-20261117/outcome-ledger.json').write_text(json.dumps(out, indent=2)+'\n')
print('source',out['source_candidates']['counts'],'inherited',out['source_candidates']['inherited_status_counts'])
print('historical',out['historical_cases']['counts'])
