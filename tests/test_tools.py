import sys
from pathlib import Path
import unittest
import copy

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from replacement_api_paths import load_inputs as load_api_inputs, validate as validate_api_paths
from check_replacement_api_evidence import check_archive as check_api_archive
from check_modular_arithmetic_evidence import check_contract as check_modular_contract, check_archive as check_modular_archive
from check_modular_bridge_evidence import check_contract as check_modular_bridge_contract, check_archive as check_modular_bridge_archive
from check_signed_word_evidence import check_contract as check_signed_contract, check_archive as check_signed_archive
from check_contraction_evidence import check_contract as check_contraction_contract, check_archive as check_contraction_archive, validate_contract as validate_contraction_contract, validate_native as validate_contraction_native
from check_ordered_source_evidence import check_paths, check_compare, validate_paths, validate_compare
from check_scaled_nested_slice_evidence import check_contract as check_scaled_contract, check_archive as check_scaled_archive, validate_partition as validate_scaled_partition, validate_native as validate_scaled_native
from check_reducer_index_evidence import check_contract as check_reducer_index_contract, check_archive as check_reducer_index_archive, validate_profiles as validate_reducer_profiles, validate_native as validate_reducer_native
from source_normalization_registry import build as build_source_normalization, validate_artifact as validate_source_normalization
from check_concatenate_status_evidence import check_archive as check_concat_archive, validate_contract as validate_concat_contract, validate_native as validate_concat_native
from check_dynamic_slice_empty_reshape_evidence import check_archive as check_ds_empty_archive, validate_contract as validate_ds_empty_contract, validate_native as validate_ds_empty_native
from lean_size import count_source
from source_inventory import inventory
from reconcile_sites import validate_map, validate_replacement_coverage
from structural_inventory import extract
from cpp_syntax_view import syntax_view
from build_review_ledger import validate as validate_review_ledger
from extract_scalar_control_cases import validate_batch
from check_empty_slice_replay_evidence import check_archive
from check_scalar_select_replay_evidence import check_archive as check_scalar_archive
from extract_arithmetic_cases import validate_helpers
from extract_layout_cases import validate_effect_evidence
from extract_collective_rotation_cases import validate_site_roles
from extract_tensor_index_cases import validate_loop_mutations, validate_index_effects
from extract_reduction_cases import validate_reduction_batch
from extract_dot_cases import validate_dot_batch
from extract_convolution_cases import validate_convolution_batch
from full_call_inventory import validate as validate_full_calls
from nonreplacement_effects import validate as validate_nonreplacement_effects
from check_boolean_control_family_evidence import check_contract as check_boolean_family_contract, check_archive as check_boolean_family_archive
from check_control_effect_evidence import check_contract as check_effect_contract, check_archive as check_effect_archive
from check_pilot import validate_graph_context
from check_pred_guard_evidence import check_contract as check_guard_contract, check_archive as check_guard_archive
from check_index_map_evidence import check_contract as check_index_contract, check_archive as check_index_archive
from check_dynamic_index_evidence import check_contract as check_dynamic_contract, check_archive as check_dynamic_archive
from check_nested_slice_evidence import check_contract as check_nested_contract, check_archive as check_nested_archive
from check_reshape_evidence import check_contract as check_reshape_contract, check_archive as check_reshape_archive
from check_reduction_evidence import check_contract as check_reduction_contract, check_archive as check_reduction_archive
from extract_typed_ast import documents
from run_typed_ast import ast_arguments, SOURCE as TYPED_SOURCE
from capture_typed_dependencies import dependency_paths
from typed_call_inventory import build as build_typed, validate as validate_typed, source_ranges, callee
from typed_delegation_evidence import load_inputs as load_typed_delegations, build as build_typed_delegations, validate as validate_typed_delegations
from check_dense_layout_evidence import check_contract as check_dense_contract, check_archive as check_dense_archive


class ReplacementApiTests(unittest.TestCase):
    def test_every_static_schema_path_matches_an_independent_call_graph_closure(self):
        import json
        import collections
        root=Path(__file__).resolve().parents[1]
        result=json.loads((root/'census/replacement-api-paths.json').read_text())
        full,typed,mapping=load_api_inputs(root)
        validate_api_paths(result,full,typed,mapping,root=root)
        self.assertEqual(len(result['source_cases']),488)
        self.assertEqual(len(result['api_endpoints']),285)
        self.assertEqual(collections.Counter(e['control_relay'] for e in result['api_endpoints']),
            dict(visitor_always_true=128,default_false=120,explicit_true=5,
                 no_control_relay_in_this_api=29,external_or_construction_boundary=3))
        calls={c['id']:c for c in full['calls']}
        targets={r['source_call_id']:set(r['local_target_function_ids']) for r in typed['source_calls']}
        endpoints={e['source_call_id'] for e in result['api_endpoints']}
        for case in result['source_cases']:
            reached=set().union(*(targets[i] for i in case['entry_call_ids']))
            while True:
                expanded=reached | set().union(*(targets[c['id']] for c in full['calls']
                    if c['owner_function_id'] in reached))
                if expanded==reached:break
                reached=expanded
            self.assertEqual(set(case['reachable_function_ids']),reached)
            expected=endpoints & (set(case['entry_call_ids']) | {c['id'] for c in full['calls']
                if c['owner_function_id'] in reached})
            self.assertEqual(set(case['reachable_endpoint_ids']),expected)
            self.assertTrue(expected)
            self.assertEqual(case['unresolved_entry_call_ids'],[])
            for witness in case['endpoint_witnesses']:
                path=witness['static_call_chain']
                self.assertIn(path[0],case['entry_call_ids'])
                self.assertEqual(path[-1],witness['endpoint_call_id'])
                for parent,child in zip(path,path[1:]):
                    self.assertIn(calls[child]['owner_function_id'],targets[parent])
        self.assertEqual(sum(len(c['endpoint_witnesses']) for c in result['source_cases']),531)

    def test_api_path_omissions_overload_default_changes_and_acceptance_are_rejected(self):
        import json
        root=Path(__file__).resolve().parents[1]
        result=json.loads((root/'census/replacement-api-paths.json').read_text())
        inputs=load_api_inputs(root)
        for mode in ('case','endpoint','default','overload','witness','frontier','contract','acceptance','denominator'):
            changed=copy.deepcopy(result)
            if mode=='case':changed['source_cases'].pop()
            elif mode=='endpoint':changed['api_endpoints'].pop()
            elif mode=='default':next(e for e in changed['api_endpoints'] if e['control_relay']=='default_false')['control_relay']='explicit_true'
            elif mode=='overload':changed['api_endpoints'][0]['selected_declarations'][0]['type']='wrong overload'
            elif mode=='witness':changed['source_cases'][0]['endpoint_witnesses'][0]['static_call_chain']=[]
            elif mode=='frontier':next(f for f in changed['function_summaries'] if f['other_external_or_unresolved_call_ids'])['other_external_or_unresolved_call_ids']=[]
            elif mode=='contract':changed['api_contracts'][0]['source_behavior']='unbounded loop'
            elif mode=='acceptance':changed['source_cases'][0]['accepted_source_proof']='unreviewed'
            else:changed['denominator_frozen']=True
            with self.assertRaises(ValueError):validate_api_paths(changed,*inputs,root=root)

    def test_native_default_relay_outcomes_keep_cap_and_nonreplacement_distinct(self):
        import json
        import shutil
        import tempfile
        root=Path(__file__).resolve().parents[1]
        check_api_archive(root)
        rp=Path('reports/replacement-status-replay-v1/result.json')
        result=json.loads((root/rp).read_text())
        paths=[rp,Path('sources/manifest.json'),
               Path('sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc')]
        paths += [Path(r['path']) for r in result['files']]
        with tempfile.TemporaryDirectory() as directory:
            sandbox=Path(directory)
            for rel in paths:
                (sandbox/rel).parent.mkdir(parents=True,exist_ok=True)
                shutil.copyfile(root/rel,sandbox/rel)
            for mode in ('omission','root','cap','scope'):
                changed=copy.deepcopy(result)
                if mode=='omission':changed['cases'].pop()
                elif mode=='root':next(r for r in changed['cases'] if r['profile']=='predecessor' and r['mode']=='pass')['root_retained']=False
                elif mode=='cap':next(r for r in changed['cases'] if r['profile']=='successor' and r['mode']=='fixedpoint')['delta']=0
                else:changed['execution_scope']='unbounded nontermination proved'
                (sandbox/rp).write_text(json.dumps(changed))
                with self.assertRaises(AssertionError):check_api_archive(sandbox)


class TypedCallTests(unittest.TestCase):
    def test_all_schema_delegations_keep_targets_and_model_scope_pending(self):
        inputs=load_typed_delegations();baseline=build_typed_delegations(*inputs)
        validate_typed_delegations(baseline,*inputs)
        empty=next(r for r in baseline['delegations'] if r['case_id']=='HandleReduce/empty-delegation')
        self.assertEqual(len(empty['related_model_evidence']),2)
        self.assertIsNone(empty['accepted_source_proof'])
        changes=[]
        changed=copy.deepcopy(baseline);changed['delegations']=changed['delegations'][1:];changes.append(changed)
        changed=copy.deepcopy(baseline);changed['delegations'][0]['selected_function_id']='wrong';changes.append(changed)
        changed=copy.deepcopy(baseline)
        row=next(r for r in changed['delegations'] if r['case_id']=='HandleReduce/empty-delegation')
        row['related_model_evidence'][0]['source_rewrite_accepted']=True;changes.append(changed)
        for changed in changes:
            with self.assertRaises(ValueError):validate_typed_delegations(changed,*inputs)

    def fixture(self):
        def function(identity,name,start,end,body=None,previous=None):
            result=dict(id=identity,kind='FunctionDecl',name=name,
                        range=dict(begin=dict(offset=start,file=TYPED_SOURCE,tokLen=1),
                                   end=dict(offset=end-1,tokLen=1)),
                        type={'qualType':'void ()'},inner=[dict(kind='CompoundStmt',inner=body or [])])
            if previous:result['previousDecl']=previous
            return result
        expression=dict(id='call',kind='CallExpr',range=dict(begin=dict(offset=240),end=dict(offset=246,tokLen=1)),
                        inner=[dict(kind='ImplicitCastExpr',inner=[dict(kind='DeclRefExpr',
                            referencedDecl=dict(id='prototype2',kind='FunctionDecl',name='foo',type={'qualType':'void (double)'}))])])
        dependent=copy.deepcopy(expression);dependent['id']='dependent'
        dependent['inner']=[dict(kind='UnresolvedLookupExpr',name='foo',type={'qualType':'<dependent>'})]
        roots=[function('first','foo',0,100),function('second','foo',101,200,previous='prototype2'),
               function('caller','bar',201,400,[expression,dependent])]
        declarations={r['id']:r for r in roots}
        syntax=dict(source_sha256='fixture',functions=[dict(id=i,name=n,byte_start=s,byte_end=e)
            for i,n,s,e in [('f1','foo',0,100),('f2','foo',101,200),('f3','bar',201,400)]],
            calls=[dict(id='source-call',line=10,call='foo',byte_start=240,byte_end=247,
                        owner_function_id='f3',local_definition_candidates=['f1','f2'])])
        return roots,declarations,syntax

    def test_json_documents_preserve_strings_boundaries_and_reject_truncation(self):
        import io
        import json
        values=[{'large':'{\\"}'*400000}, {'id':'next','inner':[{'s':'λ\\\"'}]}]
        stream=io.StringIO('\n'.join(json.dumps(v) for v in values)+'\n')
        self.assertEqual(list(documents(stream)),values)
        with self.assertRaises(json.JSONDecodeError):list(documents(io.StringIO('{"incomplete":')))

    def test_compile_flags_and_dependency_escaping_remain_explicit(self):
        arguments=['wrapper','-DFEATURE=1','-Iinclude','-std=c++20','-c',TYPED_SOURCE,
                   '-o','result.o','-MMD','-MF','result.d','-frandom-seed=output']
        command,removed=ast_arguments(arguments,'clang')
        self.assertTrue(all(flag in command for flag in ('-DFEATURE=1','-Iinclude','-std=c++20',TYPED_SOURCE)))
        self.assertNotIn('result.o',command);self.assertIn('result.o',removed)
        self.assertIn('-ast-dump-filter=xla::',command)
        self.assertEqual(dependency_paths('result.o: a.h \\\n b\\ c.h\n'),['a.h','b c.h'])
        with self.assertRaises(ValueError):dependency_paths('result.o: duplicate.h duplicate.h')

    def test_selected_overload_resolves_prototype_but_retains_dependent_variant(self):
        roots,declarations,syntax=self.fixture()
        result=build_typed(roots,declarations,syntax)
        self.assertEqual(result['source_calls'][0]['local_target_function_ids'],['f2'])
        self.assertEqual(result['source_calls'][0]['typed_bindings'],
                         ['dependent_or_unresolved_expression','selected_function_declaration'])
        self.assertEqual(result['local_call_edges'][0]['selected_function_id'],'f2')
        self.assertEqual(result['unmatched_source_functions'],[])
        validate_typed(result,roots,declarations,syntax)

    def test_typed_alias_target_variant_or_acceptance_tampering_is_rejected(self):
        roots,declarations,syntax=self.fixture();baseline=build_typed(roots,declarations,syntax)
        changes=[]
        changed=copy.deepcopy(baseline);changed['source_calls'][0]['local_target_function_ids']=['f1'];changes.append(changed)
        changed=copy.deepcopy(baseline);changed['typed_variants']=[];changes.append(changed)
        changed=copy.deepcopy(baseline);changed['local_call_edges']=[];changes.append(changed)
        changed=copy.deepcopy(baseline);changed['accepted_source_rewrites']=1;changes.append(changed)
        for changed in changes:
            with self.assertRaises(ValueError):validate_typed(changed,roots,declarations,syntax)

    def test_header_macro_spelling_and_indirect_value_are_not_direct_source_calls(self):
        node=dict(range=dict(begin=dict(expansionLoc=dict(file=TYPED_SOURCE,offset=100),
                                        spellingLoc=dict(file='header.h',offset=1)),
                             end=dict(expansionLoc=dict(file=TYPED_SOURCE,offset=110,tokLen=1),
                                      spellingLoc=dict(file='header.h',offset=5,tokLen=1))))
        self.assertEqual(source_ranges(node),[dict(byte_start=100,byte_end=111,mapping='expansion',explicit_main_file=True)])
        pointer=dict(inner=[dict(kind='DeclRefExpr',referencedDecl=dict(id='pointer',name='fp',kind='VarDecl'))])
        self.assertEqual(callee(pointer,{})['binding'],'indirect_value_callee')


class LeanSizeTests(unittest.TestCase):
    def test_nested_and_mixed_comments(self):
        source = '/- a\n/- nested -/\n-/\ndef x := /- middle -/ 2 -- tail\n\n-- done\n'
        self.assertEqual(count_source(source), {'physical_lines': 6, 'code_lines': 1})

    def test_strings_and_escaped_identifiers(self):
        source = 'def «/- name --» := "-- /- \\""\ndef raw := r##"/- text\n-- still string"##\n'
        self.assertEqual(count_source(source)['code_lines'], 3)

    def test_characters_and_primed_names(self):
        self.assertEqual(count_source("def x' := '\"' -- tail\n#check x'\n")['code_lines'], 2)

    def test_empty_and_comment_only(self):
        self.assertEqual(count_source('')['code_lines'], 0)
        self.assertEqual(count_source('/- only -/\n-- only')['code_lines'], 0)

    def test_invalid_constructs_fail_closed(self):
        for text in ('/- unfinished', 'def x := "open', 'def «open', 'def x := s!"{y}"'):
            with self.assertRaises(ValueError):
                count_source(text)

    def test_compiler_fixture_size(self):
        fixture = Path(__file__).parent / 'fixtures/Lexical.lean'
        self.assertEqual(count_source(fixture.read_text())['code_lines'], 7)


class InventoryTests(unittest.TestCase):
    def test_comments_strings_and_nested_blocks(self):
        source = '''void AlgebraicSimplifierVisitor::HandleX() {
          // ReplaceInstruction(fake);
          auto s = "ReplaceInstruction(fake)";
          if (guard) { ReplaceInstruction(real); }
        }
        void helper() { ReplaceInstruction(other); }
        '''
        data = inventory(source)
        self.assertEqual(len(data['sites']), 2)
        self.assertEqual(data['sites'][0]['owner'], 'HandleX')
        self.assertIsNone(data['sites'][1]['owner'])
        self.assertFalse(data['denominator_frozen'])


class MappingTests(unittest.TestCase):
    def test_convolution_loop_rebind_and_external_effect_omissions(self):
        import json
        root=Path(__file__).resolve().parents[1]
        batch=json.loads((root/'census/convolution-cases.json').read_text())
        structural=json.loads((root/'census/normalized-structural-sites.json').read_text())
        index=json.loads((root/'census/source-sites.json').read_text())
        source=(root/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_text().splitlines()
        validate_convolution_batch(batch,index,source,structural)
        for mode in ('loop','loop-site','rebind','external','external-hash'):
            changed=copy.deepcopy(batch)
            if mode=='loop':changed['cases'][0]['loop_execution']='one write per site'
            elif mode=='loop-site':changed['cases'][0]['additional_replacement_sites'].pop(0)
            elif mode=='rebind':
                next(c for c in changed['cases'] if c['handler']=='PromoteConvolutionToF32IfNotOnednnCompatible').pop('continuing_rebind_anchor')
            elif mode=='external':changed['external_contracts']=[]
            else:changed['external_contracts'][0]['source_body_sha256']='stale'
            with self.assertRaises(ValueError):validate_convolution_batch(changed,index,source,structural)

    def test_overloaded_helpers_and_virtual_scope_fail_closed(self):
        import json
        root=Path(__file__).resolve().parents[1]
        batch=json.loads((root/'census/dot-cases.json').read_text())
        structural=json.loads((root/'census/normalized-structural-sites.json').read_text())
        index=json.loads((root/'census/source-sites.json').read_text())
        source=(root/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_text().splitlines()
        validate_dot_batch(batch,index,source,structural)
        for mode in ('overload','hook','scope','declaration'):
            changed=copy.deepcopy(batch)
            if mode=='overload':
                single=next(c for c in changed['cases'] if c['id']=='ReplaceInstructionIfCompatible/single')
                other=next(c for c in changed['cases'] if c['id']=='ReplaceInstructionIfCompatible/span-tuple')
                for key in ('line','end_line','source_body_sha256'):single[key]=other[key]
            elif mode=='hook':changed['virtual_hook_contract_ids'].pop()
            elif mode=='scope':changed['cases'][0]['visitor_scope']='all backends'
            else:changed['noncall_declaration_site_ids'].pop()
            with self.assertRaises(ValueError):validate_dot_batch(changed,index,source,structural)

    def test_reducer_construction_and_local_lambda_guards_are_retained(self):
        import json
        root=Path(__file__).resolve().parents[1]
        batch=json.loads((root/'census/reduction-cases.json').read_text())
        structural=json.loads((root/'census/normalized-structural-sites.json').read_text())
        index=json.loads((root/'census/source-sites.json').read_text())
        source=(root/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_text().splitlines()
        validate_reduction_batch(batch,index,source,structural)
        for mode in ('clone_role','caller_guard','declaration'):
            changed=copy.deepcopy(batch)
            if mode=='clone_role':
                next(c for c in changed['cases'] if c.get('construction_kind'))['site_roles'][0]['role']='graph_replacement'
            elif mode=='caller_guard':
                next(c for c in changed['cases'] if c['id']=='HandleReduceWindow/empty-tuple').pop('lambda_invocation_anchor')
            else:changed['noncall_declaration_site_ids'].pop()
            with self.assertRaises(ValueError):validate_reduction_batch(changed,index,source,structural)

    def test_index_loop_and_pad_graph_write_omission_controls(self):
        import json
        root=Path(__file__).resolve().parents[1]
        batch=json.loads((root/'census/tensor-index-cases.json').read_text())
        structural=json.loads((root/'census/normalized-structural-sites.json').read_text())
        index=json.loads((root/'census/source-sites.json').read_text())
        source=(root/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_text().splitlines()
        validate_batch(batch,index,source)
        validate_helpers(batch,source)
        validate_loop_mutations(batch,structural)
        validate_index_effects(batch,source,structural)
        changed=copy.deepcopy(batch)
        next(c for c in changed['cases'] if c['id']=='HandleDynamicSlice/nested')['additional_replacement_sites']=[]
        with self.assertRaises(ValueError):validate_loop_mutations(changed,structural)
        changed=copy.deepcopy(structural)
        next(c for c in changed['calls'] if c['line']==8428 and c['call']=='ReplaceOperandWith')['context']=[]
        with self.assertRaises(ValueError):validate_loop_mutations(batch,changed)
        changed=copy.deepcopy(batch)
        next(c for c in changed['cases'] if c['id']=='HandlePad/broadcast-projection')['effect_evidence'].pop(2)
        with self.assertRaises(ValueError):validate_index_effects(changed,source,structural)

    def test_collective_factory_is_not_a_second_replacement(self):
        import json
        root=Path(__file__).resolve().parents[1]
        batch=json.loads((root/'census/collective-rotation-cases.json').read_text())
        structural=json.loads((root/'census/normalized-structural-sites.json').read_text())
        index=json.loads((root/'census/source-sites.json').read_text())
        source=(root/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_text().splitlines()
        validate_batch(batch,index,source)
        validate_helpers(batch,source)
        validate_site_roles(batch,structural)
        changed=copy.deepcopy(batch)
        changed['cases'][0]['site_roles'][1]['role']='graph_replacement'
        with self.assertRaises(ValueError):validate_site_roles(changed,structural)
        changed=copy.deepcopy(structural)
        next(c for c in changed['calls'] if c['line']==1415 and c['call']=='CreateUniformCollectiveReplacement')['byte_end']=10**9
        with self.assertRaises(ValueError):validate_site_roles(batch,changed)

    def test_barrier_shape_and_user_effects_cannot_be_omitted(self):
        import json
        root=Path(__file__).resolve().parents[1]
        batch=json.loads((root/'census/layout-cases.json').read_text())
        index=json.loads((root/'census/source-sites.json').read_text())
        structural=json.loads((root/'census/normalized-structural-sites.json').read_text())
        source=(root/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_text().splitlines()
        validate_batch(batch,index,source)
        validate_helpers(batch,source)
        validate_effect_evidence(batch,source,structural)
        changed=copy.deepcopy(batch)
        next(c for c in changed['cases'] if c['handler']=='HandleOptimizationBarrier')['effect_evidence'].pop()
        with self.assertRaises(ValueError):validate_effect_evidence(changed,source,structural)
        missing=copy.deepcopy(structural)
        missing['assignment_expressions']=[a for a in missing['assignment_expressions'] if a['target']!='*barrier->mutable_shape()']
        with self.assertRaises(ValueError):validate_effect_evidence(batch,source,missing)

    def test_arithmetic_sequence_and_helper_omission_controls(self):
        import json
        root=Path(__file__).resolve().parents[1]
        batch=json.loads((root/'census/arithmetic-cases.json').read_text())
        index=json.loads((root/'census/source-sites.json').read_text())
        source=(root/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_text().splitlines()
        validate_batch(batch,index,source)
        validate_helpers(batch,source)
        changed=copy.deepcopy(batch)
        group=next(c for c in changed['cases'] if c['id']=='HandleAdd/scatter-nested')
        group['additional_replacement_sites'].pop()
        with self.assertRaises(ValueError): validate_batch(changed,index,source)
        for mode in ('missing_helper','stale_body','false_acceptance'):
            changed=copy.deepcopy(batch)
            if mode=='missing_helper':changed['helper_contracts'].pop()
            elif mode=='stale_body':changed['helper_contracts'][0]['source_body_sha256']='stale'
            else:changed['helper_contracts'][0]['status']='proved'
            with self.assertRaises(ValueError):validate_helpers(changed,source)

    def test_shape_coverage_survives_no_silent_residual_transfer(self):
        import json
        root=Path(__file__).resolve().parents[1]
        batch=json.loads((root/'census/shape-cases.json').read_text())
        mapping=json.loads((root/'census/site-case-map.json').read_text())
        index=json.loads((root/'census/source-sites.json').read_text())
        validate_replacement_coverage(batch,mapping,index)
        # Even an otherwise internally consistent map must not silently turn a
        # claimed-covered branch back into an unmapped residual.
        changed=copy.deepcopy(mapping)
        changed['bindings']=[b for b in changed['bindings'] if b['case_id']!='HandleTranspose/space-depth-user-mutation']
        with self.assertRaises(ValueError): validate_replacement_coverage(batch,changed,index)

    def test_scalar_control_identity_omission_and_promotion_controls(self):
        import json
        root=Path(__file__).resolve().parents[1]
        data=json.loads((root/'census/scalar-control-cases.json').read_text())
        index=json.loads((root/'census/source-sites.json').read_text())
        source=(root/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_text().splitlines()
        validate_batch(data,index,source)
        for mode in ('missing_branch','wrong_site','stale_body','acceptance'):
            changed=copy.deepcopy(data)
            if mode=='missing_branch':
                changed['cases']=[c for c in changed['cases'] if c['id']!='HandleSqrt/square-real']
            elif mode=='wrong_site': changed['cases'][0]['replacement_line']+=1
            elif mode=='stale_body': changed['cases'][0]['source_body_sha256']='stale'
            else: changed['cases'][0]['proof']='unreviewed'
            with self.assertRaises(ValueError): validate_batch(changed,index,source)

    def test_actual_mapping_and_tamper_controls(self):
        import json
        root=Path(__file__).resolve().parents[1]
        data=json.loads((root/'census/site-case-map.json').read_text())
        index=json.loads((root/'census/source-sites.json').read_text())
        structural=json.loads((root/'census/normalized-structural-sites.json').read_text())
        cases=[]
        for name in ('simple-cases','shape-cases','scalar-control-cases','arithmetic-cases','layout-cases','collective-rotation-cases','tensor-index-cases','reduction-cases','dot-cases','convolution-cases'):
            cases+=json.loads((root/f'census/{name}.json').read_text())['cases']
        validate_map(data,index,cases,structural)
        for corruption in ('call','missing_case','false_residual'):
            broken=copy.deepcopy(data)
            if corruption=='call': broken['bindings'][0]['call']='InventedReplacement'
            elif corruption=='missing_case': broken['bindings'].pop()
            else: broken['unmapped_replacement_sites'].append(index['sites'][0])
            with self.assertRaises(ValueError): validate_map(broken,index,cases,structural)
        sequence=copy.deepcopy(data)
        binding=next(r for r in sequence['bindings'] if r.get('additional_sites'))
        binding['additional_sites'].pop()
        with self.assertRaises(ValueError): validate_map(sequence,index,cases,structural)
        reordered=copy.deepcopy(data)
        binding=next(r for r in reordered['bindings'] if r['case_id']=='HandleAdd/scatter-nested')
        binding['additional_sites'].reverse()
        with self.assertRaises(ValueError): validate_map(reordered,index,cases,structural)
        changed=copy.deepcopy(data)
        next(r for r in changed['bindings'] if r['case_id']=='HandleAllGather/uniform')['site_roles'][1]['role']='graph_replacement'
        with self.assertRaises(ValueError):validate_map(changed,index,cases,structural)
        changed=copy.deepcopy(data)
        mapped_id=next(r['site_id'] for r in changed['bindings'] if r['kind']=='replacement')
        changed['noncall_replacement_declarations'].append(next(s for s in index['sites'] if s['id']==mapped_id))
        with self.assertRaises(ValueError):validate_map(changed,index,cases,structural)


class StructuralTests(unittest.TestCase):
    def test_all_calls_template_names_and_indirect_callees(self):
        source=b'void f(){ a->SetValue<X>(x); ns::MakeThing<Type>(x); clear_sharding(); Factory()(x); }'
        old=extract(source)
        self.assertEqual(old['calls'],[])
        full=extract(source,capture_all_calls=True)
        self.assertFalse(full['parse_has_errors'])
        self.assertEqual([c['call'] for c in full['calls']],['SetValue','MakeThing','clear_sharding',None,'Factory'])
        self.assertTrue(all(c['kind']=='unclassified_syntactic_call' for c in full['calls']))

    def test_assignment_targets_local_aliases_and_short_circuit(self):
        data=extract(b'void f() { auto p = node; if (ready) { *p->mutable_shape() = shape; p = next; flags[0] |= true; } }')
        self.assertFalse(data['parse_has_errors'])
        writes=data['assignment_expressions']
        self.assertEqual([w['target'] for w in writes],['*p->mutable_shape()','p','flags[0]'])
        self.assertEqual([w['operator'] for w in writes],['=','=','|='])
        self.assertTrue(all(w['context'][0]['branch']=='then' for w in writes))
        self.assertEqual(data['calls'][0]['call'],'mutable_shape')

    def test_macro_assignment_is_source_text_not_claimed_status_semantics(self):
        source=b'void f() { ABSL_ASSIGN_OR_RETURN(value, Compute()); }'
        view,ledger=syntax_view(source)
        data=extract(view,original=source)
        self.assertFalse(data['parse_has_errors'])
        self.assertEqual(len(data['assignment_expressions']),1)
        write=data['assignment_expressions'][0]
        self.assertEqual(write['source'],source[write['byte_start']:write['byte_end']].decode())
        self.assertEqual(ledger[0]['kind'],'assignment_macro_syntax_only')

    def test_macro_view_preserves_locations_and_original_text(self):
        source='// π\nvoid f() { ABSL_ASSIGN_OR_RETURN(auto x, Make(ReplaceInstruction(y))); }'.encode()
        view,ledger=syntax_view(source)
        self.assertEqual(len(view),len(source))
        self.assertEqual(view.count(b'\n'),source.count(b'\n'))
        data=extract(view,original=source)
        self.assertFalse(data['parse_has_errors'])
        self.assertEqual(data['calls'][0]['source'],'ReplaceInstruction(y)')
        self.assertEqual(ledger[0]['kind'],'assignment_macro_syntax_only')

    def test_macro_strings_comments_and_unsupported_arguments(self):
        source=b'// ABSL_ASSIGN_OR_RETURN(fake, call())\nvoid f() { ABSL_ASSIGN_OR_RETURN(x, call(), handler); }'
        view,ledger=syntax_view(source)
        self.assertEqual(view,source)
        self.assertEqual([r['kind'] for r in ledger],['unsupported_macro'])

    def test_parenthesized_declaration(self):
        source=b'void f() { ABSL_ASSIGN_OR_RETURN((Pair<int, int> x), Make()); }'
        view,ledger=syntax_view(source)
        self.assertFalse(extract(view)['parse_has_errors'])
        self.assertEqual(len(ledger),1)

    def test_short_circuit_condition_is_not_success_branch(self):
        data=extract(b'void f() { if (guard && ReplaceInstruction(x)) { Mark(); } }')
        self.assertFalse(data['parse_has_errors'])
        call=data['calls'][0]
        self.assertEqual(call['context'][0]['branch'],'condition_evaluation')
        self.assertEqual(call['context'][1]['expression'],'guard')
        self.assertTrue(call['context'][1]['required_value'])

    def test_else_and_or_context(self):
        data=extract(b'void f() { if (ready) {} else { if (skip || ReplaceInstruction(x)) {} } }')
        context=data['calls'][0]['context']
        self.assertEqual(context[0]['branch'],'else')
        self.assertFalse(context[-1]['required_value'])

    def test_definition_is_not_call(self):
        data=extract(b'void ReplaceInstruction(int x) { /* ReplaceInstruction(fake); */ }')
        self.assertEqual(data['calls'],[])
        self.assertEqual(len(data['functions']),1)

    def test_malformed_source_is_explicit(self):
        data=extract(b'void f( { ReplaceInstruction(x);')
        self.assertTrue(data['parse_has_errors'])
        self.assertTrue(data['errors'])


class ReviewLedgerTests(unittest.TestCase):
    def test_graph_model_cannot_be_promoted_or_cross_mapped(self):
        import json
        root=Path(__file__).resolve().parents[1]
        proofs=json.loads((root/'census/pilot-value-proofs.json').read_text())
        graph=proofs['graph_context']
        validate_graph_context(graph,proofs['rules'])
        for mode in ('omission','source_acceptance','scope','self_equivalence','source_mapping'):
            changed=copy.deepcopy(graph)
            if mode=='omission':changed['rules'].pop()
            elif mode=='source_acceptance':changed['accepted_source_rewrites']=12
            elif mode=='scope':changed['semantic_track']='all_xla'
            elif mode=='self_equivalence':next(r for r in changed['rules'] if r['source_case']=='HandleXor/equal-inputs')['source_partition']='PRED pure same-shape dataflow only'
            else:changed['rules'][0]['theorem'],changed['rules'][1]['theorem']=changed['rules'][1]['theorem'],changed['rules'][0]['theorem']
            with self.assertRaises(ValueError):validate_graph_context(changed,proofs['rules'])

    def test_full_call_handler_dispatch_and_provenance_controls(self):
        import json
        root=Path(__file__).resolve().parents[1]
        full=json.loads((root/'census/full-call-inventory.json').read_text())
        structural=json.loads((root/'census/normalized-structural-sites.json').read_text())
        index=json.loads((root/'census/source-sites.json').read_text())
        mapping=json.loads((root/'census/site-case-map.json').read_text())
        data=(root/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_bytes()
        validate_full_calls(full,data,structural,index,mapping)
        for mode in ('uncaptured_call','overload','dispatch','handler','macro'):
            changed=copy.deepcopy(full)
            if mode=='uncaptured_call':
                changed['calls']=[c for c in changed['calls'] if c['call']!='clear_sharding']
            elif mode=='overload':next(c for c in changed['calls'] if len(c['local_definition_candidates'])>1)['local_definition_candidates'].pop()
            elif mode=='dispatch':changed['calls'][0]['local_dispatch_status']='resolved'
            elif mode=='handler':changed['handlers'][0]['all_call_ids'].pop()
            else:next(c for c in changed['calls'] if c['overlapping_syntax_rewrites'])['overlapping_syntax_rewrites']=[]
            with self.assertRaises(ValueError):validate_full_calls(changed,data,structural,index,mapping)

    def test_nonreplacement_effect_and_existing_node_classification_controls(self):
        import json
        root=Path(__file__).resolve().parents[1]
        full=json.loads((root/'census/full-call-inventory.json').read_text())
        structural=json.loads((root/'census/normalized-structural-sites.json').read_text())
        mapping=json.loads((root/'census/site-case-map.json').read_text())
        effects=json.loads((root/'census/nonreplacement-effects.json').read_text())
        validate_nonreplacement_effects(effects,full,structural,mapping)
        for mode in ('recovery','pointer','rng','contract','case_scope','acceptance'):
            changed=copy.deepcopy(effects)
            if mode=='recovery':changed['calls']=[c for c in changed['calls'] if c['call']!='AddRecoveryComputation']
            elif mode=='pointer':changed['assignments'].pop()
            elif mode=='rng':next(a for a in changed['assignments'] if a['classification']=='existing_rng_shape')['classification']='new_instruction_shape'
            elif mode=='contract':changed['contracts'].pop()
            elif mode=='case_scope':changed['calls'][0]['case_link_status']='exact_branch'
            else:changed['assignments'][0]['accepted_source_proof']='unreviewed'
            with self.assertRaises(ValueError):validate_nonreplacement_effects(changed,full,structural,mapping)

    def test_actual_ledger_and_omission_identity_controls(self):
        import json
        root=Path(__file__).resolve().parents[1]
        ledger=json.loads((root/'census/review-ledger.json').read_text())
        structural=json.loads((root/'census/normalized-structural-sites.json').read_text())
        proofs=json.loads((root/'census/pilot-value-proofs.json').read_text())
        validate_review_ledger(ledger,structural,proofs)
        for mode in ('omission','identity','acceptance'):
            changed=copy.deepcopy(ledger)
            if mode=='omission': changed['candidate_calls'].pop()
            elif mode=='identity': changed['candidate_calls'][0]['source']='fabricated()'
            else: changed['candidate_calls'][0]['accepted_source_proof']='invented_proof'
            with self.assertRaises(ValueError): validate_review_ledger(changed,structural,proofs)
        for mode in ('assignment_omission','assignment_identity','assignment_acceptance'):
            changed=copy.deepcopy(ledger)
            if mode=='assignment_omission':changed['assignment_candidates'].pop()
            elif mode=='assignment_identity':changed['assignment_candidates'][0]['target']='invented_pointer'
            else:changed['assignment_candidates'][0]['accepted_source_proof']='invented_proof'
            with self.assertRaises(ValueError):validate_review_ledger(changed,structural,proofs)
        changed=copy.deepcopy(ledger)
        next(a for a in changed['assignment_candidates'] if a['overlapping_syntax_rewrites'])['overlapping_syntax_rewrites']=[]
        with self.assertRaises(ValueError):validate_review_ledger(changed,structural,proofs)

        changed=copy.deepcopy(ledger)
        next(c for c in changed['candidate_calls'] if c['related_graph_context_evidence'])['related_graph_context_evidence']=[]
        with self.assertRaises(ValueError):validate_review_ledger(changed,structural,proofs)
        for field in ('related_effectful_graph_evidence','related_control_order_diagnostics'):
            changed=copy.deepcopy(ledger)
            next(c for c in changed['candidate_calls'] if c[field])[field]=[]
            with self.assertRaises(ValueError):validate_review_ledger(changed,structural,proofs)


class EmptySliceEvidenceTests(unittest.TestCase):
    def test_dense_cell_proof_and_tiled_policy_diagnostic_cannot_be_merged(self):
        import json
        import shutil
        import tempfile
        root=Path(__file__).resolve().parents[1]
        check_dense_contract(root);check_dense_archive(root)
        cp=Path('census/dense-layout-contract.json');rp=Path('reports/transpose-bitcast-replay-v2/result.json')
        mp=Path('reports/pilot-values.json');manifest_path=Path('sources/layout-storage-contract-manifest.json')
        contract=json.loads((root/cp).read_text());result=json.loads((root/rp).read_text())
        manifest=json.loads((root/manifest_path).read_text())
        paths=[cp,rp,mp,manifest_path,Path('sources/manifest.json'),Path('census/pilot-value-proofs.json'),Path('census/shape-cases.json')]
        paths += [Path(r['path']) for r in result['files']+contract['contracts']+manifest['files']]
        with tempfile.TemporaryDirectory() as directory:
            sandbox=Path(directory)
            for rel in paths:
                (sandbox/rel).parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(root/rel,sandbox/rel)
            check_dense_contract(sandbox);check_dense_archive(sandbox)
            changed=copy.deepcopy(contract);changed['profile']='all tiled/packed backend layouts'
            (sandbox/cp).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_dense_contract(sandbox)
            changed=copy.deepcopy(contract);changed['tiled_diagnostic_is_lean_refutation']=True
            (sandbox/cp).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_dense_contract(sandbox)
            changed=copy.deepcopy(result);changed['tiled_boundary']['operator_evaluation']=True
            (sandbox/rp).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_dense_archive(sandbox)
            (sandbox/rp).write_text(json.dumps(result))
            changed=json.loads((root/mp).read_text())
            changed['checks']['dense_layout_controls']['stdout']=changed['checks']['dense_layout_controls']['stdout'].replace('guards=true,false,true','guards=true,true,true')
            (sandbox/mp).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_dense_archive(sandbox)

    def test_signed_promotion_intermediate_width_observation_and_scope_are_checked(self):
        import json
        import shutil
        import tempfile
        root=Path(__file__).resolve().parents[1]
        check_signed_contract(root);check_signed_archive(root)
        cp=Path('census/signed-word-contract.json');mp=Path('reports/pilot-values.json')
        rp=Path('reports/signed-word-replay-v2/result.json')
        contract=json.loads((root/cp).read_text());result=json.loads((root/rp).read_text())
        manifest=json.loads((root/contract['manifest']).read_text())
        paths=[cp,rp,mp,Path(contract['manifest']),Path('sources/manifest.json'),
               Path('census/pilot-value-proofs.json'),Path('census/simple-cases.json'),Path('census/arithmetic-cases.json'),
               Path('sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc')]
        paths += [Path(r['path']) for r in result['files']+contract['contracts']+manifest['files']]
        prior=Path('reports/signed-word-replay-v1/result.json')
        paths += [prior]+[Path(r['path']) for r in json.loads((root/prior).read_text())['files']]
        with tempfile.TemporaryDirectory() as directory:
            sandbox=Path(directory)
            for rel in paths:
                (sandbox/rel).parent.mkdir(parents=True,exist_ok=True)
                shutil.copyfile(root/rel,sandbox/rel)
            for mode in ('promotion','negate','acceptance','source_review'):
                changed=copy.deepcopy(contract)
                if mode=='promotion':changed['source_dtype_profiles'][0]['binary_intermediate_width']=8
                elif mode=='negate':changed['source_dtype_profiles'][0]['negate_unsigned_width']=64
                elif mode=='acceptance':changed['accepted_source_rewrites']=33
                else:changed['source_correspondence_reviewed']=True
                (sandbox/cp).write_text(json.dumps(changed))
                with self.assertRaises(AssertionError):check_signed_contract(sandbox)
            (sandbox/cp).write_text(json.dumps(contract))
            for mode in ('signed_value','raw_value','omission'):
                changed=copy.deepcopy(result)
                if mode=='signed_value':changed['cases'][0]['signed_values'][1]=128
                elif mode=='raw_value':changed['cases'][0]['values'][1]=0
                else:changed['cases'].pop()
                (sandbox/rp).write_text(json.dumps(changed))
                with self.assertRaises(AssertionError):check_signed_archive(sandbox)
            (sandbox/rp).write_text(json.dumps(result))
            changed=json.loads((root/mp).read_text())
            changed['checks']['signed_word_controls']['stdout']=changed['checks']['signed_word_controls']['stdout'].replace('signed=-127,-126,1,-125,-128,2','signed=129,130,1,131,128,2')
            (sandbox/mp).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_signed_archive(sandbox)

    def test_modular_bridge_scope_orientations_guards_and_axis_values_cannot_be_erased(self):
        import json
        import shutil
        import tempfile
        root=Path(__file__).resolve().parents[1]
        check_modular_bridge_contract(root);check_modular_bridge_archive(root)
        cp=Path('census/modular-bridge-contract.json')
        rp=Path('reports/modular-bridge-replay-v2/result.json')
        mp=Path('reports/pilot-values.json')
        contract=json.loads((root/cp).read_text());result=json.loads((root/rp).read_text())
        paths=[cp,rp,mp,Path('sources/manifest.json'),Path('census/pilot-value-proofs.json'),
               Path('census/simple-cases.json'),Path('census/arithmetic-cases.json')]
        paths += [Path(r['path']) for r in result['files']+contract['contracts']]
        failed_path=Path('reports/modular-bridge-replay-v1/result.json')
        paths += [failed_path]+[Path(r['path']) for r in json.loads((root/failed_path).read_text())['files']]
        with tempfile.TemporaryDirectory() as directory:
            sandbox=Path(directory)
            for rel in paths:
                (sandbox/rel).parent.mkdir(parents=True,exist_ok=True)
                shutil.copyfile(root/rel,sandbox/rel)
            for key,value in [('accepted_source_rewrites',7),('source_matcher_extraction_proved',True),
                              ('graph_API_correspondence_proved',True),('rules',contract['rules'][:-1])]:
                changed=copy.deepcopy(contract);changed[key]=value
                (sandbox/cp).write_text(json.dumps(changed))
                with self.assertRaises(AssertionError):check_modular_bridge_contract(sandbox)
            (sandbox/cp).write_text(json.dumps(contract))
            for mode in ('orientation','guard','axis'):
                changed=copy.deepcopy(result)
                if mode=='orientation':changed['cases']=[r for r in changed['cases'] if r['name']!='four_111']
                elif mode=='guard':next(r for r in changed['cases'] if r['name']=='guard_vector_constant' and r['mode']=='handler')['changed']=True
                else:next(r for r in changed['cases'] if r['name']=='move_1_00')['values']=[0,254,250,0]
                (sandbox/rp).write_text(json.dumps(changed))
                with self.assertRaises(AssertionError):check_modular_bridge_archive(sandbox)
            (sandbox/rp).write_text(json.dumps(result))
            changed=json.loads((root/mp).read_text())
            changed['checks']['modular_bridge_controls']['stdout']=changed['checks']['modular_bridge_controls']['stdout'].replace('case=move_1_00 values=0,6,2,0','case=move_1_00 values=0,254,250,0')
            (sandbox/mp).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_modular_bridge_archive(sandbox)

    def test_modular_values_cannot_be_promoted_to_float_graph_or_unbounded_decoding(self):
        import json
        import shutil
        import tempfile
        root=Path(__file__).resolve().parents[1]
        check_modular_contract(root);check_modular_archive(root)
        cp=Path('census/modular-arithmetic-contract.json')
        rp=Path('reports/modular-arithmetic-replay-v1/result.json')
        mp=Path('reports/pilot-values.json')
        contract=json.loads((root/cp).read_text());result=json.loads((root/rp).read_text())
        paths=[cp,rp,mp,Path('sources/manifest.json'),Path('census/pilot-value-proofs.json'),
               Path('census/simple-cases.json'),Path('census/arithmetic-cases.json')]
        paths += [Path(r['path']) for r in result['files']+contract['contracts']]
        with tempfile.TemporaryDirectory() as directory:
            sandbox=Path(directory)
            for rel in paths:
                (sandbox/rel).parent.mkdir(parents=True,exist_ok=True)
                shutil.copyfile(root/rel,sandbox/rel)
            for key,value in [('profile','unbounded integers or floating point'),('accepted_source_rewrites',16),
                              ('source_correspondence_reviewed',True),('rules',contract['rules'][:-1])]:
                changed=copy.deepcopy(contract);changed[key]=value
                (sandbox/cp).write_text(json.dumps(changed))
                with self.assertRaises(AssertionError):check_modular_contract(sandbox)
            (sandbox/cp).write_text(json.dumps(contract))
            for mode in ('omission','overflow','execution'):
                changed=copy.deepcopy(result)
                if mode=='omission':changed['cases'].pop()
                elif mode=='overflow':changed['cases'][3]['values'][2]=257
                else:changed['execution_scope']='all signed/float graphs verified'
                (sandbox/rp).write_text(json.dumps(changed))
                with self.assertRaises(AssertionError):check_modular_archive(sandbox)
            (sandbox/rp).write_text(json.dumps(result))
            changed=json.loads((root/mp).read_text())
            changed['checks']['modular_arithmetic_controls']['stdout']=changed['checks']['modular_arithmetic_controls']['stdout'].replace('2,3,1,130,0,5','2,3,257,130,256,5')
            (sandbox/mp).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_modular_archive(sandbox)

    def test_boolean_family_diagnosis_retains_guards_modes_and_test_only_repair(self):
        import json
        import shutil
        import tempfile
        root=Path(__file__).resolve().parents[1]
        check_boolean_family_contract(root);check_boolean_family_archive(root)
        cp=Path('census/boolean-control-family-contract.json')
        rp=Path('reports/boolean-control-family-replay-v3/result.json')
        mp=Path('reports/pilot-values.json')
        contract=json.loads((root/cp).read_text());result=json.loads((root/rp).read_text())
        paths=[cp,rp,mp,Path('sources/manifest.json'),Path('census/pilot-value-proofs.json'),
               Path('census/simple-cases.json'),Path('sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc')]
        paths += [Path(r['path']) for r in result['files']]
        for number in (1,2):
            path=Path('reports/boolean-control-family-replay-v'+str(number)+'/result.json')
            paths.append(path)
            paths += [Path(r['path']) for r in json.loads((root/path).read_text())['files']]
        with tempfile.TemporaryDirectory() as directory:
            sandbox=Path(directory)
            for rel in paths:
                (sandbox/rel).parent.mkdir(parents=True,exist_ok=True)
                shutil.copyfile(root/rel,sandbox/rel)
            for key,value in [('accepted_source_rewrites',12),('all_schedule_refinement_proved',True),
                              ('repair_scope','canonical pass repaired'),('source_cases',contract['source_cases'][:-1])]:
                changed=copy.deepcopy(contract);changed[key]=value
                (sandbox/cp).write_text(json.dumps(changed))
                with self.assertRaises(AssertionError):check_boolean_family_contract(sandbox)
            (sandbox/cp).write_text(json.dumps(contract))
            for key,value in [('cases',result['cases'][:-1]),('execution_scope','compiled backend')]:
                changed=copy.deepcopy(result);changed[key]=value
                (sandbox/rp).write_text(json.dumps(changed))
                with self.assertRaises(AssertionError):check_boolean_family_archive(sandbox)
            (sandbox/rp).write_text(json.dumps(result))
            changed=json.loads((root/mp).read_text())
            changed['checks']['control_repair_controls']['stdout']=changed['checks']['control_repair_controls']['stdout'].replace('reverse_after=false','reverse_after=true')
            (sandbox/mp).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_boolean_family_archive(sandbox)

    def test_effectful_proof_scope_and_native_order_witness_cannot_be_promoted(self):
        import json
        import shutil
        import tempfile
        root=Path(__file__).resolve().parents[1]
        check_effect_contract(root);check_effect_archive(root)
        cp=Path('census/effectful-graph-contract.json')
        rp=Path('reports/control-order-replay-v1/result.json')
        mp=Path('reports/pilot-values.json')
        manifest_path=Path('sources/control-effects-contract-manifest.json')
        contract=json.loads((root/cp).read_text());result=json.loads((root/rp).read_text())
        manifest=json.loads((root/manifest_path).read_text())
        paths=[cp,rp,mp,manifest_path,Path('sources/manifest.json'),Path('census/pilot-value-proofs.json')]
        paths += [Path(r['path']) for r in result['files']+contract['contracts']+manifest['files']]
        with tempfile.TemporaryDirectory() as directory:
            sandbox=Path(directory)
            for rel in paths:
                (sandbox/rel).parent.mkdir(parents=True,exist_ok=True)
                shutil.copyfile(root/rel,sandbox/rel)
            for key,value in [('accepted_source_rewrites',12),('all_schedule_refinement_proved',True),
                              ('production_backend_executed',True),('source_case','HandleAnd/rhs-one')]:
                changed=copy.deepcopy(contract);changed[key]=value
                (sandbox/cp).write_text(json.dumps(changed))
                with self.assertRaises(AssertionError):check_effect_contract(sandbox)
            (sandbox/cp).write_text(json.dumps(contract))
            for key,value in [('execution_scope','production compiled backend'),('native_schedule_verified',False),
                              ('cases',result['cases'][1:])]:
                changed=copy.deepcopy(result);changed[key]=value
                (sandbox/rp).write_text(json.dumps(changed))
                with self.assertRaises(AssertionError):check_effect_archive(sandbox)
            (sandbox/rp).write_text(json.dumps(result))
            changed=json.loads((root/mp).read_text())
            changed['checks']['effectful_dag_controls']['stdout']=changed['checks']['effectful_dag_controls']['stdout'].replace('[7, 0, 0, 9]','[]')
            (sandbox/mp).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_effect_archive(sandbox)

    def test_reduction_identity_law_and_semantic_domain_cannot_be_erased(self):
        import json
        import shutil
        import tempfile
        root=Path(__file__).resolve().parents[1]
        check_reduction_contract(root);check_reduction_archive(root)
        cp=Path('census/reduction-logical-contract.json');rp=Path('reports/reduction-replay-v1/result.json')
        mp=Path('reports/pilot-values.json')
        contract=json.loads((root/cp).read_text());result=json.loads((root/rp).read_text())
        paths=[cp,rp,mp,Path('sources/manifest.json'),Path('census/pilot-value-proofs.json'),
               Path('census/reduction-cases.json')]
        paths += [Path(r['path']) for r in result['files']+contract['contracts']]
        with tempfile.TemporaryDirectory() as directory:
            sandbox=Path(directory)
            for rel in paths:
                (sandbox/rel).parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(root/rel,sandbox/rel)
            check_reduction_contract(sandbox);check_reduction_archive(sandbox)
            changed=copy.deepcopy(contract);changed['invalid_identity_case_is_source_counterexample']=True
            (sandbox/cp).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_reduction_contract(sandbox)
            changed=copy.deepcopy(contract);changed['rules'][2]['source_partition']='equal counts suffice without initializer law'
            (sandbox/cp).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_reduction_contract(sandbox)
            changed=copy.deepcopy(result);changed['cases']=[c for c in changed['cases'] if c['identity_law']]
            (sandbox/rp).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_reduction_archive(sandbox)
            (sandbox/rp).write_text(json.dumps(result))
            changed=json.loads((root/mp).read_text())
            changed['checks']['reduction_controls']['stdout']=changed['checks']['reduction_controls']['stdout'].replace('nontrivial_axes values=0,0,1','nontrivial_axes values=1,1,1')
            (sandbox/mp).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_reduction_archive(sandbox)

    def test_reshape_rank_layout_and_execution_scope_cannot_be_broadened(self):
        import json
        import shutil
        import tempfile
        root=Path(__file__).resolve().parents[1]
        check_reshape_contract(root);check_reshape_archive(root)
        cp=Path('census/reshape-contract.json');rp=Path('reports/reshape-replay-v3/result.json')
        mp=Path('reports/pilot-values.json')
        contract=json.loads((root/cp).read_text());result=json.loads((root/rp).read_text())
        paths=[cp,rp,mp,Path('sources/manifest.json'),Path('census/pilot-value-proofs.json'),
               Path('census/shape-cases.json')]
        paths += [Path(r['path']) for r in result['files']+contract['contracts']]
        with tempfile.TemporaryDirectory() as directory:
            sandbox=Path(directory)
            for rel in paths:
                (sandbox/rel).parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(root/rel,sandbox/rel)
            check_reshape_contract(sandbox);check_reshape_archive(sandbox)
            changed=copy.deepcopy(contract);changed['profile']='all physical layouts and dynamic shapes'
            (sandbox/cp).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_reshape_contract(sandbox)
            changed=copy.deepcopy(contract);changed['accepted_source_rewrites']=3
            (sandbox/cp).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_reshape_contract(sandbox)
            changed=copy.deepcopy(result);changed['cases']=[c for c in changed['cases'] if c['mode']!='handler']
            (sandbox/rp).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_reshape_archive(sandbox)
            (sandbox/rp).write_text(json.dumps(result))
            changed=json.loads((root/mp).read_text())
            changed['checks']['reshape_controls']['stdout']=changed['checks']['reshape_controls']['stdout'].replace('values=0,1,2,3,4,5','values=0,3,1,4,2,5')
            (sandbox/mp).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_reshape_archive(sandbox)

    def test_nested_slice_contract_and_no_pass_controls_cannot_be_promoted(self):
        import json
        import shutil
        import tempfile
        root=Path(__file__).resolve().parents[1]
        check_nested_contract(root);check_nested_archive(root)
        cp=Path('census/nested-slice-contract.json');rp=Path('reports/nested-slice-replay-v2/result.json')
        mp=Path('reports/pilot-values.json')
        contract=json.loads((root/cp).read_text());result=json.loads((root/rp).read_text())
        paths=[cp,rp,mp,Path('sources/manifest.json'),Path('census/pilot-value-proofs.json'),
               Path('census/tensor-index-cases.json'),Path(contract['source_contract']['path'])]
        paths += [Path(f['path']) for f in result['files']]
        with tempfile.TemporaryDirectory() as directory:
            sandbox=Path(directory)
            for rel in paths:
                (sandbox/rel).parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(root/rel,sandbox/rel)
            check_nested_contract(sandbox);check_nested_archive(sandbox)
            changed=copy.deepcopy(contract);changed['accepted_source_rewrites']=1
            (sandbox/cp).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_nested_contract(sandbox)
            changed=copy.deepcopy(contract);changed['evaluator_profile']='all production backends'
            (sandbox/cp).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_nested_contract(sandbox)
            changed=copy.deepcopy(result);changed['cases']=[c for c in changed['cases'] if c['run_pass']]
            (sandbox/rp).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_nested_archive(sandbox)
            (sandbox/rp).write_text(json.dumps(result))
            changed=json.loads((root/mp).read_text())
            changed['checks']['nested_slice_controls']['stdout']=changed['checks']['nested_slice_controls']['stdout'].replace('after=5,5,8','after=1,1,0')
            (sandbox/mp).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_nested_archive(sandbox)

    def test_dynamic_unsigned_oracle_disagreement_cannot_be_erased_or_promoted(self):
        import json
        import shutil
        import tempfile
        root=Path(__file__).resolve().parents[1]
        check_dynamic_contract(root);check_dynamic_archive(root)
        cp=Path('census/dynamic-index-contract.json');rp=Path('reports/dynamic-index-evaluator-v1/result.json')
        mp=Path('reports/pilot-values.json')
        contract=json.loads((root/cp).read_text());result=json.loads((root/rp).read_text());model=json.loads((root/mp).read_text())
        manifest_path=Path('sources/dynamic-index-contract-manifest.json')
        manifest=json.loads((root/manifest_path).read_text())
        paths=[cp,rp,mp,manifest_path,Path('sources/manifest.json'),Path('census/pilot-value-proofs.json'),
               Path('sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc')]
        paths += [Path(f['path']) for f in result['files']+manifest['files']+contract['source_contracts']]
        with tempfile.TemporaryDirectory() as directory:
            sandbox=Path(directory)
            for rel in paths:
                (sandbox/rel).parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(root/rel,sandbox/rel)
            check_dynamic_contract(sandbox);check_dynamic_archive(sandbox)
            changed=copy.deepcopy(result);changed['profile_disagreements']=[]
            (sandbox/rp).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_dynamic_archive(sandbox)
            changed=copy.deepcopy(result);changed['xla_full_pass_run']=True
            (sandbox/rp).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_dynamic_archive(sandbox)
            (sandbox/rp).write_text(json.dumps(result))
            changed=copy.deepcopy(model)
            changed['checks']['dynamic_index_controls']['stdout']=changed['checks']['dynamic_index_controls']['stdout'].replace('u64_logical=0,1,3,3,3','u64_logical=0,1,3,0,0')
            (sandbox/mp).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_dynamic_archive(sandbox)
            changed=copy.deepcopy(contract);changed['accepted_source_rewrites']=1
            (sandbox/cp).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_dynamic_contract(sandbox)

    def test_index_map_model_coordinates_and_native_scope_controls(self):
        import json
        import shutil
        import tempfile
        root=Path(__file__).resolve().parents[1]
        check_index_contract(root)
        check_index_archive(root)
        contract_path=Path('census/concrete-index-contract.json')
        report_path=Path('reports/index-map-evaluator-v1/result.json')
        model_path=Path('reports/pilot-values.json')
        contract=json.loads((root/contract_path).read_text())
        result=json.loads((root/report_path).read_text())
        model=json.loads((root/model_path).read_text())
        paths=[contract_path,report_path,model_path,Path('sources/manifest.json'),
               Path('census/pilot-value-proofs.json'),
               Path('sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc')]
        paths += [Path(f['path']) for f in result['files']+contract['contracts']]
        with tempfile.TemporaryDirectory() as directory:
            sandbox=Path(directory)
            for rel in paths:
                (sandbox/rel).parent.mkdir(parents=True,exist_ok=True)
                shutil.copyfile(root/rel,sandbox/rel)
            check_index_contract(sandbox);check_index_archive(sandbox)
            changed=copy.deepcopy(result);changed['xla_full_pass_run']=True
            (sandbox/report_path).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_index_archive(sandbox)
            (sandbox/report_path).write_text(json.dumps(result))
            changed=copy.deepcopy(model)
            changed['checks']['index_map_controls']['stdout']=changed['checks']['index_map_controls']['stdout'].replace('9,12,23,26,37,40','9,12,23,26,37,39')
            (sandbox/model_path).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_index_archive(sandbox)
            changed=copy.deepcopy(contract);changed['profile']='all_dynamic_and_machine_indices'
            (sandbox/contract_path).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_index_contract(sandbox)

    def test_pred_guard_wrapper_omission_and_execution_scope_controls(self):
        import json
        import shutil
        import tempfile
        root=Path(__file__).resolve().parents[1]
        check_guard_contract(root)
        check_guard_archive(root)
        contract_path=Path('census/pred-guard-contract.json')
        report_path=Path('reports/pred-guard-replay-v1/result.json')
        contract=json.loads((root/contract_path).read_text())
        result=json.loads((root/report_path).read_text())
        manifest_path=Path('sources/constant-guard-contract-manifest.json')
        manifest=json.loads((root/manifest_path).read_text())
        paths=[contract_path,report_path,manifest_path,Path('sources/manifest.json'),
               Path('sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc'),
               Path('census/full-call-inventory.json'),Path('census/pilot-value-proofs.json'),
               Path('TensorRewrite/Pilot/ConstantGuard.lean')]
        paths += [Path(f['path']) for f in result['files']+manifest['files']]
        with tempfile.TemporaryDirectory() as directory:
            sandbox=Path(directory)
            for rel in paths:
                (sandbox/rel).parent.mkdir(parents=True,exist_ok=True)
                shutil.copyfile(root/rel,sandbox/rel)
            check_guard_contract(sandbox)
            check_guard_archive(sandbox)
            changed=copy.deepcopy(contract)
            changed['source_wrapper_whitelist'].remove('DynamicSlice')
            (sandbox/contract_path).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_guard_contract(sandbox)
            (sandbox/contract_path).write_text(json.dumps(contract))
            changed=copy.deepcopy(result);changed['xla_full_pass_run']=True
            (sandbox/report_path).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_guard_archive(sandbox)
            changed=copy.deepcopy(result)
            next(c for c in changed['cases'] if c['wrapper']=='opaque_not')['changed']=True
            (sandbox/report_path).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_guard_archive(sandbox)
            model_path=Path('TensorRewrite/Pilot/ConstantGuard.lean')
            model=(sandbox/model_path).read_text().replace('  | transpose\n','  | transpose\n  | logicalNot\n')
            (sandbox/model_path).write_text(model)
            with self.assertRaises(AssertionError):check_guard_contract(sandbox)

    def test_scalar_select_disabled_control_omission_and_false_equality_rejected(self):
        import hashlib
        import json
        import shutil
        import tempfile
        root=Path(__file__).resolve().parents[1]
        check_scalar_archive(root)
        report=Path('reports/scalar-select-replay-v2/result.json')
        result=json.loads((root/report).read_text())
        paths=[report,Path('sources/manifest.json'),
               Path('sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc')]
        paths += [Path(item['path']) for item in result['files']]
        with tempfile.TemporaryDirectory() as directory:
            sandbox=Path(directory)
            for rel in paths:
                (sandbox/rel).parent.mkdir(parents=True,exist_ok=True)
                shutil.copyfile(root/rel,sandbox/rel)
            check_scalar_archive(sandbox)
            changed=copy.deepcopy(result)
            changed['cases'][-1]['after']=changed['cases'][-1]['before']
            (sandbox/report).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_scalar_archive(sandbox)
            changed=copy.deepcopy(result)
            logpath=report.parent/'test.log'
            log=(sandbox/logpath).read_text().replace('SCALAR_SELECT_RESULT enabled=0 predicate=0','OMITTED_CONTROL enabled=0 predicate=0')
            (sandbox/logpath).write_text(log)
            next(f for f in changed['files'] if f['path']==str(logpath))['sha256']=hashlib.sha256(log.encode()).hexdigest()
            (sandbox/report).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError):check_scalar_archive(sandbox)

    def test_success_claim_and_omitted_witness_fail_even_with_updated_hash(self):
        import hashlib
        import json
        import shutil
        import tempfile
        root=Path(__file__).resolve().parents[1]
        check_archive(root)
        report=Path('reports/empty-slice-replay-v2/result.json')
        result=json.loads((root/report).read_text())
        manifest=Path('sources/indexing-contract-manifest.json')
        contracts=json.loads((root/manifest).read_text())
        paths=[report,manifest,Path('sources/manifest.json'),
               Path('sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc')]
        paths += [Path(item['path']) for item in result['files']+contracts['files']]
        with tempfile.TemporaryDirectory() as directory:
            sandbox=Path(directory)
            for rel in paths:
                (sandbox/rel).parent.mkdir(parents=True,exist_ok=True)
                shutil.copyfile(root/rel,sandbox/rel)
            check_archive(sandbox)
            changed=copy.deepcopy(result)
            changed['cases'][0]['rewritten_verified']=True
            (sandbox/report).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError): check_archive(sandbox)
            changed=copy.deepcopy(result)
            logpath=report.parent/'test.log'
            log=(sandbox/logpath).read_text().replace('EMPTY_SLICE_RESULT reversed=1','OMITTED_RESULT reversed=1')
            (sandbox/logpath).write_text(log)
            next(f for f in changed['files'] if f['path']==str(logpath))['sha256']=hashlib.sha256(log.encode()).hexdigest()
            (sandbox/report).write_text(json.dumps(changed))
            with self.assertRaises(AssertionError): check_archive(sandbox)


class TestDiscoveryEvidenceTests(unittest.TestCase):
    def test_empty_or_partial_discovery_is_rejected(self):
        from checkpoint import validate_test_count
        validate_test_count('Ran 68 tests in 1.2s\n\nOK')
        for output in ('Ran 0 tests in 0.0s\nOK','Ran 67 tests in 1s\nOK','OK'):
            with self.assertRaises(ValueError):validate_test_count(output)


class ContractionEvidenceTests(unittest.TestCase):
    def test_contract_and_source_boundaries(self):
        import json
        root=Path(__file__).resolve().parents[1]
        check_contraction_contract(root)
        original=json.loads((root/'census/contraction-contract.json').read_text())
        for key,value in [('fp_diagnostic_is_source_refutation',True),
                          ('fp_observation_contract_adopted',True),
                          ('source_correspondence_reviewed',True),
                          ('accepted_source_rewrites',1),('profile','arbitrary tensors')]:
            changed=copy.deepcopy(original);changed[key]=value
            with self.assertRaises(AssertionError):validate_contraction_contract(changed)

    def test_native_rows_and_bit_observations(self):
        import json
        root=Path(__file__).resolve().parents[1]
        check_contraction_archive(root)
        folder=root/'reports/contraction-replay-v3'
        result=json.loads((folder/'result.json').read_text());log=(folder/'test.log').read_text()
        for altered in [log.replace('case=outer01 mode=handler','case=omitted mode=handler'),
                        log.replace('case=batch_left mode=pass','case=wrong_axes mode=pass'),
                        log.replace('case=matrix_contract mode=pass changed=0',
                                    'case=matrix_contract mode=pass changed=1'),
                        log.replace('bits_equal=0','bits_equal=1')]:
            with self.assertRaises(AssertionError):validate_contraction_native(result,altered,3)
        changed=copy.deepcopy(result);changed['fp_cases'][1]['bits_equal']=True
        with self.assertRaises(AssertionError):validate_contraction_native(changed,log,3)
        changed=copy.deepcopy(result);changed['handler_initialization']='constructor only'
        with self.assertRaises(AssertionError):validate_contraction_native(changed,log,3)


class OrderedSourceEvidenceTests(unittest.TestCase):
    def test_path_coverage_and_continuation_mutations(self):
        root=Path(__file__).resolve().parents[1]
        record,cases=check_paths(root)
        changed=copy.deepcopy(record);changed['case_links'].pop()
        with self.assertRaises(AssertionError):validate_paths(changed,cases)
        changed=copy.deepcopy(record);changed['semantic_denominator']=41
        with self.assertRaises(AssertionError):validate_paths(changed,cases)
        changed=copy.deepcopy(record)
        pad=next(f for f in changed['source_functions'] if f['name']=='HandlePad')
        next(s for s in pad['stages'] if s['id']=='compatible')['outcome_contract']=['return on failure']
        with self.assertRaises(AssertionError):validate_paths(changed,cases)
        changed=copy.deepcopy(record)
        compare=next(f for f in changed['source_functions'] if f['name']=='HandleCompare')
        next(s for s in compare['stages'] if s['id']=='nonnegative-zero')['outcome_contract']=['nonnegative values']
        with self.assertRaises(AssertionError):validate_paths(changed,cases)

    def test_nan_truth_change_and_controls_are_not_erased(self):
        import json
        root=Path(__file__).resolve().parents[1];check_compare(root)
        folder=root/'reports/compare-nonnegative-replay-v1'
        result=json.loads((folder/'result.json').read_text());log=(folder/'test.log').read_text()
        for altered in [log.replace('kind=exp direction=GE mode=pass','kind=omitted direction=GE mode=pass'),
                        log.replace('mode=control changed=0','mode=control changed=1'),
                        log.replace('before=0,1,1,1,1,1','before=1,1,1,1,1,1')]:
            with self.assertRaises(AssertionError):validate_compare(result,altered)
        changed=copy.deepcopy(result);changed['accepted_source_rewrites']=2
        with self.assertRaises(AssertionError):validate_compare(changed,log)


class ScaledNestedSliceEvidenceTests(unittest.TestCase):
    def test_original_graph_partition_and_pointer_continuation_are_required(self):
        import json
        root=Path(__file__).resolve().parents[1];check_scaled_contract(root)
        cases=json.loads((root/'census/tensor-index-cases.json').read_text())['cases']
        original=next(c for c in cases if c['id']=='HandleDynamicSlice/nested-after-scaled-probe')
        direct=next(c for c in cases if c['id']=='HandleDynamicSlice/nested')
        for key,value in [('lhs',direct['lhs']),('source_path_partition','direct_original_data_operand'),
                          ('discarded_original_operation','none'),('proof','accepted')]:
            changed=copy.deepcopy(original);changed[key]=value
            with self.assertRaises(AssertionError):validate_scaled_partition(changed,direct)
        changed=copy.deepcopy(original);changed['local_binding_evidence'][0]['line']=8333
        with self.assertRaises(AssertionError):validate_scaled_partition(changed,direct)

    def test_value_change_and_static_orientation_type_controls_are_required(self):
        import json
        root=Path(__file__).resolve().parents[1];check_scaled_archive(root)
        folder=root/'reports/scaled-nested-slice-replay-v1'
        result=json.loads((folder/'result.json').read_text());log=(folder/'test.log').read_text()
        for altered in [log.replace('before=28 after=4','before=28 after=28'),
                        log.replace('case=reversed','case=omitted'),
                        log.replace('case=s64_result','case=omitted'),
                        log.replace('case=constant_starts mode=control','case=omitted mode=control')]:
            with self.assertRaises(AssertionError):validate_scaled_native(result,altered)
        changed=copy.deepcopy(result);changed['source_correspondence_reviewed']=True
        with self.assertRaises(AssertionError):validate_scaled_native(changed,log)


class ReducerIndexEvidenceTests(unittest.TestCase):
    def test_actual_source_does_not_have_the_corrected_safe_guards(self):
        import json
        root=Path(__file__).resolve().parents[1];check_reducer_index_contract(root)
        scatter=[c for c in json.loads((root/'census/arithmetic-cases.json').read_text())['cases'] if c['id'].startswith('HandleAdd/scatter-')]
        gather=next(c for c in json.loads((root/'census/tensor-index-cases.json').read_text())['cases'] if c['id']=='HandleGather/small-select-chain')
        for key in ('matcher_checks_parameter_numbers','matcher_checks_parameter_distinctness'):
            changed=copy.deepcopy(scatter);changed[0][key]=True
            with self.assertRaises(AssertionError):validate_reducer_profiles(changed,gather)
        changed=copy.deepcopy(scatter);changed[0]['reducer_role_profiles']=['01','10']
        with self.assertRaises(AssertionError):validate_reducer_profiles(changed,gather)
        changed=copy.deepcopy(gather);changed['checks_literal_representability']=True
        with self.assertRaises(AssertionError):validate_reducer_profiles(scatter,changed)

    def test_reducer_role_narrowing_and_guard_controls_are_required(self):
        import json
        root=Path(__file__).resolve().parents[1];check_reducer_index_archive(root)
        folder=root/'reports/reducer-index-replay-v1'
        result=json.loads((folder/'result.json').read_text());log=(folder/'test.log').read_text()
        for altered in [log.replace('before=7,4 after=8,4','before=7,4 after=7,4'),
                        log.replace('before=0 after=128','before=0 after=0'),
                        log.replace('s8_default4','omitted'),log.replace('s32_zero','omitted'),
                        log.replace('REDUCER_INDEX_CAST original=128 s8=-128',
                                    'REDUCER_INDEX_CAST original=128 s8=128')]:
            with self.assertRaises(AssertionError):validate_reducer_native(result,altered)
        changed=copy.deepcopy(result);changed['source_correspondence_reviewed']=True
        with self.assertRaises(AssertionError):validate_reducer_native(changed,log)


class SourceNormalizationRegistryTests(unittest.TestCase):
    def test_exact_source_and_nonacceptance_boundaries(self):
        import json
        root=Path(__file__).resolve().parents[1]
        registry=build_source_normalization(root)
        self.assertEqual(registry['independently_locally_normalized_record_count'],488)
        self.assertEqual(len(registry['not_yet_locally_normalized_case_ids']),0)
        self.assertIsNone(registry['semantic_denominator'])
        artifact=json.loads((root/registry['review_inputs'][0]['path']).read_text())
        cases={c['id']:c for c in json.loads((root/'census/arithmetic-cases.json').read_text())['cases']}
        changed=copy.deepcopy(artifact);changed['scope']['denominator_frozen']=True
        with self.assertRaises(AssertionError):validate_source_normalization(changed,cases,root)
        changed=copy.deepcopy(artifact);changed['cases'][0]['acceptance']='source accepted'
        with self.assertRaises(AssertionError):validate_source_normalization(changed,cases,root)
        changed=copy.deepcopy(artifact);next(iter(changed['source_spans'].values()))['sha256']='0'*64
        with self.assertRaises(AssertionError):validate_source_normalization(changed,cases,root)
        changed=copy.deepcopy(artifact);changed['cases'][0]['earlier_return_constraints']['ordered_prior_stage_refs']=['invented']
        with self.assertRaises(AssertionError):validate_source_normalization(changed,cases,root)
        changed=copy.deepcopy(artifact);changed['cases'][0]['ordered_actions'][0]['source_span']='invented'
        with self.assertRaises(AssertionError):validate_source_normalization(changed,cases,root)



class ConcatenateStatusEvidenceTests(unittest.TestCase):
    def test_native_archive_and_scope(self):
        check_concat_archive()

    def test_mutation_and_acceptance_boundaries(self):
        import json
        root=Path(__file__).resolve().parents[1]
        contract=json.loads((root/'census/concatenate-status-contract.json').read_text())
        for key in ('lean_certified','tensor_value_counterexample_claimed','nontermination_claimed'):
            changed=copy.deepcopy(contract);changed[key]=True
            with self.assertRaises(AssertionError):validate_concat_contract(changed)
        changed=copy.deepcopy(contract);changed['early_control_rejection']='all_control_dependencies'
        with self.assertRaises(AssertionError):validate_concat_contract(changed)
        folder=root/'reports/concatenate-status-replay-v3'
        result=json.loads((folder/'result.json').read_text());log=(folder/'test.log').read_text()
        changed=copy.deepcopy(result)
        row=next(r for r in changed['cases'] if not r['changed'] and r['delta']>0)
        row['delta']=0
        with self.assertRaises(AssertionError):validate_concat_native(changed,log)
        changed=copy.deepcopy(result);changed['accepted_source_rewrites']=1
        with self.assertRaises(AssertionError):validate_concat_native(changed,log)
        incomplete='\n'.join(line for line in log.splitlines() if not ('CONCAT_STATUS_RESULT' in line and 'mode=fixedpoint' in line))
        with self.assertRaises(AssertionError):validate_concat_native(result,incomplete)


class DynamicSliceEmptyReshapeEvidenceTests(unittest.TestCase):
    def test_constructor_failure_archive_and_domain(self):
        check_ds_empty_archive()

    def test_domain_and_outcome_boundaries(self):
        import json
        root=Path(__file__).resolve().parents[1]
        contract=json.loads((root/'census/dynamic-slice-empty-reshape-contract.json').read_text())
        for key in ('semantic_domain_resolved','lean_certified','stablehlo_contract_automatically_transferred_to_hlo'):
            changed=copy.deepcopy(contract);changed[key]=True
            with self.assertRaises(AssertionError):validate_ds_empty_contract(changed)
        changed=copy.deepcopy(contract);changed['published_xla_sizes_strictly_positive']=False
        with self.assertRaises(AssertionError):validate_ds_empty_contract(changed)
        folder=root/'reports/dynamic-slice-empty-reshape-replay-v4'
        result=json.loads((folder/'result.json').read_text());log=(folder/'test.log').read_text()
        changed=copy.deepcopy(result)
        row=next(r for r in changed['cases'] if r['outcome']=='checked_fatal');row['outcome']='valid'
        with self.assertRaises(AssertionError):validate_ds_empty_native(changed,log)
        changed=copy.deepcopy(result);changed['native_operator_evaluation']=True
        with self.assertRaises(AssertionError):validate_ds_empty_native(changed,log)
        incomplete='\n'.join(line for line in log.splitlines() if not ('DS_EMPTY_RESHAPE_RESULT' in line and 'case=layout_sensitive' in line))
        with self.assertRaises(AssertionError):validate_ds_empty_native(result,incomplete)

if __name__ == '__main__':
    unittest.main()
