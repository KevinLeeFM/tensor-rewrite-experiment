"""Inventory retained benchmark data and checked mathematical evidence; no C++ processing."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = 'census/mathematical-corpus-v1.json'
BATCHES = ('arithmetic', 'collective-rotation', 'convolution', 'dot', 'layout',
           'reduction', 'scalar-control', 'shape', 'simple', 'tensor-index')
ALLOWED = {'propext', 'Quot.sound', 'Classical.choice'}


def read(path, root=ROOT):
    return json.loads((root/path).read_text())


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def freeze(root=ROOT):
    target = root/MANIFEST
    if target.exists():
        raise ValueError('corpus v1 already exists; revisions require a new manifest version')
    files=[]; ids=[]
    for batch in BATCHES:
        name='census/'+batch+'-cases.json'
        rows=read(name, root)['cases']
        files.append(dict(path=name, sha256=digest(root/name), count=len(rows)))
        ids.extend(row['id'] for row in rows)
    assert len(ids)==len(set(ids))==488
    record=dict(schema=1, benchmark_records_frozen=True, benchmark_record_count=len(ids),
                mathematical_obligation_denominator_frozen=False,
                mathematical_obligation_denominator=None,
                scope='retained abstract benchmark data only; no new code correspondence',
                files=files, benchmark_ids=sorted(ids))
    target.write_text(json.dumps(record,indent=2)+'\n')


def corpus(root=ROOT):
    manifest=read(MANIFEST,root); rows={}
    for file in manifest['files']:
        assert digest(root/file['path'])==file['sha256'], file['path']
        cases=read(file['path'],root)['cases']
        assert len(cases)==file['count']
        for case in cases:
            assert case['id'] not in rows
            rows[case['id']]=dict(benchmark_id=case['id'],batch=Path(file['path']).stem,
                retained_lhs=case.get('lhs'),retained_rhs=case.get('rhs'),
                unreviewed_benchmark_notes_not_assumptions=case.get('guard'),
                mathematical_target_status='needs_formal_statement_and_domain_partition',
                evidence=[],whole_record_mathematically_closed=False,
                code_correspondence='future_work')
    assert sorted(rows)==manifest['benchmark_ids']
    assert len(rows)==manifest['benchmark_record_count']==488
    return rows



def retained_declaration_refs(value,path='pilot'):
    result={}
    def visit(item,origin):
        if isinstance(item,dict):
            for key,entry in item.items():visit(entry,origin+'.'+key)
        elif isinstance(item,list):
            for index,entry in enumerate(item):visit(entry,origin+'['+str(index)+']')
        elif isinstance(item,str) and item.startswith('TensorRewrite.'):
            result.setdefault(item,[]).append(origin)
    visit(value,path)
    return result


def evidence(root=ROOT):
    pilot=read('census/pilot-value-proofs.json',root); result={}
    def add(name,kind,profile,labels=()):
        if name not in result:
            result[name]=dict(theorem=name,kinds=[],profile_descriptions=[],
                              historical_candidate_benchmark_labels=[],
                              label_correspondence_certified=False,
                              mathematical_acceptance='kernel_check_pending',
                              independent_statement_review='pending')
        row=result[name]
        if kind not in row['kinds']:row['kinds'].append(kind)
        if profile not in row['profile_descriptions']:row['profile_descriptions'].append(profile)
        row['historical_candidate_benchmark_labels']=sorted(set(
            row['historical_candidate_benchmark_labels'])|set(labels))
    for row in pilot['rules']:
        labels=([row['source_case']] if row.get('source_case') else [])+row.get('additional_source_cases',[])
        add(row['theorem'],'value_law',row['semantic_track'],labels)
    for kind,key in [('pure_graph_context','graph_context'),('fixed_schedule_context','effectful_graph_context')]:
        for row in pilot[key]['rules']:
            add(row['theorem'],kind,row['source_partition'],[row['source_case']])
    nested=pilot['nested_slice']
    for name in nested['logical_rule_theorems']:
        add(name,'value_law',nested['logical_profile'],[nested['source_case']])
    for name in pilot['support_theorems']:
        add(name,'support_lemma','premises and conclusion in the checked Lean declaration')
    # These are mathematical certificates. No native evidence validator is invoked.
    for key in ('numerical_refutation','shape_refutation','algebraic_refutation',
                'ordered_compare','scaled_nested_slice','reducer_index'):
        group=pilot[key]
        labels=group.get('case_ids',group.get('source_cases',[]))
        if group.get('case_id'):labels=[group['case_id']]
        for name in group.get('refutation_theorems',group.get('certificates',[])):
            add(name,'refutation_or_diagnostic_certificate',group.get('profile',group.get('scope','')),labels)
    # Every explicitly retained declaration reference is inventoried, including diagnostic
    # witnesses/consistency/repair certificates. No native evidence validator is invoked.
    kinds={'bridge_theorems':'mathematical_guard_bridge',
           'consistency_theorems':'model_consistency_certificate',
           'witness_theorems':'concrete_witness_certificate','witness_theorem':'concrete_witness_certificate',
           'diagnostic_certificates':'diagnostic_certificate',
           'evaluator_profile_certificates':'index_value_profile_certificate',
           'repair_certificates':'fixed_schedule_repair_certificate',
           'certificates':'fixed_schedule_or_diagnostic_certificate'}
    retained_profiles={
        'constant_guard':'Pure predicate tensor DAG with mathematical IsAll constant-recognition premise',
        'numerical_refutation':'Consistency of a partial encoded exceptional-product relation; not full IEEE arithmetic',
        'shape_refutation':'Bounded static shape/stride witness consistency and endpoint mismatch',
        'index_oracle_diagnostic':'Unsigned64 decoded-index versus declared signed-decoding alternative; no source equivalence',
        'nested_slice':'Bounded nested-slice unsigned64 index-profile diagnostics; no source equivalence',
        'control_order_diagnostic':'Validity and traces of schedules in the declared effectful DAG observation model',
        'boolean_control_family':'Fixed-schedule control-order repair in the declared effectful DAG observation model',
        'contraction':'Partial zero-MAC sign/initializer behavior relation; not a complete IEEE convolution or Dot specification'}
    for name,origins in retained_declaration_refs(pilot).items():
        if name not in result:
            group_name=origins[0].split('.')[1].split('[')[0]
            field=next((key for key in kinds if any('.'+key in origin for origin in origins)),None)
            group=pilot.get(group_name,{})
            profile=retained_profiles.get(group_name,group.get('profile',group.get('scope',
                group.get('logical_profile','Declared mathematical premises/conclusion in the checked Lean type; retained '+group_name))))
            add(name,kinds.get(field,'retained_mathematical_declaration'),profile)
        result[name]['retained_manifest_paths']=sorted(origins)
    # The retained packet groups two mathematical diagnostics. Keep their namespaces
    # and candidate labels distinct; no native or caller/API correspondence is inferred.
    for name,row in result.items():
        if '.ReducerIndex.ScatterRoles.' in name:
            row['historical_candidate_benchmark_labels']=[
                'HandleAdd/scatter-single-lhs','HandleAdd/scatter-single-rhs']
            row['profile_descriptions']=['single in-bounds coordinate update at arbitrary vector '
                'size/word width; actual current/update parameter roles; no general window, '
                'floating, effect or source correspondence claim']
        elif '.ReducerIndex.GatherLiterals.' in name:
            row['historical_candidate_benchmark_labels']=['HandleGather/small-select-chain']
            row['profile_descriptions']=['actual signed-word Select-chain coordinates and '
                'represented-threshold condition; concrete signed8 narrowing certificates; '
                'not general Gather dimension semantics or source correspondence']
    theory=read('reports/theory-progress.json',root)
    for name in theory['axiom_dependencies']:
        labels=['HandleNegate/involution'] if name.endswith('FloatNegation.tensor_involution') else []
        if name.endswith(('Convolution.convolve_empty_spatial_input',
                          'Convolution.convolve_empty_kernel','Convolution.convolve_no_channels')):
            labels=['HandleConvolution/empty']
        if name.endswith('Convolution.convolve_bias_scale'):
            labels=['TryToReorderConvAddMultiply/order-'+side for side in
                    ('lhs-lhs','lhs-rhs','rhs-lhs','rhs-rhs')]
        if name.endswith('ConvolutionPointwise.convolve_eq_channelSum'):
            labels=['SimplifyConvToDot/pointwise-layout']
        if name.endswith(('ConvolutionOrdered.convolve_eq_dot','ConvolutionFloat.binary32_pointwise_dot')):
            labels=['SimplifyConvToDot/pointwise-layout']
        if name.endswith('ConvolutionFloat.binary32_fold_omission_refuted'):
            labels=['SimplifyConvToMultiply/pointwise-000']
        if name.endswith('ConvolutionFloat.binary32_reversal_refuted'):
            labels=['SimplifyConvToMultiply/reduce-100']
        if name.endswith('ConvolutionSeparable.convolve_eq_productReduction'):
            labels=['SimplifyConvToMultiply/'+mode for mode in
                    ('pointwise-000','reduce-000','reduce-100')]
        if name.endswith('ConvolutionDot.convolve_eq_dot'):
            labels=['SimplifyConvToDot/pointwise-layout']
        if name.endswith('ConvolutionPointwise.convolve_single_channel'):
            labels=['SimplifyConvToMultiply/pointwise-000']
        if '.ScalarDomains.' in name:
            if name.endswith(('real_log_exp_tensor','complex_log_exp_tensor_iff',
                              'complex_log_exp_counterexample')):
                labels=['HandleLog/exp']
            elif name.endswith('real_log_sqrt_tensor_pos'):
                labels=['HandleLog/sqrt']
            elif name.endswith('real_sqrt_square_tensor'):
                labels=['HandleSqrt/square-real']
            elif name.endswith(('complex_sqrt_square_tensor_iff',
                                'complex_sqrt_square_counterexample')):
                labels=['HandleSqrt/square-complex']
        if '.ReductionAlgebra.' in name:
            suffix=name.rsplit('.',1)[1]
            labels={
                'constant_and':['HandleReduce/scalar-broadcast-and'],
                'constant_or':['HandleReduce/scalar-broadcast-or'],
                'constant_min':['HandleReduce/scalar-broadcast-minimum'],
                'constant_max':['HandleReduce/scalar-broadcast-maximum'],
                'constant_add':['HandleReduce/broadcast-replicated-axes'],
                'negate_sum':['HandleReduce/negate-sum'],
                'concat_add':['HandleReduce/concat','HandleReduce/merge-delegation'],
                'sum_reduction':['MergeReduces/combined-axes'],
                'empty_components':['BroadcastReduce/tuple','HandleReduce/empty-delegation'],
                'sameCount_components':['ReplaceReduceWithReshape/tuple',
                                        'HandleReduce/same-element-count']}.get(suffix,[])
        if '.ReductionWindow.' in name:
            domains=read('census/reduction-window-domains-v1.json',root)
            labels=[r['benchmark_id'] for r in domains['records'] if name in r['core_evidence']]
        if name.endswith(('FullSpanWindow.reduce_reshape','FullSpanWindow.original_reduce_reshape')):
            labels=read('census/full-span-window-v1.json',root)['candidate_benchmark_labels']
        if '.PrefixWindow.' in name:
            manifest=read('census/prefix-window-v1.json',root)
            labels=manifest['candidate_benchmark_bindings'].get(name.rsplit('.',1)[1],[])
        if '.ScatterLayout.' in name:
            manifest=read('census/scatter-layout-v1.json',root)
            labels=manifest['candidate_benchmark_bindings'].get(name,[])
        if '.ScatterConcat.' in name:
            manifest=read('census/scatter-concat-v1.json',root)
            labels=manifest['candidate_benchmark_bindings'].get(name,[])
        if '.OrderedScatter.' in name:
            manifest=read('census/ordered-scatter-v1.json',root)
            labels=manifest['candidate_benchmark_bindings'].get(name.rsplit('.',1)[1],[])
        if '.PadBroadcast.' in name:
            manifest=read('census/pad-broadcast-v1.json',root)
            labels=manifest['candidate_benchmark_bindings'].get(name.rsplit('.',1)[1],[])
        if '.BroadcastWindow.' in name:
            manifest=read('census/broadcast-window-v1.json',root)
            labels=manifest['candidate_benchmark_bindings'].get(name.rsplit('.',1)[1],[])
        if name.endswith(('WindowTupleFamily.rewrite_sound','WindowTransport.singleton_reduce')):
            labels=['HandleReduceWindow/singleton-tuple']
        if '.PadWindow.' in name:
            manifest=read('census/pad-window-v1.json',root)
            labels=manifest['candidate_benchmark_bindings'].get(name.rsplit('.',1)[1],[])
        if '.SlicePad.' in name:
            manifest=read('census/slice-pad-v1.json',root)
            suffix=name.rsplit('.',1)[1]
            if suffix in ('unit_window_graph','unit_window_add_zero','unit_window_min','unit_window_max'):
                labels=[label for label in manifest['candidate_benchmark_labels']
                        if suffix=='unit_window_graph' or
                        ('singleton-add-' in label if suffix=='unit_window_add_zero' else
                         'singleton-minimum-' in label if suffix=='unit_window_min' else
                         'singleton-maximum-' in label)]
        remainder=read('census/remainder-v1.json',root)
        labels=sorted(set(labels)|set(remainder['candidate_benchmark_bindings'].get(name,[])))
        kind=('scatter_layout_order_refutation' if '.ScatterLayout.' in name
              and name.endswith('_refuted') else
              'ordered_scatter_contract_refutation' if '.OrderedScatter.' in name
              and name.endswith('_refuted') else
              'uniform_fixed_order_rounding_refutation' if '.UniformSum.' in name else
              'remainder_contract_refutation' if '.Remainder.' in name
              and name.endswith('_refuted') else
              'pad_broadcast_contract_refutation' if '.PadBroadcast.' in name
              and name.endswith('_refuted') else
              'broadcast_state_contract_refutation' if '.BroadcastWindow.' in name
              and name.endswith('_refuted') else
              'prefix_window_contract_refutation' if '.PrefixWindow.' in name
              and name.endswith('_refuted') else
              'pad_window_contract_refutation' if '.PadWindow.' in name
              and name.endswith('_refuted') else
              'slice_pad_geometry_refutation' if '.SlicePad.' in name
              and name.endswith('_refuted') else
              'window_contract_refutation' if '.ReductionWindow.' in name
              and name.endswith('_refuted') else
              'reduction_contract_refutation' if '.ReductionAlgebra.' in name
              and name.endswith('_refuted') else
              'scalar_domain_counterexample' if '.ScalarDomains.' in name
              and name.endswith('_counterexample') else
              'numerical_contract_refutation' if '.ConvolutionFloat.' in name
              and name.endswith('_refuted') else 'library_backed_theory')
        add(name,kind,theory.get('theorem_profiles',{}).get(name,theory['scope']),labels)
    return sorted(result.values(),key=lambda row:row['theorem'])


def audit_theorems(rows,root=ROOT):
    path=root/'reports/mathematical-ledger-audit.lean'
    lines=['import TensorRewrite','import TensorRewriteTheory','']
    for row in rows:
        lines.extend(['#check @'+row['theorem'],'#print axioms '+row['theorem']])
    path.write_text('\n'.join(lines)+'\n')
    build=subprocess.run(['lake','build'],cwd=root,text=True,capture_output=True)
    assert build.returncode==0,(build.stdout+build.stderr)[-6000:]
    run=subprocess.run(['lake','env','lean',str(path)],cwd=root,text=True,capture_output=True)
    (root/'reports/mathematical-ledger-audit.log').write_text(run.stdout+run.stderr)
    assert run.returncode==0,(run.stdout+run.stderr)[-6000:]
    for row in rows:
        name=row['theorem']
        match=re.search(re.escape(name)+r"' depends on axioms: \[([^\]]*)\]",run.stdout)
        if match:axioms={v.strip() for v in match[1].split(',') if v.strip()}
        else:
            assert name+"' does not depend on any axioms" in run.stdout,name
            axioms=set()
        assert axioms<=ALLOWED,(name,axioms)
        row['mathematical_acceptance']='kernel_checked_in_declared_model'
        row['axiom_dependencies']=sorted(axioms)
    return dict(path=str(path.relative_to(root)),sha256=digest(path),exit_code=run.returncode,
                output_path='reports/mathematical-ledger-audit.log',
                output_sha256=digest(root/'reports/mathematical-ledger-audit.log'))


def formulated_families(root=ROOT):
    family=read('reports/logical-values-family.json',root)
    frozen=read(family['manifest'],root)
    assert digest(root/family['manifest'])==family['manifest_sha256']
    assert family['status']=='kernel_complete_declared_mathematical_value_family'
    assert family['profile_units']==frozen['profile_units']
    assert family['profile_unit_count']==frozen['profile_unit_count']==20
    assert not family['code_correspondence_performed']
    assert family['code_correspondence_future_work'] and family['whole_benchmark_records_closed']==0
    for file in frozen['model_files']:
        assert digest(root/file['path'])==file['sha256']
    theory=read('reports/theory-progress.json',root)
    expected={name:axioms for name,axioms in theory['axiom_dependencies'].items()
              if '.LogicalFamily.' in name}
    assert len(expected)==6 and family['certificate_axioms']==expected
    for profile in family['profile_units']:
        expected_condition='inputs[0] = inputs[1]' if profile['rule']=='xor_equal' else 'True'
        assert profile['side_condition']==expected_condition
    families=[dict(family=frozen['family'],profile_unit_count=20,
                 kernel_status=family['status'],independent_statement_review='pending',
                 observations=family['observations'],manifest=family['manifest'],
                 manifest_sha256=family['manifest_sha256'],
                 candidate_benchmark_labels=family['covered_candidate_benchmark_labels'],
                 label_correspondence_certified=False)]
    from check_broadcast_window import validate_family_result
    family=read('reports/window-tuple-family.json',root);validate_family_result(family)
    frozen=read(family['manifest'],root)
    expected={name:axioms for name,axioms in theory['axiom_dependencies'].items()
              if '.WindowTupleFamily.' in name}
    assert len(expected)==3 and family['certificate_axioms']==expected
    families.append(dict(family=frozen['family'],profile_unit_count=1,
                         kernel_status=family['status'],independent_statement_review='pending',
                         observations=family['observations'],manifest=family['manifest'],
                         manifest_sha256=family['manifest_sha256'],
                         candidate_benchmark_labels=family['covered_candidate_benchmark_labels'],
                         label_correspondence_certified=False))
    return families


def mathematical_models(root=ROOT):
    from check_convolution_model import validate_result
    model=read('reports/convolution-model.json',root);validate_result(model)
    assert digest(root/model['manifest'])==model['manifest_sha256']
    frozen=read(model['manifest'],root)
    for file in frozen['model_files']:
        assert digest(root/file['path'])==file['sha256']
    theory=read('reports/theory-progress.json',root)
    expected={name:axioms for name,axioms in theory['axiom_dependencies'].items()
              if '.Convolution.' in name}
    assert model['certificate_axioms']==expected
    models=[dict(model=frozen['model'],scope=frozen['geometry'],scalar_contract='exact_semiring',
                 status=model['status'],checked_theorem_count=20,
                 full_family_complete=False,independent_statement_review='pending',
                 manifest=model['manifest'],manifest_sha256=model['manifest_sha256'])]
    from check_convolution_pointwise import validate_result as validate_pointwise
    pointwise=read('reports/convolution-pointwise.json',root);validate_pointwise(pointwise)
    assert digest(root/pointwise['manifest'])==pointwise['manifest_sha256']
    extension=read(pointwise['manifest'],root)
    assert extension['base_model_manifest']==model['manifest']
    assert extension['base_model_manifest_sha256']==model['manifest_sha256']
    for file in extension['files']:
        assert digest(root/file['path'])==file['sha256'],file['path']
    expected={name:axioms for name,axioms in theory['axiom_dependencies'].items()
              if '.ConvolutionPointwise.' in name}
    assert pointwise['certificate_axioms']==expected
    assert set(extension['certificates'])==set(expected)
    models.append(dict(model=extension['model'],scope=extension['hypotheses'],
                       scalar_contract='exact_semiring',status=pointwise['status'],
                       checked_theorem_count=13,full_family_complete=False,
                       independent_statement_review='pending',manifest=pointwise['manifest'],
                       manifest_sha256=pointwise['manifest_sha256']))
    from check_convolution_dot import check_inputs, validate_result as validate_dot
    dot=read('reports/convolution-dot.json',root);validate_dot(dot)
    assert digest(root/dot['manifest'])==dot['manifest_sha256']
    dot_manifest=check_inputs(root)
    assert dot_manifest['base_model_manifest']==model['manifest']
    assert dot_manifest['channel_model_manifest']==pointwise['manifest']
    expected={name:axioms for name,axioms in theory['axiom_dependencies'].items()
              if '.ConvolutionDot.' in name}
    assert dot['certificate_axioms']==expected
    assert set(dot_manifest['certificates'])==set(expected)
    models.append(dict(model=dot_manifest['model'],scope=dot_manifest['hypotheses'],
                       scalar_contract='exact_semiring',status=dot['status'],
                       checked_theorem_count=12,full_family_complete=False,
                       dot_tensor_bridge_proved=True,both_coordinate_round_trips_proved=True,
                       independent_statement_review='pending',manifest=dot['manifest'],
                       manifest_sha256=dot['manifest_sha256']))
    from check_convolution_separable import check_inputs as separable_inputs
    from check_convolution_separable import validate_result as validate_separable
    separable=read('reports/convolution-separable.json',root);validate_separable(separable)
    assert digest(root/separable['manifest'])==separable['manifest_sha256']
    separable_manifest=separable_inputs(root)
    expected={name:axioms for name,axioms in theory['axiom_dependencies'].items()
              if '.ConvolutionSeparable.' in name}
    assert separable['certificate_axioms']==expected
    assert set(separable_manifest['certificates'])==set(expected)
    models.append(dict(model=separable_manifest['model'],scope=separable_manifest['hypotheses'],
                       scalar_contract=separable['scalar_contract'],status=separable['status'],
                       checked_theorem_count=11,full_family_complete=False,
                       nonunit_axes_only=True,kernel_reversal_reindexed=True,
                       independent_statement_review='pending',manifest=separable['manifest'],
                       manifest_sha256=separable['manifest_sha256']))
    from check_convolution_ordered import check_inputs as ordered_inputs
    from check_convolution_ordered import validate_result as validate_ordered
    ordered=read('reports/convolution-ordered.json',root);validate_ordered(ordered)
    assert digest(root/ordered['manifest'])==ordered['manifest_sha256']
    ordered_manifest=ordered_inputs(root)
    expected={name:axioms for name,axioms in theory['axiom_dependencies'].items()
              if '.ConvolutionOrdered.' in name or '.ConvolutionFloat.' in name}
    assert ordered['certificate_axioms']==expected
    assert set(ordered_manifest['certificates'])==set(expected)
    models.append(dict(model=ordered_manifest['model'],scope=ordered_manifest['hypotheses'],
                       scalar_contract=ordered['scalar_contract'],status=ordered['status'],
                       checked_theorem_count=15,full_family_complete=False,
                       binary32_ordered_pointwise_proved=True,
                       external_backend_schedule_verified=False,
                       independent_statement_review='pending',manifest=ordered['manifest'],
                       manifest_sha256=ordered['manifest_sha256']))
    from check_scalar_domains import check_inputs as scalar_inputs, validate_result as validate_scalar
    scalar=read('reports/scalar-domains.json',root);validate_scalar(scalar)
    assert digest(root/scalar['manifest'])==scalar['manifest_sha256']
    scalar_manifest=scalar_inputs(root)
    expected={name:axioms for name,axioms in theory['axiom_dependencies'].items()
              if '.ScalarDomains.' in name}
    assert scalar['certificate_axioms']==expected
    models.append(dict(model=scalar_manifest['model'],scope='exact real/principal-complex log/sqrt domains',
                       scalar_contract=scalar['scalar_contract'],status=scalar['status'],
                       checked_theorem_count=14,full_family_complete=False,
                       domain_profiles=scalar['profiles'],rounded_transcendentals_modeled=False,
                       independent_statement_review='pending',manifest=scalar['manifest'],
                       manifest_sha256=scalar['manifest_sha256']))
    from check_reduction_algebra import check_inputs as reduction_inputs
    from check_reduction_algebra import validate_result as validate_reduction
    reduction=read('reports/reduction-algebra.json',root);validate_reduction(reduction)
    extension=reduction_inputs()
    expected={name:axioms for name,axioms in theory['axiom_dependencies'].items()
              if '.ReductionFiber.' in name or '.ReductionAlgebra.' in name}
    assert reduction['certificate_axioms']==expected
    models.append(dict(model=extension['model'],scope=extension['axis_contract'],
                       scalar_contract=reduction['scalar_contract'],status=reduction['status'],
                       checked_theorem_count=27,full_family_complete=False,
                       actual_ordered_fiber_to_coordinate_sum_proved=True,
                       window_geometry_proved=False,independent_statement_review='pending',
                       manifest=reduction['manifest'],manifest_sha256=reduction['manifest_sha256']))
    from check_reduction_window import check_inputs as window_inputs
    from check_reduction_window import validate_result as validate_window
    window=read('reports/reduction-window.json',root);validate_window(window)
    extension=window_inputs()
    expected={name:axioms for name,axioms in theory['axiom_dependencies'].items()
              if '.ReductionWindow.' in name}
    assert window['certificate_axioms']==expected
    models.append(dict(model=extension['model'],scope=extension['geometry_contract'],
                       scalar_contract=window['scalar_contract'],status=window['status'],
                       checked_theorem_count=29,full_family_complete=False,
                       unit_affine_gather_proved=True,invalid_samples_are_folded=True,
                       separate_slice_pad_graph_equivalence_proved=False,
                       independent_statement_review='pending',manifest=window['manifest'],
                       manifest_sha256=window['manifest_sha256']))
    from check_slice_pad import check_inputs as factor_inputs, validate_result as validate_factor
    factor=read('reports/slice-pad.json',root);validate_factor(factor)
    extension=factor_inputs()
    expected={name:axioms for name,axioms in theory['axiom_dependencies'].items()
              if '.SlicePad.' in name}
    assert factor['certificate_axioms']==expected
    models.append(dict(model=extension['model'],scope=extension['arithmetic_domain'],
                       scalar_contract='arbitrary pure scalar map; original unit-window padding law retained',
                       status=factor['status'],checked_theorem_count=28,full_family_complete=False,
                       separate_slice_pad_graph_equivalence_proved=True,
                       slice_attributes_well_formed=True,output_shape_equality_derived=True,
                       base_window_manifest=window['manifest'],
                       base_window_manifest_sha256=window['manifest_sha256'],
                       independent_statement_review='pending',manifest=factor['manifest'],
                       manifest_sha256=factor['manifest_sha256']))
    from check_full_span_window import check_inputs as full_inputs
    from check_full_span_window import validate_result as validate_full
    full=read('reports/full-span-window.json',root);validate_full(full)
    extension=full_inputs()
    expected={name:axioms for name,axioms in theory['axiom_dependencies'].items()
              if '.FullSpanWindow.' in name or '.OrderedCoordinates.' in name}
    assert full['certificate_axioms']==expected
    models.append(dict(model=extension['model'],scope=extension['conditions'],
                       scalar_contract=extension['scalar_contract'],status=full['status'],
                       checked_theorem_count=20,full_family_complete=False,
                       ordered_contribution_lists_equal=True,initializer_retained=True,
                       output_shape_and_reshape_derived=True,mixed_kept_reduced_axes=True,
                       base_window_manifest=window['manifest'],
                       base_window_manifest_sha256=window['manifest_sha256'],
                       independent_statement_review='pending',manifest=full['manifest'],
                       manifest_sha256=full['manifest_sha256']))
    from check_pad_window import check_inputs as pad_inputs
    from check_pad_window import validate_result as validate_pad
    padded=read('reports/pad-window.json',root);validate_pad(padded)
    extension=pad_inputs()
    expected={name:axioms for name,axioms in theory['axiom_dependencies'].items()
              if '.PadWindow.' in name or '.LatticeIndex.' in name}
    assert padded['certificate_axioms']==expected
    models.append(dict(model=extension['model'],scope=extension['conditions'],
                       scalar_contract=extension['scalar_contract'],status=padded['status'],
                       checked_theorem_count=23,full_family_complete=False,
                       independent_pad_operator=True,empty_safe_geometry_derived=True,
                       ordered_contribution_lists_equal=True,initializer_retained=True,
                       converted_fill_retained=True,broadcast_sequence_proved=False,
                       window_domain_worksheet=extension['window_domain_worksheet'],
                       independent_statement_review='pending',manifest=padded['manifest'],
                       manifest_sha256=padded['manifest_sha256']))
    from check_prefix_window import check_inputs as prefix_inputs
    from check_prefix_window import validate_result as validate_prefix
    prefix=read('reports/prefix-window.json',root);validate_prefix(prefix)
    extension=prefix_inputs()
    expected={name:axioms for name,axioms in theory['axiom_dependencies'].items()
              if '.PrefixWindow.' in name}
    assert prefix['certificate_axioms']==expected
    models.append(dict(model=extension['model'],scope=extension['conditions'],
                       scalar_contract=extension['arithmetic_contract'],status=prefix['status'],
                       checked_theorem_count=34,full_family_complete=False,
                       direct_prefix_semantics=True,ordered_padding_prefix_partition=True,
                       retained_strides_general=True,same_width_iota_product=True,
                       signed_unsigned_exact_domains_iff=True,
                       rounded_uniform_sum_product_proved=False,
                       scalar_wrapper_recognition_proved=False,
                       window_domain_worksheet=extension['window_domain_worksheet'],
                       independent_statement_review='pending',manifest=prefix['manifest'],
                       manifest_sha256=prefix['manifest_sha256']))
    from check_broadcast_window import check_inputs as broadcast_inputs
    from check_broadcast_window import validate_result as validate_broadcast
    broadcast=read('reports/broadcast-window.json',root);validate_broadcast(broadcast)
    extension=broadcast_inputs()
    expected={name:axioms for name,axioms in theory['axiom_dependencies'].items() if any(
        group in name for group in ('.BroadcastWindow.','.WindowTransport.',
                                    '.WindowTupleFamily.','.WindowTupleFloat.'))}
    assert len(expected)==36 and broadcast['certificate_axioms']==expected
    models.append(dict(model=extension['model'],scope=extension['geometry_contract'],
                       scalar_contract=extension['reducer_contract'],status=broadcast['status'],
                       checked_theorem_count=36,full_family_complete=False,
                       actual_reshape_broadcast_graph=True,shape_and_axes_derived=True,
                       associativity_assumed=False,two_sided_identity_required=True,
                       state_initial_padding_transport=True,binary32_tuple_stored_bits=True,
                       combined_pad_broadcast_composition_proved=False,
                       window_domain_worksheet=extension['window_domain_worksheet'],
                       independent_statement_review='pending',manifest=broadcast['manifest'],
                       manifest_sha256=broadcast['manifest_sha256']))
    from check_pad_broadcast import check_inputs as composed_inputs
    from check_pad_broadcast import validate_result as validate_composed
    composed=read('reports/pad-broadcast.json',root);validate_composed(composed)
    extension=composed_inputs()
    expected={name:axioms for name,axioms in theory['axiom_dependencies'].items()
              if '.PadBroadcast.' in name}
    assert len(expected)==13 and composed['certificate_axioms']==expected
    models.append(dict(model=extension['model'],scope=extension['geometry_contract'],
                       scalar_contract=extension['value_contract'],status=composed['status'],
                       checked_theorem_count=13,full_family_complete=False,
                       raw_coverage_derived=True,retained_edge_cancellation_derived=True,
                       complete_fused_attribute_equality=True,actual_reshape_broadcast_graph=True,
                       associativity_assumed=False,converted_fill_equality_required=True,
                       combined_pad_broadcast_composition_proved=True,
                       window_domain_worksheet=extension['window_domain_worksheet'],
                       independent_statement_review='pending',manifest=composed['manifest'],
                       manifest_sha256=composed['manifest_sha256']))
    from check_remainder import check_inputs as remainder_inputs, validate_result as validate_remainder
    remainder=read('reports/remainder.json',root);validate_remainder(remainder)
    extension=remainder_inputs()
    expected={name:axioms for name,axioms in theory['axiom_dependencies'].items()
              if '.Remainder.' in name or '.UniformSum.' in name}
    assert len(expected)==28 and remainder['certificate_axioms']==expected
    assert remainder['reused_axioms']=={n:theory['axiom_dependencies'][n]
                                       for n in extension['reused_certificates']}
    models.append(dict(model=extension['model'],scope=extension['range_contract'],
                       scalar_contract=extension['operator_contract'],status=remainder['status'],
                       checked_theorem_count=28,reused_declaration_count=1,full_family_complete=False,
                       actual_signed_select_negate_mask=True,bounded_axis_iota=True,
                       zero_divisor_total_model_disclosed=True,
                       floating_truncating_remainder_formalized=False,
                       uniform_fixed_order_bit_equality_refuted=True,
                       uniform_collective_refinement_refuted=False,
                       collective_communication_model_complete=False,
                       domain_worksheet=extension['domain_worksheet'],
                       independent_statement_review='pending',manifest=remainder['manifest'],
                       manifest_sha256=remainder['manifest_sha256']))
    from check_ordered_scatter import check_inputs as scatter_inputs, validate_result as validate_scatter
    scatter=read('reports/ordered-scatter.json',root);validate_scatter(scatter)
    extension=scatter_inputs()
    expected={name:axioms for name,axioms in theory['axiom_dependencies'].items()
              if '.OrderedScatter.' in name}
    assert len(expected)==36 and scatter['certificate_axioms']==expected
    models.append(dict(model=extension['model'],scope=extension['geometry_contract'],
                       scalar_contract=extension['algebra_contract'],status=scatter['status'],
                       checked_theorem_count=36,full_family_complete=False,
                       actual_window_event_generation=True,duplicate_order_preserved=True,
                       whole_coupled_state_preserved=True,derived_empty_vector_full_window_map=True,
                       actual_reducer_parameter_roles=True,all_width_word_instantiation=True,
                       tensor_input_concatenation_bridge_proved=False,
                       all_scatter_dimension_numbers_supported=False,
                       floating_associativity_assumed=False,
                       domain_worksheet=extension['domain_worksheet'],
                       independent_statement_review='pending',manifest=scatter['manifest'],
                       manifest_sha256=scatter['manifest_sha256']))
    from check_scatter_concat import check_inputs as concat_inputs, validate_result as validate_concat
    concatenation=read('reports/scatter-concat.json',root);validate_concat(concatenation)
    extension=concat_inputs()
    expected={name:axioms for name,axioms in theory['axiom_dependencies'].items()
              if '.ScatterConcat.' in name}
    assert len(expected)==9 and concatenation['certificate_axioms']==expected
    models.append(dict(model=extension['model'],scope=extension['geometry_contract'],
                       scalar_contract=extension['algebra_contract'],status=concatenation['status'],
                       checked_theorem_count=9,full_family_complete=False,
                       actual_tensor_inputs_concatenated=True,leading_batch_axis_bridge_proved=True,
                       arbitrary_shared_trailing_batch_dimensions=True,duplicate_order_preserved=True,
                       whole_state_sequential_law_without_algebra=True,
                       arbitrary_concat_axis_bridge_proved=False,
                       all_scatter_dimension_numbers_supported=False,
                       floating_associativity_assumed=False,
                       independent_statement_review='pending',manifest=concatenation['manifest'],
                       manifest_sha256=concatenation['manifest_sha256']))
    from check_scatter_layout import check_inputs as layout_inputs, validate_result as validate_layout
    layout=read('reports/scatter-layout.json',root);validate_layout(layout)
    extension=layout_inputs()
    expected={name:axioms for name,axioms in theory['axiom_dependencies'].items()
              if '.ScatterLayout.' in name}
    assert len(expected)==16 and layout['certificate_axioms']==expected
    models.append(dict(model=extension['model'],scope=extension['geometry_contract'],
                       scalar_contract=extension['algebra_contract'],status=layout['status'],
                       checked_theorem_count=16,full_family_complete=False,
                       actual_raw_update_tensor_read=True,
                       arbitrary_batch_window_axis_interleaving=True,
                       inserted_singleton_window_axes_derived=True,exact_ordered_trace_bridge=True,
                       raw_storage_order_counterexample_checked=True,
                       operand_index_batching_supported=False,
                       implicit_index_vector_layout_supported=False,
                       arbitrary_relative_window_permutation_supported=False,
                       all_scatter_dimension_numbers_supported=False,
                       floating_associativity_assumed=False,
                       independent_statement_review='pending',manifest=layout['manifest'],
                       manifest_sha256=layout['manifest_sha256']))
    return models


def assemble(cases,proofs,audit,families=(),models=()):
    for proof in proofs:
        assert proof['mathematical_acceptance']=='kernel_checked_in_declared_model'
        for label in proof['historical_candidate_benchmark_labels']:
            assert label in cases,label
            cases[label]['evidence'].append(proof['theorem'])
            cases[label]['mathematical_target_status']='partial_model_evidence_requires_partition_review'
    for family in families:
        for label in family['candidate_benchmark_labels']:
            assert label in cases,label
            cases[label].setdefault('kernel_complete_declared_value_families',[]).append(family['family'])
            cases[label]['mathematical_target_status']='declared_value_family_complete_full_record_partitions_open'
    records=sorted(cases.values(),key=lambda row:row['benchmark_id'])
    return dict(schema=1,status='mathematical_campaign_ledger_formulation_in_progress',
        code_correspondence_performed=False,code_correspondence_future_work=True,
        benchmark_record_count=len(records),mathematical_obligation_denominator=None,
        mathematical_denominator_frozen=False,whole_benchmark_records_closed=0,
        positive_or_negative_workflow_verdict='unresolved_full_campaign_required',
        benchmark_status_counts=dict(Counter(r['mathematical_target_status'] for r in records)),
        batch_counts=dict(Counter(r['batch'] for r in records)),
        distinct_checked_declarations=len(proofs),
        declaration_kind_counts=dict(Counter(k for p in proofs for k in p['kinds'])),
        formulated_mathematical_families=list(families),
        partial_mathematical_models=list(models),
        kernel_complete_family_profile_count=sum(f['profile_unit_count'] for f in families),
        count_policy='declaration kinds can overlap; benchmark labels are retained candidates, '
                     'not certified correspondence; no proof-count/488 coverage fraction',
        corpus_manifest=MANIFEST,audit=audit,proofs=proofs,benchmark_records=records)


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--freeze-corpus',action='store_true')
    args=parser.parse_args()
    if args.freeze_corpus:freeze()
    cases=corpus();proofs=evidence();audit=audit_theorems(proofs)
    result=assemble(cases,proofs,audit,formulated_families(),mathematical_models())
    (ROOT/'census/mathematical-ledger.json').write_text(json.dumps(result,indent=2)+'\n')
    print(str(result['benchmark_record_count'])+' benchmark records retained; '+
          str(result['distinct_checked_declarations'])+' mathematical declarations checked; '
          'full obligation partitions and verdict remain open.')


if __name__=='__main__':main()
