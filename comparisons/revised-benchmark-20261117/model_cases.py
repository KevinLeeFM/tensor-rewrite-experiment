"""Attach reviewed mathematical cases to the source register without adding the two inventories."""
import collections
import hashlib
import json


def attach_model_cases(out, packet, root, modern, crosswalk):
    directory = packet / 'model-audit'
    read = lambda path: json.loads(path.read_text())
    digest = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    manifest_path = directory / 'evidence-sha256.json'
    manifest = read(manifest_path)
    historical_blobs = {
        f"{row['historical_commit']}:{row['packet_directory']}/{artifact['file']}": artifact['sha256']
        for row in crosswalk['rows'] for artifact in row['artifacts'].values()
    }
    by_source = {row['id']: row for row in modern}
    cases = []
    ids = set()
    cited = set()
    groups = {}
    plan = root / 'docs/experiment-plan.md'
    plan_bytes = plan.read_bytes()
    plan_blob = hashlib.sha1(b'blob ' + str(len(plan_bytes)).encode() + bytes([0]) + plan_bytes).hexdigest()
    assert plan_blob == '87d5dceba7ae672a9a36a617dc7c7e2f332873a3'
    effort_path = directory / 'effort.json'
    catalog_pins = directory / 'catalog-sha256.json'
    pinned_catalogs = read(catalog_pins)
    audit_inputs = [manifest_path, catalog_pins, effort_path, plan]
    for name in ('structural', 'value', 'new', 'inherited', 'control', 'nov18', 'extrema', 'gather-dot'):
        catalog = directory / (name + '.json')
        review = directory / (name + '-review.md')
        assert digest(catalog) == pinned_catalogs[catalog.name], catalog
        assert digest(review) == pinned_catalogs[review.name], review
        audit_inputs.extend([catalog, review])
        rows = read(catalog)
        counts = collections.Counter()
        for row in rows:
            assert all(row.get(k) for k in (
                'id', 'lhs', 'rhs', 'conditions', 'types', 'source_ids', 'theorem', 'evidence', 'overlap'))
            assert row['id'] not in ids, row['id']
            ids.add(row['id'])
            assert len(set(row['source_ids'])) == len(row['source_ids'])
            assert set(row['source_ids']) <= by_source.keys()
            assert isinstance(row['evidence'], list)
            for path in row['evidence']:
                if path not in cited:
                    actual = historical_blobs[path] if ':' in path else digest(root / path)
                    assert actual == manifest[path], path
                    cited.add(path)
            outcome = row.get('outcome', 'proved')
            assert outcome in {'proved', 'disproved'}, (row['id'], outcome)
            counts[outcome] += 1
            cases.append({**row, 'outcome': outcome, 'scope_review': str(review.relative_to(root)),
                          'catalog': name})
            for source_id in row['source_ids']:
                by_source[source_id].setdefault('mathematical_case_ids', []).append(row['id'])
        groups[name] = dict(counts)
    assert cited == manifest.keys()
    sources_with_cases = {s for s, r in by_source.items() if r.get('mathematical_case_ids')}
    for row in modern:
        if 'mathematical_case_ids' in row and row['work_state'] in {
            'inherited_checked_partial_evidence', 'no_attempt_evidence_in_inherited_ledger'
        }:
            row['pre_model_audit_work_state'] = row['work_state']
            row['work_state'] = 'reviewed_mathematical_case_whole_source_open'
    candidates = out['source_candidates']
    candidates['work_state_counts'] = dict(collections.Counter(row['work_state'] for row in modern))
    candidates['records_with_any_reviewed_partition'] = sum(
        bool(row.get('mathematical_case_ids') or row.get('earlier_reviewed_partition')
             or row.get('reviewed_record_observation') or row.get('accepted_model_partitions')
             or row.get('reviewed_model_counterexamples') or row.get('shape_inferred_operator_verdict')
             or row.get('complete_record_verdict')) for row in modern)
    inherited_family = 'declared_value_family_complete_full_record_partitions_open'
    # Classification refers to the original census even after a stronger record verdict supersedes its reason.
    source_rows = read(root / 'census/mathematical-ledger.json')['benchmark_records']
    family_ids = {r['benchmark_id'] for r in source_rows if r['mathematical_target_status'] == inherited_family}
    out['reviewed_mathematical_cases'] = {
        'plan_revision': '86cef93e98518f5b46f0ecde01efddf320ff88e5',
        'plan_path': 'docs/experiment-plan.md',
        'plan_git_blob': plan_blob,
        'effort': read(effort_path),
        'acceptance': 'Fixed original and replacement calculations under declared types and conditions; all admitted shapes, accesses and logical values. Model refutation requires an admitted violating witness.',
        'scope': 'Reviewed source-associated cases only. The remaining mathematical denominator is open. Some cases overlap historical paper laws; never add historical and current counts to claim distinct rules.',
        'counts': dict(collections.Counter(row['outcome'] for row in cases)),
        'counts_by_catalog': groups,
        'source_ids_represented': len(sources_with_cases),
        'source_ids_without_catalogued_case': sorted(by_source.keys() - sources_with_cases),
        'inherited_family_ids_with_catalogued_case': sorted(family_ids & sources_with_cases),
        'inherited_family_ids_pending_catalog_review': sorted(family_ids - sources_with_cases),
        'cases': cases}
    for path in audit_inputs:
        out['sources'][str(path.relative_to(root))] = digest(path)
