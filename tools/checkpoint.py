"""Validate the initial milestone artifacts and emit a hashed checkpoint report."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
from reconcile_sites import validate_map, validate_replacement_coverage
from extract_scalar_control_cases import validate_batch
from extract_arithmetic_cases import validate_helpers
from extract_layout_cases import validate_effect_evidence
from extract_collective_rotation_cases import validate_site_roles
from extract_tensor_index_cases import validate_loop_mutations, validate_index_effects
from extract_reduction_cases import validate_reduction_batch
from extract_dot_cases import validate_dot_batch
from extract_convolution_cases import validate_convolution_batch
from full_call_inventory import validate as validate_full_calls
from nonreplacement_effects import validate as validate_nonreplacement_effects

ROOT = Path(__file__).resolve().parents[1]


def validate_test_count(output, minimum=68):
    """Unittest discovery returning success with absent/partial suites is not evidence."""
    import re
    match=re.search(r'^Ran (\d+) tests? in ',output,re.M)
    if match is None or int(match[1])<minimum:
        raise ValueError('missing or incomplete Python test discovery: expected at least '+str(minimum))


def main():
    outputs = {}
    for name, command in (
        ('inputs', [sys.executable, 'tools/freeze_inputs.py', '--check']),
        ('structural_inventory', [sys.executable, 'tools/structural_inventory.py']),
        ('full_call_inventory', [sys.executable, 'tools/full_call_inventory.py']),
        ('typed_call_inventory', [sys.executable, 'tools/typed_call_inventory.py']),
        ('replacement_api_paths', [sys.executable, 'tools/replacement_api_paths.py']),
        ('typed_delegations', [sys.executable, 'tools/typed_delegation_evidence.py']),
        ('nonreplacement_effects', [sys.executable, 'tools/nonreplacement_effects.py']),
        ('source_normalization_registry', [sys.executable, 'tools/source_normalization_registry.py']),
        ('review_ledger', [sys.executable, 'tools/build_review_ledger.py']),
        ('lean', ['lean', '--version']),
        ('lexical_fixture', ['lean', 'tests/fixtures/Lexical.lean']),
        ('value_pilot', [sys.executable, 'tools/check_pilot.py']),
        ('tests', [sys.executable, '-B', '-m', 'unittest', 'discover', '-s', 'tests', '-v']),
        ('native_permutation', [sys.executable, 'tools/check_native_permutation.py']),
        ('pred_mul_diagnostic', [sys.executable, 'tools/check_pred_mul_nonfinite.py']),
        ('archived_xla_replay', [sys.executable, 'tools/check_xla_replay_evidence.py']),
        ('archived_empty_slice_replay', [sys.executable, 'tools/check_empty_slice_replay_evidence.py']),
        ('archived_scalar_select_replay', [sys.executable, 'tools/check_scalar_select_replay_evidence.py']),
        ('pred_constant_guard_evidence', [sys.executable, 'tools/check_pred_guard_evidence.py']),
        ('concrete_index_map_evidence', [sys.executable, 'tools/check_index_map_evidence.py']),
        ('dynamic_index_evidence', [sys.executable, 'tools/check_dynamic_index_evidence.py']),
        ('nested_slice_evidence', [sys.executable, 'tools/check_nested_slice_evidence.py']),
        ('reshape_evidence', [sys.executable, 'tools/check_reshape_evidence.py']),
        ('reduction_evidence', [sys.executable, 'tools/check_reduction_evidence.py']),
        ('dense_layout_evidence', [sys.executable, 'tools/check_dense_layout_evidence.py']),
        ('reducer_index_evidence', [sys.executable, 'tools/check_reducer_index_evidence.py']),
        ('concatenate_status_evidence', [sys.executable, 'tools/check_concatenate_status_evidence.py']),
        ('dynamic_slice_empty_reshape_evidence', [sys.executable, 'tools/check_dynamic_slice_empty_reshape_evidence.py']),
        ('scaled_nested_slice_evidence', [sys.executable, 'tools/check_scaled_nested_slice_evidence.py']),
        ('ordered_source_evidence', [sys.executable, 'tools/check_ordered_source_evidence.py']),
        ('contraction_evidence', [sys.executable, 'tools/check_contraction_evidence.py']),
        ('signed_word_evidence', [sys.executable, 'tools/check_signed_word_evidence.py']),
        ('modular_bridge_evidence', [sys.executable, 'tools/check_modular_bridge_evidence.py']),
        ('modular_arithmetic_evidence', [sys.executable, 'tools/check_modular_arithmetic_evidence.py']),
        ('replacement_api_evidence', [sys.executable, 'tools/check_replacement_api_evidence.py']),
        ('boolean_control_family_evidence', [sys.executable, 'tools/check_boolean_control_family_evidence.py']),
        ('control_effect_evidence', [sys.executable, 'tools/check_control_effect_evidence.py']),
        ('typed_call_evidence', [sys.executable, 'tools/check_typed_call_evidence.py']),
    ):
        run = subprocess.run(command, cwd=ROOT, text=True, capture_output=True)
        outputs[name] = {'exit_code': run.returncode, 'stdout': run.stdout, 'stderr': run.stderr}
        if run.returncode:
            raise RuntimeError(outputs[name])
        if name=='tests':
            validate_test_count(run.stdout+run.stderr)
    inventory = json.loads((ROOT / 'census/source-sites.json').read_text())
    structural = json.loads((ROOT / 'census/structural-sites.json').read_text())
    assert structural['source_sha256'] == inventory['source_sha256']
    assert not structural['denominator_frozen']
    normalized = json.loads((ROOT / 'census/normalized-structural-sites.json').read_text())
    assert normalized['source_sha256'] == inventory['source_sha256']
    assert not normalized['parse_has_errors']
    assert all(s['structural_classification']=='function_declarator_not_call'
               for s in normalized['lexical_only_sites'])
    assert all(r['kind']!='unsupported_macro' for r in normalized['syntax_rewrites'])
    supplement = json.loads((ROOT / 'sources/dependency-supplement.json').read_text())
    for item in supplement['files']:
        assert hashlib.sha256((ROOT/item['path']).read_bytes()).hexdigest() == item['sha256']
    collective_sources=json.loads((ROOT/'sources/collective-contract-manifest.json').read_text())
    assert collective_sources['source_commit']==json.loads((ROOT/'sources/manifest.json').read_text())['xla_commit']
    for item in collective_sources['files']:
        assert hashlib.sha256((ROOT/item['path']).read_bytes()).hexdigest()==item['sha256']
    reduction_sources=json.loads((ROOT/'sources/reduction-contract-manifest.json').read_text())
    assert reduction_sources['source_commit']==collective_sources['source_commit']
    for item in reduction_sources['files']:
        assert hashlib.sha256((ROOT/item['path']).read_bytes()).hexdigest()==item['sha256']
    convolution_sources=json.loads((ROOT/'sources/convolution-contract-manifest.json').read_text())
    assert convolution_sources['source_commit']==collective_sources['source_commit']
    for item in convolution_sources['files']:
        assert hashlib.sha256((ROOT/item['path']).read_bytes()).hexdigest()==item['sha256']
    effects_sources=json.loads((ROOT/'sources/effects-contract-manifest.json').read_text())
    assert effects_sources['source_commit']==collective_sources['source_commit']
    for item in effects_sources['files']:
        assert hashlib.sha256((ROOT/item['path']).read_bytes()).hexdigest()==item['sha256']
    guard_sources=json.loads((ROOT/'sources/constant-guard-contract-manifest.json').read_text())
    assert guard_sources['source_commit']==collective_sources['source_commit']
    for item in guard_sources['files']:
        assert hashlib.sha256((ROOT/item['path']).read_bytes()).hexdigest()==item['sha256']
    historical = json.loads((ROOT / 'census/historical-rules.json').read_text())
    assert not inventory['denominator_frozen']
    assert historical['invoked_in_main_suite'] == 118
    # Stable IDs and source bounds, including source snippets for extracted cases.
    source = (ROOT / 'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_text().splitlines()
    ids = [site['id'] for site in inventory['sites']]
    assert len(ids) == len(set(ids))
    for case in json.loads((ROOT / 'census/initial-cases.json').read_text())['cases']:
        assert case['source_excerpt'] == '\n'.join(source[case['line']-1:case['end_line']])
        assert case['status'] == 'extracted_pending_review'
    batch = json.loads((ROOT / 'census/simple-cases.json').read_text())
    assert batch['source_sha256'] == inventory['source_sha256']
    assert not batch['denominator_frozen']
    batch_ids = [case['id'] for case in batch['cases']]
    assert len(batch_ids) == len(set(batch_ids))
    definitions = {d['name']: d for d in inventory['definitions']}
    for case in batch['cases']:
        owner = definitions[case['handler']]
        assert case['line'] == owner['line'] and case['end_line'] == owner['end_line']
        assert case['proof'] is None and case['lean_statement'] is None
    shape = json.loads((ROOT / 'census/shape-cases.json').read_text())
    scalar_control = json.loads((ROOT / 'census/scalar-control-cases.json').read_text())
    arithmetic = json.loads((ROOT / 'census/arithmetic-cases.json').read_text())
    layout = json.loads((ROOT / 'census/layout-cases.json').read_text())
    collective_rotation = json.loads((ROOT / 'census/collective-rotation-cases.json').read_text())
    tensor_index = json.loads((ROOT / 'census/tensor-index-cases.json').read_text())
    reduction = json.loads((ROOT / 'census/reduction-cases.json').read_text())
    dot = json.loads((ROOT / 'census/dot-cases.json').read_text())
    convolution = json.loads((ROOT / 'census/convolution-cases.json').read_text())
    validate_batch(scalar_control, inventory, source)
    validate_batch(arithmetic, inventory, source)
    validate_helpers(arithmetic, source)
    validate_batch(layout, inventory, source)
    validate_helpers(layout, source)
    validate_effect_evidence(layout, source, normalized)
    validate_batch(collective_rotation, inventory, source)
    validate_helpers(collective_rotation, source)
    validate_site_roles(collective_rotation, normalized)
    validate_batch(tensor_index, inventory, source)
    validate_helpers(tensor_index, source)
    validate_loop_mutations(tensor_index, normalized)
    validate_index_effects(tensor_index, source, normalized)
    validate_reduction_batch(reduction, inventory, source, normalized)
    validate_dot_batch(dot, inventory, source, normalized)
    validate_convolution_batch(convolution, inventory, source, normalized)
    for case in layout['cases']:
        for effect in case.get('effect_evidence',[]):
            assert effect['anchor'] in source[effect['line']-1]
    site_map = json.loads((ROOT / 'census/site-case-map.json').read_text())
    full_calls=json.loads((ROOT/'census/full-call-inventory.json').read_text())
    effects=json.loads((ROOT/'census/nonreplacement-effects.json').read_text())
    validate_full_calls(full_calls, (ROOT/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_bytes(), normalized, inventory, site_map)
    validate_nonreplacement_effects(effects,full_calls,normalized,site_map)
    validate_map(site_map, inventory, batch['cases'] + shape['cases'] + scalar_control['cases'] + arithmetic['cases'] + layout['cases'] + collective_rotation['cases'] + tensor_index['cases'] + reduction['cases'] + dot['cases'] + convolution['cases'], normalized)
    validate_replacement_coverage(shape, site_map, inventory)
    assert scalar_control['source_sha256'] == inventory['source_sha256']
    assert not scalar_control['denominator_frozen']
    source_sites = {s['id']: s for s in inventory['sites']}
    for case in scalar_control['cases']:
        body = '\n'.join(source[case['line']-1:case['end_line']])
        assert hashlib.sha256(body.encode()).hexdigest() == case['source_body_sha256']
        assert case['proof'] is None
        if 'replacement_site_id' in case:
            site = source_sites[case['replacement_site_id']]
            assert site['owner'] == case['handler']
            assert site['line'] == case['replacement_line']
            assert site['call'] == case['replacement_call']
            assert source[site['line']-1] == case['replacement_source']
        else:
            assert case['delegation_target'] in source[case['delegation_line']-1]
    assert shape['source_sha256'] == inventory['source_sha256']
    assert not shape['denominator_frozen']
    shape_ids = [case['id'] for case in shape['cases']]
    assert len(shape_ids) == len(set(shape_ids))
    for case in shape['cases']:
        body = '\n'.join(source[case['line']-1:case['end_line']])
        assert hashlib.sha256(body.encode()).hexdigest() == case['source_body_sha256']
        anchor_line_count = case['branch_anchor'].count('\n') + 1
        assert case['branch_anchor'] in '\n'.join(source[case['anchor_line']-1:case['anchor_line']-1+anchor_line_count])
        assert case['proof'] is None
    report = {'schema': 1, 'checkpoint': 'initial-foundations', 'checks_passed': True,
              'verified_rewrite_count': 0, 'rewrite_denominator': None,
              'source_sites': len(inventory['sites']), 'historical_invocations': 118,
              'source_schema_batch_count': len(batch_ids),
              'shape_schema_batch_count': len(shape_ids),
              'scalar_control_schema_batch_count': len(scalar_control['cases']),
              'arithmetic_schema_batch_count': len(arithmetic['cases']),
              'layout_schema_batch_count': len(layout['cases']),
              'collective_rotation_schema_batch_count': len(collective_rotation['cases']),
              'tensor_index_schema_batch_count': len(tensor_index['cases']),
              'reduction_schema_batch_count':len(reduction['cases']),
              'dot_schema_batch_count':len(dot['cases']),
              'convolution_schema_batch_count':len(convolution['cases']),
              'structural_assignment_candidates': len(normalized['assignment_expressions']),
              'full_syntactic_calls':len(full_calls['calls']),
              'full_function_definitions':len(full_calls['functions']),
              'reconciled_handler_records':len(full_calls['handlers']),
              'supplementary_effect_calls':len(effects['calls']),
              'classified_direct_mutable_pointer_writes':len(effects['assignments']),
              'mapped_distinct_replacement_sites': len(
                  {r['site_id'] for r in site_map['bindings'] if r['kind']=='replacement'} |
                  {s['site_id'] for r in site_map['bindings'] for s in r.get('additional_sites',[])}),
              'unmapped_replacement_sites': len(site_map['unmapped_replacement_sites']),
              'noncall_replacement_declarations':len(site_map['noncall_replacement_declarations']),
              'checks': outputs, 'files': []}
    for directory in ('tools', 'tests', 'census'):
        for path in sorted((ROOT / directory).rglob('*')):
            if path.is_file() and '__pycache__' not in path.parts:
                report['files'].append({'path': str(path.relative_to(ROOT)),
                                        'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
    (ROOT / 'reports/initial-checkpoint.json').write_text(json.dumps(report, indent=2)+'\n')
    print('Initial checkpoint validated; complete rewrite census and proof campaign remain open')


if __name__ == '__main__':
    main()
