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
    reuse_links = []
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
    for name in ('structural', 'value', 'new', 'inherited', 'control', 'nov18', 'extrema', 'gather-dot', 'pad-dot', 'slice-dot-followup', 'dot-overlap', 'dot-unit', 'fiber-broadcast', 'guard-domains', 'scan-shape', 'window-convolution', 'collective-window', 'pointwise-concat', 'physical-conv-domains', 'mixed-physical', 'layout-scatter-windows', 'mixed-tap-reductions', 'signed-prefix-reuse', 'window-early', 'bitcast-admission', 'literal-empty-outer'):
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
            entry = {**row, 'outcome': outcome, 'scope_review': str(review.relative_to(root)),
                     'catalog': name}
            if 'historical_reuse' in row:
                assert row['historical_reuse'] in row['evidence']
                reuse_links.append(entry)
                source_field = 'mathematical_reuse_ids'
            else:
                counts[outcome] += 1
                cases.append(entry)
                source_field = 'mathematical_case_ids'
            for source_id in row['source_ids']:
                by_source[source_id].setdefault(source_field, []).append(row['id'])
        groups[name] = dict(counts)
    assert cited == manifest.keys()
    alias_rows_path = directory / 'delegation137-alias-rows.json'
    alias_review_path = directory / 'delegation137-alias-review.md'
    for path in (alias_rows_path, alias_review_path):
        assert digest(path) == pinned_catalogs[path.name], path
        audit_inputs.append(path)
    aliases = read(alias_rows_path)
    outcomes_by_id = {case['id']: case for case in cases}
    seen_aliases = set()
    for alias in aliases:
        caller = by_source[alias['source_id']]
        target = outcomes_by_id[alias['existing_case_id']]
        pair = (caller['id'], target['id'])
        assert pair not in seen_aliases and caller['id'] not in target['source_ids']
        seen_aliases.add(pair)
        assert set(alias['existing_source_ids']) <= set(target['source_ids'])
        assert alias['outcome'] == target['outcome'] and alias['theorem'] == target['theorem']
        receipt = alias['historical_review_or_receipt']
        receipt_hash = historical_blobs[receipt] if ':' in receipt else digest(root / receipt)
        assert receipt_hash == alias['receipt_sha256']
        caller.setdefault('mathematical_case_ids', []).append(target['id'])
    sources_with_cases = {s for s, r in by_source.items() if r.get('mathematical_case_ids') or r.get('mathematical_reuse_ids')}
    for row in modern:
        if row['id'] in sources_with_cases and row['work_state'] in {
            'inherited_checked_partial_evidence', 'no_attempt_evidence_in_inherited_ledger'
        }:
            row['pre_model_audit_work_state'] = row['work_state']
            row['work_state'] = 'reviewed_mathematical_case_whole_source_open'
    candidates = out['source_candidates']
    candidates['work_state_counts'] = dict(collections.Counter(row['work_state'] for row in modern))
    candidates['records_with_any_reviewed_partition'] = sum(
        bool(row['id'] in sources_with_cases or row.get('earlier_reviewed_partition')
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
        'reviewed_source_delegations': aliases,
        'source_ids_represented': len(sources_with_cases),
        'source_ids_without_catalogued_case': sorted(by_source.keys() - sources_with_cases),
        'inherited_family_ids_with_catalogued_case': sorted(family_ids & sources_with_cases),
        'inherited_family_ids_pending_catalog_review': sorted(family_ids - sources_with_cases),
        'historical_reuse_links': reuse_links,
        'cases': cases}
    for path in audit_inputs:
        out['sources'][str(path.relative_to(root))] = digest(path)
