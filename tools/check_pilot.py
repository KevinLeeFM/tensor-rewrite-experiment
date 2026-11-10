"""Build value pilot, audit axiom dependencies, check negative control, measure LOC."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
from lean_size import count_source
ROOT=Path(__file__).resolve().parents[1]

def validate_graph_context(graph, value_rules):
 expected={r['source_case']:'TensorRewrite.Pilot.BooleanDag.'+r['theorem'].rsplit('.',1)[1].replace('_zero','_false') for r in value_rules if r['theorem'].startswith('TensorRewrite.Pilot.Boolean.')}
 rows=graph['rules']
 if len(rows)!=len(expected) or {r['source_case']:r['theorem'] for r in rows}!=expected:
  raise ValueError('Boolean graph case omitted or duplicated')
 if len({r['theorem'] for r in rows})!=len(rows):raise ValueError('duplicate graph theorem')
 if graph['semantic_track']!='pure_same_shape_PRED_dataflow' or graph['accepted_source_rewrites']!=0:
  raise ValueError('pure graph evidence promoted to source acceptance')
 if graph['status']!='kernel_checked_pure_pred_graph_context_not_full_source_acceptance':
  raise ValueError('wrong graph evidence status')
 for row in rows:
  if row['status']!='kernel_checked_graph_context_not_source_acceptance' or not row['source_partition'].startswith('PRED pure same-shape dataflow only'):
   raise ValueError('graph source scope silently broadened')
  if row['source_case']=='HandleXor/equal-inputs' and 'pointer-identical self-input subcase only, not Identical equivalence' not in row['source_partition']:
   raise ValueError('pointer-self theorem generalized to instruction equivalence')

def main():
 outputs={}
 def run(name,cmd):
  p=subprocess.run(cmd,cwd=ROOT,text=True,capture_output=True)
  outputs[name]={'exit_code':p.returncode,'stdout':p.stdout,'stderr':p.stderr}
  return p
 for name,cmd in [('build',['lake','build']),('audit',['lake','env','lean','TensorRewrite/Pilot/Audit.lean']),('controls',['lake','env','lean','tests/fixtures/PilotControls.lean']),('transpose_controls',['lake','env','lean','tests/fixtures/TransposeControls.lean']),('float_exception_controls',['lake','env','lean','tests/fixtures/FloatExceptionalControls.lean']),('empty_slice_controls',['lake','env','lean','tests/fixtures/EmptySliceControls.lean']),('select_contraction_controls',['lake','env','lean','tests/fixtures/SelectContractionControls.lean']),('dag_controls',['lake','env','lean','tests/fixtures/DagControls.lean']),('constant_guard_controls',['lake','env','lean','tests/fixtures/ConstantGuardControls.lean']),('index_map_controls',['lake','env','lean','tests/fixtures/IndexMapControls.lean']),('dynamic_index_controls',['lake','env','lean','tests/fixtures/DynamicIndexControls.lean']),('nested_slice_controls',['lake','env','lean','tests/fixtures/NestedSliceControls.lean']),('reshape_controls',['lake','env','lean','tests/fixtures/ReshapeControls.lean']),('reduction_controls',['lake','env','lean','tests/fixtures/ReductionControls.lean']),('dense_layout_controls',['lake','env','lean','tests/fixtures/DenseLayoutControls.lean']),('effectful_dag_controls',['lake','env','lean','tests/fixtures/EffectfulDagControls.lean']),('control_repair_controls',['lake','env','lean','tests/fixtures/ControlRepairControls.lean']),('modular_arithmetic_controls',['lake','env','lean','tests/fixtures/ModularArithmeticControls.lean']),('modular_bridge_controls',['lake','env','lean','tests/fixtures/ModularBridgeControls.lean']),('reducer_index_controls',['lake','env','lean','tests/fixtures/ReducerIndexControls.lean']),('scaled_nested_controls',['lake','env','lean','tests/fixtures/ScaledNestedSliceControls.lean']),('ordered_compare_controls',['lake','env','lean','tests/fixtures/OrderedCompareControls.lean']),('contraction_controls',['lake','env','lean','tests/fixtures/ContractionControls.lean']),('signed_word_controls',['lake','env','lean','tests/fixtures/SignedWordControls.lean'])]:
  p=run(name,cmd)
  if p.returncode or 'warning:' in p.stdout+p.stderr: raise RuntimeError(outputs[name])
 for name,fixture in [('invalid_control','InvalidPilot'),('invalid_reverse','InvalidReverse'),('invalid_transpose','InvalidTranspose'),('invalid_subtract','InvalidSubtract'),('invalid_float_exception','InvalidFloatExceptional'),('invalid_empty_slice','InvalidEmptySlice'),('invalid_select_contraction','InvalidSelectContraction'),('invalid_dag','InvalidDag'),('invalid_constant_guard','InvalidConstantGuard'),('invalid_index_map','InvalidIndexMap'),('invalid_dynamic_index','InvalidDynamicIndex'),('invalid_nested_slice','InvalidNestedSlice'),('invalid_reshape','InvalidReshape'),('invalid_reduction','InvalidReduction'),('invalid_dense_layout','InvalidDenseLayout'),('invalid_effectful_dag','InvalidEffectfulDag'),('invalid_control_repair','InvalidControlRepair'),('invalid_modular_arithmetic','InvalidModularArithmetic'),('invalid_modular_bridge','InvalidModularBridge'),('invalid_reducer_role','InvalidReducerRole'),('invalid_gather_literal','InvalidGatherLiteral'),('invalid_scaled_nested','InvalidScaledNestedSlice'),('invalid_ordered_compare','InvalidOrderedCompare'),('invalid_contraction','InvalidContraction'),('invalid_signed_word','InvalidSignedWord')]:
  p=run(name,['lake','env','lean','tests/fixtures/'+fixture+'.lean'])
  if p.returncode==0 or 'rfl' not in p.stdout+p.stderr: raise RuntimeError('Invalid proof was not rejected as expected')
  if name in ('invalid_reducer_role','invalid_gather_literal','invalid_scaled_nested','invalid_ordered_compare','invalid_contraction','invalid_dag','invalid_constant_guard','invalid_index_map','invalid_dynamic_index','invalid_nested_slice','invalid_reshape','invalid_reduction','invalid_dense_layout','invalid_effectful_dag','invalid_control_repair','invalid_modular_arithmetic','invalid_modular_bridge','invalid_signed_word') and len(re.findall(r': error',p.stdout+p.stderr))!=1: raise RuntimeError('DAG negative control has unrelated errors')
 ledger=json.loads((ROOT/'census/pilot-value-proofs.json').read_text())
 rules=ledger['rules']
 support=ledger.get('support_theorems',[])
 graph=ledger.get('graph_context',{})
 graph_rules=graph.get('rules',[])
 validate_graph_context(graph,ledger['rules'])
 effectful=ledger['effectful_graph_context']
 assert effectful['accepted_source_rewrites']==0 and effectful['all_schedule_refinement_proved'] is False
 effectful_rules=effectful['rules']
 assert len(effectful_rules)==12
 assert {r['source_case']:r['theorem'].replace('.EffectfulBooleanDag.','.BooleanDag.') for r in effectful_rules}=={r['source_case']:r['theorem'] for r in graph_rules}
 order=ledger['control_order_diagnostic']
 assert order['accepted_source_rewrites']==0 and order['production_backend_executed'] is False
 order_certificates=order['certificates']
 repair=ledger['boolean_control_family']
 assert repair['accepted_source_rewrites']==0 and repair['all_schedule_refinement_proved'] is False
 repair_certificates=repair['repair_certificates']
 guard=ledger['constant_guard']
 assert guard['accepted_source_rewrites']==0
 assert guard['semantic_track']=='PRED finite storage and pure total index pullbacks'
 guard_bridges=guard['bridge_theorems']
 index_diagnostic=ledger['index_oracle_diagnostic']
 diagnostic_certificates=index_diagnostic['diagnostic_certificates']
 assert index_diagnostic['accepted_source_rewrites']==0
 assert index_diagnostic['scope']=='evaluator/logical index profiles; not an algebraic-simplifier counterexample'
 nested=ledger['nested_slice']
 assert nested['accepted_source_rewrites']==0
 assert nested['logical_profile']=='arbitrary finite rank and bounded static extents; mathematical decoded starts'
 assert nested['evaluator_profile']=='observed s64 conversion for DynamicSlice; typed unsigned HLO clamps; 10 to 6 to 2 shape chain'
 nested_rules=nested['logical_rule_theorems']
 nested_certificates=nested['evaluator_profile_certificates']
 numerical=ledger.get('numerical_refutation',{})
 shape=ledger.get('shape_refutation',{})
 algebraic=ledger.get('algebraic_refutation',{})
 algebraic_witnesses=algebraic.get('witness_theorems',[])
 refutations=numerical.get('refutation_theorems',[])+shape.get('refutation_theorems',[])+algebraic.get('refutation_theorems',[])
 consistency=numerical.get('consistency_theorems',[])+shape.get('consistency_theorems',[])
 witnesses=shape.get('witness_theorems',[])
 reducer_index=ledger['reducer_index']
 reducer_index_certificates=reducer_index['certificates']
 assert reducer_index['accepted_source_rewrites']==0 and not reducer_index['preservation_claim_for_actual_source_guard']
 scaled_nested=ledger['scaled_nested_slice']
 scaled_nested_certificates=scaled_nested['certificates']
 assert scaled_nested['accepted_source_rewrites']==0 and not scaled_nested['preservation_claim']
 ordered_compare=ledger['ordered_compare']
 ordered_compare_certificates=ordered_compare['certificates']
 assert ordered_compare['accepted_source_rewrites']==0 and not ordered_compare['backend_observation_contract_adopted']
 contraction=ledger['contraction']
 contraction_certificates=contraction['diagnostic_certificates']
 assert contraction['accepted_source_rewrites']==0 and not contraction['fp_diagnostic_is_source_refutation']
 deps={name:[a.strip() for a in axioms.split(',') if a.strip()] for name,axioms in re.findall(r"'([^']+)' depends on axioms: \[([^\]]*)\]",outputs['audit']['stdout'])}
 for name in re.findall(r"'([^']+)' does not depend on any axioms", outputs['audit']['stdout']):
  deps[name]=[]
 expected=[r['theorem'] for r in rules]+support+refutations+consistency+witnesses+algebraic_witnesses+[r['theorem'] for r in graph_rules]+guard_bridges+diagnostic_certificates+nested_rules+nested_certificates+[r['theorem'] for r in effectful_rules]+order_certificates+repair_certificates+contraction_certificates+ordered_compare_certificates+scaled_nested_certificates+reducer_index_certificates
 assert len(expected)==len(set(expected)), 'duplicate theorem accounting'
 assert set(deps)==set(expected)
 assert all(set(axioms)<={'propext','Quot.sound','Classical.choice'} for axioms in deps.values())
 # Retain the earlier empty-axiom certificate gate. The new general Int/list
 # theorem uses audited standard extensionality/quotient lemmas; the concrete
 # witnesses and universal-identity refutation still have empty dependencies.
 algebraic_general='TensorRewrite.Pilot.SelectContraction.nonzero_sum_refutes'
 assert set(algebraic.get('standard_axiom_refutation_theorems',[]))=={algebraic_general}
 assert all(not deps[name] for name in refutations+consistency+witnesses+algebraic_witnesses if name!=algebraic_general)
 assert set(deps[algebraic_general])<={'propext','Quot.sound'}
 assert all(not deps[name] for name in diagnostic_certificates+contraction_certificates+ordered_compare_certificates)
 # BitVec.ofInt's standard bound proof depends on propext. Preserve that
 # audited dependency for these word-addition certificates, without relaxing
 # the older empty-axiom diagnostic certificate gate.
 assert all(set(deps[name])<={'propext'} for name in nested_certificates)
 targets=shape.get('targets',[])
 assert len(targets)==len(shape.get('case_ids',[]))
 assert {t['case_id'] for t in targets}==set(shape.get('case_ids',[]))
 assert {t[k] for t in targets for k in ('refutation_theorem','not_preserving_theorem')}==set(shape.get('refutation_theorems',[]))
 assert {t['witness_theorem'] for t in targets}==set(witnesses)
 shape_cases={c['id'] for c in json.loads((ROOT/'census/shape-cases.json').read_text())['cases']}
 assert set(shape.get('case_ids',[]))<=shape_cases
 algebraic_cases={c['id'] for c in json.loads((ROOT/'census/convolution-cases.json').read_text())['cases']}
 assert algebraic.get('case_id') in algebraic_cases
 categories={'S':['TensorRewrite/Pilot/Tensor.lean','TensorRewrite/Pilot/Indexing.lean','TensorRewrite/Pilot/Permutation.lean','TensorRewrite/Pilot/PermutationArrays.lean','TensorRewrite/Pilot/PermutationLoop.lean','TensorRewrite/Pilot/Float32Exceptional.lean','TensorRewrite/Pilot/SliceShape.lean','TensorRewrite/Pilot/SelectContraction.lean','TensorRewrite/Pilot/Dag.lean','TensorRewrite/Pilot/BooleanDag.lean','TensorRewrite/Pilot/ConstantGuard.lean','TensorRewrite/Pilot/IndexMaps.lean','TensorRewrite/Pilot/DynamicIndexValue.lean','TensorRewrite/Pilot/DynamicIndex.lean','TensorRewrite/Pilot/DynamicSliceTensor.lean','TensorRewrite/Pilot/NestedUnsigned64.lean','TensorRewrite/Pilot/FiniteProduct.lean','TensorRewrite/Pilot/LinearIndex.lean','TensorRewrite/Pilot/Reshape.lean','TensorRewrite/Pilot/Reduction.lean','TensorRewrite/Pilot/DenseLayout.lean'],
             'H':['TensorRewrite/Pilot/IndexLemmas.lean','TensorRewrite/Pilot/PermutationArrayLemmas.lean','TensorRewrite/Pilot/PermutationLoopLemmas.lean','TensorRewrite/Pilot/SelectContractionLemmas.lean','TensorRewrite/Pilot/DagLemmas.lean','TensorRewrite/Pilot/ConstantGuardLemmas.lean','TensorRewrite/Pilot/SliceIndexBounds.lean','TensorRewrite/Pilot/IndexMapLemmas.lean','TensorRewrite/Pilot/DynamicIndexBounds.lean','TensorRewrite/Pilot/DynamicIndexLemmas.lean','TensorRewrite/Pilot/DynamicSliceCompositionLemmas.lean','TensorRewrite/Pilot/FiniteProductLemmas.lean','TensorRewrite/Pilot/LinearIndexLemmas.lean','TensorRewrite/Pilot/ReshapeLemmas.lean','TensorRewrite/Pilot/ReductionLemmas.lean','TensorRewrite/Pilot/DenseLayoutLemmas.lean'],
             'R':['TensorRewrite/Pilot/Boolean.lean','TensorRewrite/Pilot/Bitwise.lean','TensorRewrite/Pilot/Reverse.lean','TensorRewrite/Pilot/Transpose.lean','TensorRewrite/Pilot/Subtract.lean','TensorRewrite/Pilot/BooleanDagRules.lean','TensorRewrite/Pilot/GuardedBooleanDag.lean','TensorRewrite/Pilot/DynamicSliceComposition.lean','TensorRewrite/Pilot/ReshapeRules.lean','TensorRewrite/Pilot/ReductionRules.lean','TensorRewrite/Pilot/DenseLayoutRules.lean'],
             'A':['TensorRewrite.lean'],
             'C':['TensorRewrite/Pilot/PredMulRefutation.lean','TensorRewrite/Pilot/EmptySliceRefutation.lean','TensorRewrite/Pilot/SelectContractionRefutation.lean','TensorRewrite/Pilot/UnsignedIndexBoundary.lean','TensorRewrite/Pilot/NestedUnsigned64Certificates.lean']}
 categories['S'] += ['TensorRewrite/Pilot/OperandOrder.lean','TensorRewrite/Pilot/EffectfulDag.lean','TensorRewrite/Pilot/EffectfulBooleanDag.lean','TensorRewrite/Pilot/DependencyOrder.lean']
 categories['H'] += ['TensorRewrite/Pilot/PromotedWordArithmetic.lean','TensorRewrite/Pilot/OperandOrderLemmas.lean','TensorRewrite/Pilot/DependencyOrderLemmas.lean','TensorRewrite/Pilot/EffectfulDagLemmas.lean','TensorRewrite/Pilot/EffectfulBooleanDagLemmas.lean']
 categories['R'] += ['TensorRewrite/Pilot/ModularArithmeticBridges.lean','TensorRewrite/Pilot/EffectfulBooleanDagRules.lean','TensorRewrite/Pilot/ModularArithmetic.lean']
 categories['C'] += ['TensorRewrite/Pilot/ControlOrderCertificates.lean']
 categories['S'] += ['TensorRewrite/Pilot/ReducerIndex.lean']
 categories['H'] += ['TensorRewrite/Pilot/ReducerIndexLemmas.lean']
 categories['C'] += ['TensorRewrite/Pilot/ReducerIndexCertificates.lean']
 categories['S'] += ['TensorRewrite/Pilot/ScaledNestedSlice.lean']
 categories['C'] += ['TensorRewrite/Pilot/ScaledNestedSliceCertificates.lean']
 categories['S'] += ['TensorRewrite/Pilot/OrderedCompareProfile.lean']
 categories['C'] += ['TensorRewrite/Pilot/OrderedCompareCertificates.lean']
 categories['S'] += ['TensorRewrite/Pilot/Contraction.lean','TensorRewrite/Pilot/ZeroMacProfile.lean']
 categories['H'] += ['TensorRewrite/Pilot/ContractionLemmas.lean']
 categories['R'] += ['TensorRewrite/Pilot/ContractionRules.lean']
 categories['C'] += ['TensorRewrite/Pilot/ZeroMacCertificates.lean']
 rows=[]
 for category,paths in categories.items():
  for name in paths:
   data=(ROOT/name).read_bytes()
   rows.append({'path':name,'category':category,'sha256':hashlib.sha256(data).hexdigest(),**count_source(data.decode())})
 report={'schema':1,'status':'kernel_checked_values_and_explicit_contract_refutation_not_full_source_acceptance',
         'reducer_index_scope':reducer_index,'checked_reducer_index_certificates':len(reducer_index_certificates),'scaled_nested_slice_scope':scaled_nested,'checked_scaled_nested_slice_certificates':len(scaled_nested_certificates),'ordered_compare_scope':ordered_compare,'checked_ordered_comparison_certificates':len(ordered_compare_certificates),'contraction_scope':contraction,'checked_contraction_diagnostic_certificates':len(contraction_certificates),'signed_word_scope':ledger['signed_words'],'modular_bridge_scope':ledger['modular_bridges'],'modular_arithmetic_scope':ledger['modular_arithmetic'],'checked_effectful_graph_context_theorems':len(effectful_rules),'effectful_graph_context_scope':effectful,'checked_control_order_repair_certificates':len(repair_certificates),'boolean_control_family_scope':repair,'checked_control_order_certificates':len(order_certificates),'control_order_diagnostic_scope':order,'checked_value_theorems':len(rules),'checked_graph_context_theorems':len(graph_rules),'checked_guard_bridge_theorems':len(guard_bridges),'constant_guard_scope':guard,'graph_context_scope':graph,'checked_support_theorems':len(support),'accepted_source_rewrites':0,
         'checked_refutation_theorems':len(refutations),'checked_nested_slice_logical_rules':len(nested_rules),'checked_evaluator_relative_nested_slice_certificates':len(nested_certificates),'nested_slice_scope':nested,'checked_index_oracle_diagnostic_certificates':len(diagnostic_certificates),'index_oracle_diagnostic_scope':index_diagnostic,'checked_contract_consistency_theorems':len(consistency),
         'checked_shape_witness_theorems':len(witnesses),
         'refuted_value_targets_under_explicit_contract':1 if numerical.get('refutation_theorems') else 0,
         'refuted_shape_targets_under_explicit_contract':len(shape.get('case_ids',[])),
         'numerical_refutation_scope':numerical,
         'shape_refutation_scope':shape,'algebraic_refutation_scope':algebraic,
         'checked_algebraic_witness_theorems':len(algebraic_witnesses),
         'refuted_algebraic_targets_in_mathematical_track':1 if algebraic else 0,
         'axiom_dependencies':deps,'checks':outputs,'files':rows,
         'category_lines':{c:sum(r['code_lines'] for r in rows if r['category']==c) for c in categories},
         'total_custom_lean_lines':sum(r['code_lines'] for r in rows),
         'refutation_certificate_lines':sum(r['code_lines'] for r in rows if r['category']=='C'),
         'measurement_scope':'full custom Lean value and static-shape development; audit/test files excluded and reported separately',
         'test_audit_lines':{name:count_source((ROOT/name).read_text()) for name in ['TensorRewrite/Pilot/Audit.lean','tests/fixtures/PilotControls.lean','tests/fixtures/InvalidPilot.lean','tests/fixtures/InvalidReverse.lean','tests/fixtures/TransposeControls.lean','tests/fixtures/InvalidTranspose.lean','tests/fixtures/InvalidSubtract.lean','tests/fixtures/FloatExceptionalControls.lean','tests/fixtures/InvalidFloatExceptional.lean','tests/fixtures/EmptySliceControls.lean','tests/fixtures/InvalidEmptySlice.lean','tests/fixtures/SelectContractionControls.lean','tests/fixtures/InvalidSelectContraction.lean','tests/fixtures/DagControls.lean','tests/fixtures/InvalidDag.lean','tests/fixtures/ConstantGuardControls.lean','tests/fixtures/InvalidConstantGuard.lean','tests/fixtures/IndexMapControls.lean','tests/fixtures/InvalidIndexMap.lean','tests/fixtures/DynamicIndexControls.lean','tests/fixtures/InvalidDynamicIndex.lean','tests/fixtures/NestedSliceControls.lean','tests/fixtures/InvalidNestedSlice.lean','tests/fixtures/ReshapeControls.lean','tests/fixtures/InvalidReshape.lean','tests/fixtures/ReductionControls.lean','tests/fixtures/InvalidReduction.lean','tests/fixtures/DenseLayoutControls.lean','tests/fixtures/InvalidDenseLayout.lean','tests/fixtures/EffectfulDagControls.lean','tests/fixtures/InvalidEffectfulDag.lean','tests/fixtures/ControlRepairControls.lean','tests/fixtures/InvalidControlRepair.lean','tests/fixtures/ModularArithmeticControls.lean','tests/fixtures/InvalidModularArithmetic.lean','tests/fixtures/ModularBridgeControls.lean','tests/fixtures/InvalidModularBridge.lean','tests/fixtures/SignedWordControls.lean','tests/fixtures/InvalidSignedWord.lean','tests/fixtures/ContractionControls.lean','tests/fixtures/InvalidContraction.lean','tests/fixtures/OrderedCompareControls.lean','tests/fixtures/InvalidOrderedCompare.lean','tests/fixtures/ScaledNestedSliceControls.lean','tests/fixtures/InvalidScaledNestedSlice.lean','tests/fixtures/ReducerIndexControls.lean','tests/fixtures/InvalidReducerRole.lean','tests/fixtures/InvalidGatherLiteral.lean']}}
 (ROOT/'reports/pilot-values.json').write_text(json.dumps(report,indent=2)+'\n')
 print('Pilot passed:',report['checked_value_theorems'],'value theorems;',report['category_lines'],'source rewrites accepted: 0')
if __name__=='__main__':main()
