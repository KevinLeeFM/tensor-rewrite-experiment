import TensorRewrite
import TensorRewriteTheory

#check @TensorRewrite.Pilot.AxisArray.composeLoop_eq_compose
#print axioms TensorRewrite.Pilot.AxisArray.composeLoop_eq_compose
#check @TensorRewrite.Pilot.AxisArray.composePrefix_get
#print axioms TensorRewrite.Pilot.AxisArray.composePrefix_get
#check @TensorRewrite.Pilot.AxisArray.composePrefix_size
#print axioms TensorRewrite.Pilot.AxisArray.composePrefix_size
#check @TensorRewrite.Pilot.AxisArray.compose_get
#print axioms TensorRewrite.Pilot.AxisArray.compose_get
#check @TensorRewrite.Pilot.AxisArray.decode_preserves
#print axioms TensorRewrite.Pilot.AxisArray.decode_preserves
#check @TensorRewrite.Pilot.AxisArray.ofPermutation_comp
#print axioms TensorRewrite.Pilot.AxisArray.ofPermutation_comp
#check @TensorRewrite.Pilot.AxisArray.ofPermutation_get
#print axioms TensorRewrite.Pilot.AxisArray.ofPermutation_get
#check @TensorRewrite.Pilot.Bitwise.and_lhs_zero
#print axioms TensorRewrite.Pilot.Bitwise.and_lhs_zero
#check @TensorRewrite.Pilot.Bitwise.and_rhs_zero
#print axioms TensorRewrite.Pilot.Bitwise.and_rhs_zero
#check @TensorRewrite.Pilot.Bitwise.not_not
#print axioms TensorRewrite.Pilot.Bitwise.not_not
#check @TensorRewrite.Pilot.Bitwise.or_lhs_zero
#print axioms TensorRewrite.Pilot.Bitwise.or_lhs_zero
#check @TensorRewrite.Pilot.Bitwise.or_rhs_zero
#print axioms TensorRewrite.Pilot.Bitwise.or_rhs_zero
#check @TensorRewrite.Pilot.Bitwise.xor_lhs_zero
#print axioms TensorRewrite.Pilot.Bitwise.xor_lhs_zero
#check @TensorRewrite.Pilot.Bitwise.xor_rhs_zero
#print axioms TensorRewrite.Pilot.Bitwise.xor_rhs_zero
#check @TensorRewrite.Pilot.Bitwise.xor_self
#print axioms TensorRewrite.Pilot.Bitwise.xor_self
#check @TensorRewrite.Pilot.Boolean.and_lhs_false
#print axioms TensorRewrite.Pilot.Boolean.and_lhs_false
#check @TensorRewrite.Pilot.Boolean.and_lhs_true
#print axioms TensorRewrite.Pilot.Boolean.and_lhs_true
#check @TensorRewrite.Pilot.Boolean.and_rhs_false
#print axioms TensorRewrite.Pilot.Boolean.and_rhs_false
#check @TensorRewrite.Pilot.Boolean.and_rhs_true
#print axioms TensorRewrite.Pilot.Boolean.and_rhs_true
#check @TensorRewrite.Pilot.Boolean.not_not
#print axioms TensorRewrite.Pilot.Boolean.not_not
#check @TensorRewrite.Pilot.Boolean.or_lhs_false
#print axioms TensorRewrite.Pilot.Boolean.or_lhs_false
#check @TensorRewrite.Pilot.Boolean.or_lhs_true
#print axioms TensorRewrite.Pilot.Boolean.or_lhs_true
#check @TensorRewrite.Pilot.Boolean.or_rhs_false
#print axioms TensorRewrite.Pilot.Boolean.or_rhs_false
#check @TensorRewrite.Pilot.Boolean.or_rhs_true
#print axioms TensorRewrite.Pilot.Boolean.or_rhs_true
#check @TensorRewrite.Pilot.Boolean.xor_lhs_zero
#print axioms TensorRewrite.Pilot.Boolean.xor_lhs_zero
#check @TensorRewrite.Pilot.Boolean.xor_rhs_zero
#print axioms TensorRewrite.Pilot.Boolean.xor_rhs_zero
#check @TensorRewrite.Pilot.Boolean.xor_self
#print axioms TensorRewrite.Pilot.Boolean.xor_self
#check @TensorRewrite.Pilot.BooleanDag.and_lhs_false
#print axioms TensorRewrite.Pilot.BooleanDag.and_lhs_false
#check @TensorRewrite.Pilot.BooleanDag.and_lhs_true
#print axioms TensorRewrite.Pilot.BooleanDag.and_lhs_true
#check @TensorRewrite.Pilot.BooleanDag.and_rhs_false
#print axioms TensorRewrite.Pilot.BooleanDag.and_rhs_false
#check @TensorRewrite.Pilot.BooleanDag.and_rhs_true
#print axioms TensorRewrite.Pilot.BooleanDag.and_rhs_true
#check @TensorRewrite.Pilot.BooleanDag.and_rhs_true_of_isAll
#print axioms TensorRewrite.Pilot.BooleanDag.and_rhs_true_of_isAll
#check @TensorRewrite.Pilot.BooleanDag.not_not
#print axioms TensorRewrite.Pilot.BooleanDag.not_not
#check @TensorRewrite.Pilot.BooleanDag.or_lhs_false
#print axioms TensorRewrite.Pilot.BooleanDag.or_lhs_false
#check @TensorRewrite.Pilot.BooleanDag.or_lhs_true
#print axioms TensorRewrite.Pilot.BooleanDag.or_lhs_true
#check @TensorRewrite.Pilot.BooleanDag.or_rhs_false
#print axioms TensorRewrite.Pilot.BooleanDag.or_rhs_false
#check @TensorRewrite.Pilot.BooleanDag.or_rhs_true
#print axioms TensorRewrite.Pilot.BooleanDag.or_rhs_true
#check @TensorRewrite.Pilot.BooleanDag.xor_lhs_false
#print axioms TensorRewrite.Pilot.BooleanDag.xor_lhs_false
#check @TensorRewrite.Pilot.BooleanDag.xor_rhs_false
#print axioms TensorRewrite.Pilot.BooleanDag.xor_rhs_false
#check @TensorRewrite.Pilot.BooleanDag.xor_self
#print axioms TensorRewrite.Pilot.BooleanDag.xor_self
#check @TensorRewrite.Pilot.ConstantGuard.DenseLiteral.matchesAll_sound
#print axioms TensorRewrite.Pilot.ConstantGuard.DenseLiteral.matchesAll_sound
#check @TensorRewrite.Pilot.ConstantGuard.View.isAll_sound
#print axioms TensorRewrite.Pilot.ConstantGuard.View.isAll_sound
#check @TensorRewrite.Pilot.ConstantGuard.matchesAll_all
#print axioms TensorRewrite.Pilot.ConstantGuard.matchesAll_all
#check @TensorRewrite.Pilot.Contraction.contract_count_zero_of_lhs_empty
#print axioms TensorRewrite.Pilot.Contraction.contract_count_zero_of_lhs_empty
#check @TensorRewrite.Pilot.Contraction.contract_count_zero_of_rhs_empty
#print axioms TensorRewrite.Pilot.Contraction.contract_count_zero_of_rhs_empty
#check @TensorRewrite.Pilot.Contraction.dot_empty_contract
#print axioms TensorRewrite.Pilot.Contraction.dot_empty_contract
#check @TensorRewrite.Pilot.Contraction.dot_empty_lhs
#print axioms TensorRewrite.Pilot.Contraction.dot_empty_lhs
#check @TensorRewrite.Pilot.Contraction.dot_empty_output
#print axioms TensorRewrite.Pilot.Contraction.dot_empty_output
#check @TensorRewrite.Pilot.Contraction.dot_empty_rhs
#print axioms TensorRewrite.Pilot.Contraction.dot_empty_rhs
#check @TensorRewrite.Pilot.Contraction.dot_no_contract
#print axioms TensorRewrite.Pilot.Contraction.dot_no_contract
#check @TensorRewrite.Pilot.Contraction.dot_no_contract_of_finish_identity
#print axioms TensorRewrite.Pilot.Contraction.dot_no_contract_of_finish_identity
#check @TensorRewrite.Pilot.Contraction.firstIndex_appendIndex
#print axioms TensorRewrite.Pilot.Contraction.firstIndex_appendIndex
#check @TensorRewrite.Pilot.Contraction.secondIndex_appendIndex
#print axioms TensorRewrite.Pilot.Contraction.secondIndex_appendIndex
#check @TensorRewrite.Pilot.Contraction.terms_length
#print axioms TensorRewrite.Pilot.Contraction.terms_length
#check @TensorRewrite.Pilot.Contraction.terms_no_contract
#print axioms TensorRewrite.Pilot.Contraction.terms_no_contract
#check @TensorRewrite.Pilot.ControlOrder.original_forward_trace
#print axioms TensorRewrite.Pilot.ControlOrder.original_forward_trace
#check @TensorRewrite.Pilot.ControlOrder.original_forward_valid
#print axioms TensorRewrite.Pilot.ControlOrder.original_forward_valid
#check @TensorRewrite.Pilot.ControlOrder.original_requires_forward
#print axioms TensorRewrite.Pilot.ControlOrder.original_requires_forward
#check @TensorRewrite.Pilot.ControlOrder.original_reverse_impossible
#print axioms TensorRewrite.Pilot.ControlOrder.original_reverse_impossible
#check @TensorRewrite.Pilot.ControlOrder.repaired_forward_trace
#print axioms TensorRewrite.Pilot.ControlOrder.repaired_forward_trace
#check @TensorRewrite.Pilot.ControlOrder.repaired_forward_valid
#print axioms TensorRewrite.Pilot.ControlOrder.repaired_forward_valid
#check @TensorRewrite.Pilot.ControlOrder.repaired_refines_replacement
#print axioms TensorRewrite.Pilot.ControlOrder.repaired_refines_replacement
#check @TensorRewrite.Pilot.ControlOrder.repaired_requires_forward
#print axioms TensorRewrite.Pilot.ControlOrder.repaired_requires_forward
#check @TensorRewrite.Pilot.ControlOrder.repaired_reverse_impossible
#print axioms TensorRewrite.Pilot.ControlOrder.repaired_reverse_impossible
#check @TensorRewrite.Pilot.ControlOrder.replacement_admits_reverse
#print axioms TensorRewrite.Pilot.ControlOrder.replacement_admits_reverse
#check @TensorRewrite.Pilot.ControlOrder.replacement_reverse_trace
#print axioms TensorRewrite.Pilot.ControlOrder.replacement_reverse_trace
#check @TensorRewrite.Pilot.ControlOrder.replacement_reverse_valid
#print axioms TensorRewrite.Pilot.ControlOrder.replacement_reverse_valid
#check @TensorRewrite.Pilot.Dag.Node.evalEffectful_mapRefs
#print axioms TensorRewrite.Pilot.Dag.Node.evalEffectful_mapRefs
#check @TensorRewrite.Pilot.Dag.Node.eval_mapRefs
#print axioms TensorRewrite.Pilot.Dag.Node.eval_mapRefs
#check @TensorRewrite.Pilot.Dag.Program.evalEffectful_delete_equal
#print axioms TensorRewrite.Pilot.Dag.Program.evalEffectful_delete_equal
#check @TensorRewrite.Pilot.Dag.Program.evalEffectful_delete_unused
#print axioms TensorRewrite.Pilot.Dag.Program.evalEffectful_delete_unused
#check @TensorRewrite.Pilot.Dag.Program.evalEffectful_mapInputs
#print axioms TensorRewrite.Pilot.Dag.Program.evalEffectful_mapInputs
#check @TensorRewrite.Pilot.Dag.Program.evalEffectful_replace_equal
#print axioms TensorRewrite.Pilot.Dag.Program.evalEffectful_replace_equal
#check @TensorRewrite.Pilot.Dag.Program.eval_delete_equal
#print axioms TensorRewrite.Pilot.Dag.Program.eval_delete_equal
#check @TensorRewrite.Pilot.Dag.Program.eval_mapInputs
#print axioms TensorRewrite.Pilot.Dag.Program.eval_mapInputs
#check @TensorRewrite.Pilot.Dag.Program.eval_replace_equal
#print axioms TensorRewrite.Pilot.Dag.Program.eval_replace_equal
#check @TensorRewrite.Pilot.Dag.extend_liftRefs
#print axioms TensorRewrite.Pilot.Dag.extend_liftRefs
#check @TensorRewrite.Pilot.DenseLayout.address_transpose_val
#print axioms TensorRewrite.Pilot.DenseLayout.address_transpose_val
#check @TensorRewrite.Pilot.DenseLayout.fromOrdered_toOrdered
#print axioms TensorRewrite.Pilot.DenseLayout.fromOrdered_toOrdered
#check @TensorRewrite.Pilot.DenseLayout.linearize_cast_val
#print axioms TensorRewrite.Pilot.DenseLayout.linearize_cast_val
#check @TensorRewrite.Pilot.DenseLayout.minorOrderMatches_axis
#print axioms TensorRewrite.Pilot.DenseLayout.minorOrderMatches_axis
#check @TensorRewrite.Pilot.DenseLayout.minorOrderMatches_of_axis
#print axioms TensorRewrite.Pilot.DenseLayout.minorOrderMatches_of_axis
#check @TensorRewrite.Pilot.DenseLayout.orderedShape_transpose
#print axioms TensorRewrite.Pilot.DenseLayout.orderedShape_transpose
#check @TensorRewrite.Pilot.DenseLayout.read_write
#print axioms TensorRewrite.Pilot.DenseLayout.read_write
#check @TensorRewrite.Pilot.DenseLayout.toOrdered_fromOrdered
#print axioms TensorRewrite.Pilot.DenseLayout.toOrdered_fromOrdered
#check @TensorRewrite.Pilot.DenseLayout.transpose_eq_bitcast
#print axioms TensorRewrite.Pilot.DenseLayout.transpose_eq_bitcast
#check @TensorRewrite.Pilot.DenseLayout.transpose_extents
#print axioms TensorRewrite.Pilot.DenseLayout.transpose_extents
#check @TensorRewrite.Pilot.DenseLayout.write_read
#print axioms TensorRewrite.Pilot.DenseLayout.write_read
#check @TensorRewrite.Pilot.DependencyOrder.Graph.isSchedule_of_predecessor_inclusion
#print axioms TensorRewrite.Pilot.DependencyOrder.Graph.isSchedule_of_predecessor_inclusion
#check @TensorRewrite.Pilot.DependencyOrder.Graph.isTrace_of_predecessor_inclusion
#print axioms TensorRewrite.Pilot.DependencyOrder.Graph.isTrace_of_predecessor_inclusion
#check @TensorRewrite.Pilot.DynamicIndex.clampStart_bounds
#print axioms TensorRewrite.Pilot.DynamicIndex.clampStart_bounds
#check @TensorRewrite.Pilot.DynamicIndex.clampStart_combined
#print axioms TensorRewrite.Pilot.DynamicIndex.clampStart_combined
#check @TensorRewrite.Pilot.DynamicIndex.clampStart_full_extent
#print axioms TensorRewrite.Pilot.DynamicIndex.clampStart_full_extent
#check @TensorRewrite.Pilot.DynamicIndex.combinedStart_bounds
#print axioms TensorRewrite.Pilot.DynamicIndex.combinedStart_bounds
#check @TensorRewrite.Pilot.DynamicIndex.coordinate_bounds
#print axioms TensorRewrite.Pilot.DynamicIndex.coordinate_bounds
#check @TensorRewrite.Pilot.DynamicIndex.dynamicSliceIndex_compose
#print axioms TensorRewrite.Pilot.DynamicIndex.dynamicSliceIndex_compose
#check @TensorRewrite.Pilot.DynamicIndex.dynamicSliceIndex_val
#print axioms TensorRewrite.Pilot.DynamicIndex.dynamicSliceIndex_val
#check @TensorRewrite.Pilot.DynamicIndex.dynamicSliceView_constant
#print axioms TensorRewrite.Pilot.DynamicIndex.dynamicSliceView_constant
#check @TensorRewrite.Pilot.DynamicIndex.signedValue_eq_unsignedValue
#print axioms TensorRewrite.Pilot.DynamicIndex.signedValue_eq_unsignedValue
#check @TensorRewrite.Pilot.DynamicIndex.sliceTensor_compose
#print axioms TensorRewrite.Pilot.DynamicIndex.sliceTensor_compose
#check @TensorRewrite.Pilot.DynamicIndex.unsigned64_high_bit_disagrees
#print axioms TensorRewrite.Pilot.DynamicIndex.unsigned64_high_bit_disagrees
#check @TensorRewrite.Pilot.DynamicIndex.unsigned64_max_disagrees
#print axioms TensorRewrite.Pilot.DynamicIndex.unsigned64_max_disagrees
#check @TensorRewrite.Pilot.DynamicIndex.unsigned64_not_universally_equal
#print axioms TensorRewrite.Pilot.DynamicIndex.unsigned64_not_universally_equal
#check @TensorRewrite.Pilot.EffectfulBooleanDag.and_lhs_false
#print axioms TensorRewrite.Pilot.EffectfulBooleanDag.and_lhs_false
#check @TensorRewrite.Pilot.EffectfulBooleanDag.and_lhs_true
#print axioms TensorRewrite.Pilot.EffectfulBooleanDag.and_lhs_true
#check @TensorRewrite.Pilot.EffectfulBooleanDag.and_rhs_false
#print axioms TensorRewrite.Pilot.EffectfulBooleanDag.and_rhs_false
#check @TensorRewrite.Pilot.EffectfulBooleanDag.and_rhs_true
#print axioms TensorRewrite.Pilot.EffectfulBooleanDag.and_rhs_true
#check @TensorRewrite.Pilot.EffectfulBooleanDag.eval_delete_of_pure
#print axioms TensorRewrite.Pilot.EffectfulBooleanDag.eval_delete_of_pure
#check @TensorRewrite.Pilot.EffectfulBooleanDag.eval_replace_of_pure
#print axioms TensorRewrite.Pilot.EffectfulBooleanDag.eval_replace_of_pure
#check @TensorRewrite.Pilot.EffectfulBooleanDag.not_not
#print axioms TensorRewrite.Pilot.EffectfulBooleanDag.not_not
#check @TensorRewrite.Pilot.EffectfulBooleanDag.or_lhs_false
#print axioms TensorRewrite.Pilot.EffectfulBooleanDag.or_lhs_false
#check @TensorRewrite.Pilot.EffectfulBooleanDag.or_lhs_true
#print axioms TensorRewrite.Pilot.EffectfulBooleanDag.or_lhs_true
#check @TensorRewrite.Pilot.EffectfulBooleanDag.or_rhs_false
#print axioms TensorRewrite.Pilot.EffectfulBooleanDag.or_rhs_false
#check @TensorRewrite.Pilot.EffectfulBooleanDag.or_rhs_true
#print axioms TensorRewrite.Pilot.EffectfulBooleanDag.or_rhs_true
#check @TensorRewrite.Pilot.EffectfulBooleanDag.xor_lhs_false
#print axioms TensorRewrite.Pilot.EffectfulBooleanDag.xor_lhs_false
#check @TensorRewrite.Pilot.EffectfulBooleanDag.xor_rhs_false
#print axioms TensorRewrite.Pilot.EffectfulBooleanDag.xor_rhs_false
#check @TensorRewrite.Pilot.EffectfulBooleanDag.xor_self
#print axioms TensorRewrite.Pilot.EffectfulBooleanDag.xor_self
#check @TensorRewrite.Pilot.FiniteProduct.column_join
#print axioms TensorRewrite.Pilot.FiniteProduct.column_join
#check @TensorRewrite.Pilot.FiniteProduct.join_row_column
#print axioms TensorRewrite.Pilot.FiniteProduct.join_row_column
#check @TensorRewrite.Pilot.FiniteProduct.row_join
#print axioms TensorRewrite.Pilot.FiniteProduct.row_join
#check @TensorRewrite.Pilot.Float32Exceptional.any_refining_relation_rejects
#print axioms TensorRewrite.Pilot.Float32Exceptional.any_refining_relation_rejects
#check @TensorRewrite.Pilot.Float32Exceptional.canonical_nan_allowed
#print axioms TensorRewrite.Pilot.Float32Exceptional.canonical_nan_allowed
#check @TensorRewrite.Pilot.Float32Exceptional.every_compliant_mul_differs
#print axioms TensorRewrite.Pilot.Float32Exceptional.every_compliant_mul_differs
#check @TensorRewrite.Pilot.Float32Exceptional.false_inf_refutes
#print axioms TensorRewrite.Pilot.Float32Exceptional.false_inf_refutes
#check @TensorRewrite.Pilot.Float32Exceptional.false_nan_refutes
#print axioms TensorRewrite.Pilot.Float32Exceptional.false_nan_refutes
#check @TensorRewrite.Pilot.Float32Exceptional.false_neg_inf_refutes
#print axioms TensorRewrite.Pilot.Float32Exceptional.false_neg_inf_refutes
#check @TensorRewrite.Pilot.Float32Exceptional.false_nonfinite_refutes
#print axioms TensorRewrite.Pilot.Float32Exceptional.false_nonfinite_refutes
#check @TensorRewrite.Pilot.Float32Exceptional.inf_false_refutes
#print axioms TensorRewrite.Pilot.Float32Exceptional.inf_false_refutes
#check @TensorRewrite.Pilot.Float32Exceptional.nan_false_refutes
#print axioms TensorRewrite.Pilot.Float32Exceptional.nan_false_refutes
#check @TensorRewrite.Pilot.Float32Exceptional.neg_inf_false_refutes
#print axioms TensorRewrite.Pilot.Float32Exceptional.neg_inf_false_refutes
#check @TensorRewrite.Pilot.Float32Exceptional.not_universally_valid
#print axioms TensorRewrite.Pilot.Float32Exceptional.not_universally_valid
#check @TensorRewrite.Pilot.Float32Exceptional.scalar_tensor_refutes
#print axioms TensorRewrite.Pilot.Float32Exceptional.scalar_tensor_refutes
#check @TensorRewrite.Pilot.IndexMaps.broadcastIndex_val
#print axioms TensorRewrite.Pilot.IndexMaps.broadcastIndex_val
#check @TensorRewrite.Pilot.IndexMaps.broadcastView_constant
#print axioms TensorRewrite.Pilot.IndexMaps.broadcastView_constant
#check @TensorRewrite.Pilot.IndexMaps.sliceIndex_val
#print axioms TensorRewrite.Pilot.IndexMaps.sliceIndex_val
#check @TensorRewrite.Pilot.IndexMaps.sliceView_constant
#print axioms TensorRewrite.Pilot.IndexMaps.sliceView_constant
#check @TensorRewrite.Pilot.LinearIndex.delinearize_linearize
#print axioms TensorRewrite.Pilot.LinearIndex.delinearize_linearize
#check @TensorRewrite.Pilot.LinearIndex.linearize_delinearize
#print axioms TensorRewrite.Pilot.LinearIndex.linearize_delinearize
#check @TensorRewrite.Pilot.ModularArithmetic.add_assoc
#print axioms TensorRewrite.Pilot.ModularArithmetic.add_assoc
#check @TensorRewrite.Pilot.ModularArithmetic.add_broadcast_assoc
#print axioms TensorRewrite.Pilot.ModularArithmetic.add_broadcast_assoc
#check @TensorRewrite.Pilot.ModularArithmetic.add_comm
#print axioms TensorRewrite.Pilot.ModularArithmetic.add_comm
#check @TensorRewrite.Pilot.ModularArithmetic.add_lhs_zero
#print axioms TensorRewrite.Pilot.ModularArithmetic.add_lhs_zero
#check @TensorRewrite.Pilot.ModularArithmetic.add_rhs_zero
#print axioms TensorRewrite.Pilot.ModularArithmetic.add_rhs_zero
#check @TensorRewrite.Pilot.ModularArithmetic.add_sub_cancel_left
#print axioms TensorRewrite.Pilot.ModularArithmetic.add_sub_cancel_left
#check @TensorRewrite.Pilot.ModularArithmetic.add_sub_cancel_right
#print axioms TensorRewrite.Pilot.ModularArithmetic.add_sub_cancel_right
#check @TensorRewrite.Pilot.ModularArithmetic.broadcast_factor_any_order
#print axioms TensorRewrite.Pilot.ModularArithmetic.broadcast_factor_any_order
#check @TensorRewrite.Pilot.ModularArithmetic.factor_any_order
#print axioms TensorRewrite.Pilot.ModularArithmetic.factor_any_order
#check @TensorRewrite.Pilot.ModularArithmetic.factor_left
#print axioms TensorRewrite.Pilot.ModularArithmetic.factor_left
#check @TensorRewrite.Pilot.ModularArithmetic.factor_right
#print axioms TensorRewrite.Pilot.ModularArithmetic.factor_right
#check @TensorRewrite.Pilot.ModularArithmetic.four_factors
#print axioms TensorRewrite.Pilot.ModularArithmetic.four_factors
#check @TensorRewrite.Pilot.ModularArithmetic.four_factors_any_order
#print axioms TensorRewrite.Pilot.ModularArithmetic.four_factors_any_order
#check @TensorRewrite.Pilot.ModularArithmetic.mul_assoc
#print axioms TensorRewrite.Pilot.ModularArithmetic.mul_assoc
#check @TensorRewrite.Pilot.ModularArithmetic.mul_assoc_any_order
#print axioms TensorRewrite.Pilot.ModularArithmetic.mul_assoc_any_order
#check @TensorRewrite.Pilot.ModularArithmetic.mul_broadcast_assoc
#print axioms TensorRewrite.Pilot.ModularArithmetic.mul_broadcast_assoc
#check @TensorRewrite.Pilot.ModularArithmetic.mul_lhs_one
#print axioms TensorRewrite.Pilot.ModularArithmetic.mul_lhs_one
#check @TensorRewrite.Pilot.ModularArithmetic.mul_lhs_zero
#print axioms TensorRewrite.Pilot.ModularArithmetic.mul_lhs_zero
#check @TensorRewrite.Pilot.ModularArithmetic.mul_neg_neg
#print axioms TensorRewrite.Pilot.ModularArithmetic.mul_neg_neg
#check @TensorRewrite.Pilot.ModularArithmetic.mul_rhs_one
#print axioms TensorRewrite.Pilot.ModularArithmetic.mul_rhs_one
#check @TensorRewrite.Pilot.ModularArithmetic.mul_rhs_zero
#print axioms TensorRewrite.Pilot.ModularArithmetic.mul_rhs_zero
#check @TensorRewrite.Pilot.ModularArithmetic.sub_add_broadcast
#print axioms TensorRewrite.Pilot.ModularArithmetic.sub_add_broadcast
#check @TensorRewrite.Pilot.ModularArithmetic.sub_add_constant
#print axioms TensorRewrite.Pilot.ModularArithmetic.sub_add_constant
#check @TensorRewrite.Pilot.NestedUnsigned64.both_high_changes
#print axioms TensorRewrite.Pilot.NestedUnsigned64.both_high_changes
#check @TensorRewrite.Pilot.NestedUnsigned64.inner_high_changes
#print axioms TensorRewrite.Pilot.NestedUnsigned64.inner_high_changes
#check @TensorRewrite.Pilot.NestedUnsigned64.not_universally_preserving
#print axioms TensorRewrite.Pilot.NestedUnsigned64.not_universally_preserving
#check @TensorRewrite.Pilot.NestedUnsigned64.outer_high_changes
#print axioms TensorRewrite.Pilot.NestedUnsigned64.outer_high_changes
#check @TensorRewrite.Pilot.OperandOrder.map₂_eq
#print axioms TensorRewrite.Pilot.OperandOrder.map₂_eq
#check @TensorRewrite.Pilot.OrderedCompareProfile.false_consistent
#print axioms TensorRewrite.Pilot.OrderedCompareProfile.false_consistent
#check @TensorRewrite.Pilot.OrderedCompareProfile.quiet_nan_is_nan
#print axioms TensorRewrite.Pilot.OrderedCompareProfile.quiet_nan_is_nan
#check @TensorRewrite.Pilot.OrderedCompareProfile.quiet_nan_left_refutes
#print axioms TensorRewrite.Pilot.OrderedCompareProfile.quiet_nan_left_refutes
#check @TensorRewrite.Pilot.OrderedCompareProfile.quiet_nan_right_refutes
#print axioms TensorRewrite.Pilot.OrderedCompareProfile.quiet_nan_right_refutes
#check @TensorRewrite.Pilot.OrderedCompareProfile.true_incompatible_of_left_nan
#print axioms TensorRewrite.Pilot.OrderedCompareProfile.true_incompatible_of_left_nan
#check @TensorRewrite.Pilot.OrderedCompareProfile.true_incompatible_of_right_nan
#print axioms TensorRewrite.Pilot.OrderedCompareProfile.true_incompatible_of_right_nan
#check @TensorRewrite.Pilot.PromotedWordArithmetic.narrow_ofInt
#print axioms TensorRewrite.Pilot.PromotedWordArithmetic.narrow_ofInt
#check @TensorRewrite.Pilot.PromotedWordArithmetic.promoted_add
#print axioms TensorRewrite.Pilot.PromotedWordArithmetic.promoted_add
#check @TensorRewrite.Pilot.PromotedWordArithmetic.promoted_mul
#print axioms TensorRewrite.Pilot.PromotedWordArithmetic.promoted_mul
#check @TensorRewrite.Pilot.PromotedWordArithmetic.promoted_neg
#print axioms TensorRewrite.Pilot.PromotedWordArithmetic.promoted_neg
#check @TensorRewrite.Pilot.PromotedWordArithmetic.promoted_sub
#print axioms TensorRewrite.Pilot.PromotedWordArithmetic.promoted_sub
#check @TensorRewrite.Pilot.PromotedWordArithmetic.signed_cast_narrow
#print axioms TensorRewrite.Pilot.PromotedWordArithmetic.signed_cast_narrow
#check @TensorRewrite.Pilot.PromotedWordArithmetic.signed_promotion_exact
#print axioms TensorRewrite.Pilot.PromotedWordArithmetic.signed_promotion_exact
#check @TensorRewrite.Pilot.PromotedWordArithmetic.tensor_signed_decode_injective
#print axioms TensorRewrite.Pilot.PromotedWordArithmetic.tensor_signed_decode_injective
#check @TensorRewrite.Pilot.ReducerIndex.GatherLiterals.literal_128_narrows
#print axioms TensorRewrite.Pilot.ReducerIndex.GatherLiterals.literal_128_narrows
#check @TensorRewrite.Pilot.ReducerIndex.GatherLiterals.maximum_index_changes
#print axioms TensorRewrite.Pilot.ReducerIndex.GatherLiterals.maximum_index_changes
#check @TensorRewrite.Pilot.ReducerIndex.GatherLiterals.negative_index_changes
#print axioms TensorRewrite.Pilot.ReducerIndex.GatherLiterals.negative_index_changes
#check @TensorRewrite.Pilot.ReducerIndex.GatherLiterals.not_universally_preserving
#print axioms TensorRewrite.Pilot.ReducerIndex.GatherLiterals.not_universally_preserving
#check @TensorRewrite.Pilot.ReducerIndex.GatherLiterals.selectedIndex_eq_original
#print axioms TensorRewrite.Pilot.ReducerIndex.GatherLiterals.selectedIndex_eq_original
#check @TensorRewrite.Pilot.ReducerIndex.GatherLiterals.zero_index_changes
#print axioms TensorRewrite.Pilot.ReducerIndex.GatherLiterals.zero_index_changes
#check @TensorRewrite.Pilot.ReducerIndex.ScatterRoles.current_update_preserves
#print axioms TensorRewrite.Pilot.ReducerIndex.ScatterRoles.current_update_preserves
#check @TensorRewrite.Pilot.ReducerIndex.ScatterRoles.distinct_parameters_preserve
#print axioms TensorRewrite.Pilot.ReducerIndex.ScatterRoles.distinct_parameters_preserve
#check @TensorRewrite.Pilot.ReducerIndex.ScatterRoles.not_universally_preserving
#print axioms TensorRewrite.Pilot.ReducerIndex.ScatterRoles.not_universally_preserving
#check @TensorRewrite.Pilot.ReducerIndex.ScatterRoles.repeated_current_changes
#print axioms TensorRewrite.Pilot.ReducerIndex.ScatterRoles.repeated_current_changes
#check @TensorRewrite.Pilot.ReducerIndex.ScatterRoles.repeated_update_changes
#print axioms TensorRewrite.Pilot.ReducerIndex.ScatterRoles.repeated_update_changes
#check @TensorRewrite.Pilot.ReducerIndex.ScatterRoles.update_current_preserves
#print axioms TensorRewrite.Pilot.ReducerIndex.ScatterRoles.update_current_preserves
#check @TensorRewrite.Pilot.Reduction.elementCount_eq_of_units
#print axioms TensorRewrite.Pilot.Reduction.elementCount_eq_of_units
#check @TensorRewrite.Pilot.Reduction.elementCount_factor
#print axioms TensorRewrite.Pilot.Reduction.elementCount_factor
#check @TensorRewrite.Pilot.Reduction.fiberCount_one_of_sameCount
#print axioms TensorRewrite.Pilot.Reduction.fiberCount_one_of_sameCount
#check @TensorRewrite.Pilot.Reduction.fiberValues_length
#print axioms TensorRewrite.Pilot.Reduction.fiberValues_length
#check @TensorRewrite.Pilot.Reduction.fiberValues_unit
#print axioms TensorRewrite.Pilot.Reduction.fiberValues_unit
#check @TensorRewrite.Pilot.Reduction.length_flatMap_constant
#print axioms TensorRewrite.Pilot.Reduction.length_flatMap_constant
#check @TensorRewrite.Pilot.Reduction.reduceTensor_empty_input
#print axioms TensorRewrite.Pilot.Reduction.reduceTensor_empty_input
#check @TensorRewrite.Pilot.Reduction.reduceTensor_empty_output
#print axioms TensorRewrite.Pilot.Reduction.reduceTensor_empty_output
#check @TensorRewrite.Pilot.Reduction.reduceTensor_sameCount
#print axioms TensorRewrite.Pilot.Reduction.reduceTensor_sameCount
#check @TensorRewrite.Pilot.Reduction.unitIndex_eq_reshapeIndex
#print axioms TensorRewrite.Pilot.Reduction.unitIndex_eq_reshapeIndex
#check @TensorRewrite.Pilot.Reduction.unitIndex_linearize_val
#print axioms TensorRewrite.Pilot.Reduction.unitIndex_linearize_val
#check @TensorRewrite.Pilot.Reduction.unitReducedAxes_of_fiberCount_one
#print axioms TensorRewrite.Pilot.Reduction.unitReducedAxes_of_fiberCount_one
#check @TensorRewrite.Pilot.Reshape.reshapeIndex_compose
#print axioms TensorRewrite.Pilot.Reshape.reshapeIndex_compose
#check @TensorRewrite.Pilot.Reshape.reshapeTensor_compose
#print axioms TensorRewrite.Pilot.Reshape.reshapeTensor_compose
#check @TensorRewrite.Pilot.Reshape.reshapeTensor_empty
#print axioms TensorRewrite.Pilot.Reshape.reshapeTensor_empty
#check @TensorRewrite.Pilot.Reshape.reshapeTensor_identity
#print axioms TensorRewrite.Pilot.Reshape.reshapeTensor_identity
#check @TensorRewrite.Pilot.Reshape.reshapeView_constant
#print axioms TensorRewrite.Pilot.Reshape.reshapeView_constant
#check @TensorRewrite.Pilot.Reshape.tensor_eq_of_empty
#print axioms TensorRewrite.Pilot.Reshape.tensor_eq_of_empty
#check @TensorRewrite.Pilot.Reverse.reverse_axisMask_trivial
#print axioms TensorRewrite.Pilot.Reverse.reverse_axisMask_trivial
#check @TensorRewrite.Pilot.Reverse.reverse_binary_constant_lhs
#print axioms TensorRewrite.Pilot.Reverse.reverse_binary_constant_lhs
#check @TensorRewrite.Pilot.Reverse.reverse_binary_constant_rhs
#print axioms TensorRewrite.Pilot.Reverse.reverse_binary_constant_rhs
#check @TensorRewrite.Pilot.Reverse.reverse_comp
#print axioms TensorRewrite.Pilot.Reverse.reverse_comp
#check @TensorRewrite.Pilot.Reverse.reverse_constant
#print axioms TensorRewrite.Pilot.Reverse.reverse_constant
#check @TensorRewrite.Pilot.Reverse.reverse_map₂
#print axioms TensorRewrite.Pilot.Reverse.reverse_map₂
#check @TensorRewrite.Pilot.Reverse.reverse_reverse
#print axioms TensorRewrite.Pilot.Reverse.reverse_reverse
#check @TensorRewrite.Pilot.Reverse.reverse_trivial
#print axioms TensorRewrite.Pilot.Reverse.reverse_trivial
#check @TensorRewrite.Pilot.ScaledNestedSlice.changes_of_not_fixed
#print axioms TensorRewrite.Pilot.ScaledNestedSlice.changes_of_not_fixed
#check @TensorRewrite.Pilot.ScaledNestedSlice.multiplier_seven_changes
#print axioms TensorRewrite.Pilot.ScaledNestedSlice.multiplier_seven_changes
#check @TensorRewrite.Pilot.ScaledNestedSlice.negative_multiplier_changes
#print axioms TensorRewrite.Pilot.ScaledNestedSlice.negative_multiplier_changes
#check @TensorRewrite.Pilot.ScaledNestedSlice.not_universally_preserving
#print axioms TensorRewrite.Pilot.ScaledNestedSlice.not_universally_preserving
#check @TensorRewrite.Pilot.ScaledNestedSlice.original_witness
#print axioms TensorRewrite.Pilot.ScaledNestedSlice.original_witness
#check @TensorRewrite.Pilot.ScaledNestedSlice.rewritten_witness
#print axioms TensorRewrite.Pilot.ScaledNestedSlice.rewritten_witness
#check @TensorRewrite.Pilot.ScaledNestedSlice.zero_multiplier_changes
#print axioms TensorRewrite.Pilot.ScaledNestedSlice.zero_multiplier_changes
#check @TensorRewrite.Pilot.SelectContraction.branchContraction_eq
#print axioms TensorRewrite.Pilot.SelectContraction.branchContraction_eq
#check @TensorRewrite.Pilot.SelectContraction.false_witness
#print axioms TensorRewrite.Pilot.SelectContraction.false_witness
#check @TensorRewrite.Pilot.SelectContraction.hoistedContraction_eq
#print axioms TensorRewrite.Pilot.SelectContraction.hoistedContraction_eq
#check @TensorRewrite.Pilot.SelectContraction.nonzero_sum_refutes
#print axioms TensorRewrite.Pilot.SelectContraction.nonzero_sum_refutes
#check @TensorRewrite.Pilot.SelectContraction.not_universally_valid
#print axioms TensorRewrite.Pilot.SelectContraction.not_universally_valid
#check @TensorRewrite.Pilot.SelectContraction.true_witness
#print axioms TensorRewrite.Pilot.SelectContraction.true_witness
#check @TensorRewrite.Pilot.SliceShape.coordinate_bounds
#print axioms TensorRewrite.Pilot.SliceShape.coordinate_bounds
#check @TensorRewrite.Pilot.SliceShape.empty_witness_well_formed
#print axioms TensorRewrite.Pilot.SliceShape.empty_witness_well_formed
#check @TensorRewrite.Pilot.SliceShape.remove_redundant_stride_not_preserving
#print axioms TensorRewrite.Pilot.SliceShape.remove_redundant_stride_not_preserving
#check @TensorRewrite.Pilot.SliceShape.remove_redundant_stride_refutes
#print axioms TensorRewrite.Pilot.SliceShape.remove_redundant_stride_refutes
#check @TensorRewrite.Pilot.SliceShape.remove_redundant_stride_witness
#print axioms TensorRewrite.Pilot.SliceShape.remove_redundant_stride_witness
#check @TensorRewrite.Pilot.SliceShape.reorder_reverse_not_preserving
#print axioms TensorRewrite.Pilot.SliceShape.reorder_reverse_not_preserving
#check @TensorRewrite.Pilot.SliceShape.reorder_reverse_refutes
#print axioms TensorRewrite.Pilot.SliceShape.reorder_reverse_refutes
#check @TensorRewrite.Pilot.SliceShape.reorder_reverse_witness
#print axioms TensorRewrite.Pilot.SliceShape.reorder_reverse_witness
#check @TensorRewrite.Pilot.Subtract.add_sub_self_left
#print axioms TensorRewrite.Pilot.Subtract.add_sub_self_left
#check @TensorRewrite.Pilot.Subtract.add_sub_self_right
#print axioms TensorRewrite.Pilot.Subtract.add_sub_self_right
#check @TensorRewrite.Pilot.Subtract.neg_neg
#print axioms TensorRewrite.Pilot.Subtract.neg_neg
#check @TensorRewrite.Pilot.Subtract.sub_add_self_left
#print axioms TensorRewrite.Pilot.Subtract.sub_add_self_left
#check @TensorRewrite.Pilot.Subtract.sub_add_self_right
#print axioms TensorRewrite.Pilot.Subtract.sub_add_self_right
#check @TensorRewrite.Pilot.Subtract.sub_broadcast_eq_add_neg
#print axioms TensorRewrite.Pilot.Subtract.sub_broadcast_eq_add_neg
#check @TensorRewrite.Pilot.Subtract.sub_eq_add_neg
#print axioms TensorRewrite.Pilot.Subtract.sub_eq_add_neg
#check @TensorRewrite.Pilot.Subtract.sub_self
#print axioms TensorRewrite.Pilot.Subtract.sub_self
#check @TensorRewrite.Pilot.Subtract.sub_sub_self
#print axioms TensorRewrite.Pilot.Subtract.sub_sub_self
#check @TensorRewrite.Pilot.Subtract.sub_zero
#print axioms TensorRewrite.Pilot.Subtract.sub_zero
#check @TensorRewrite.Pilot.Tensor.reindex_constant
#print axioms TensorRewrite.Pilot.Tensor.reindex_constant
#check @TensorRewrite.Pilot.Tensor.reindex_map₂
#print axioms TensorRewrite.Pilot.Tensor.reindex_map₂
#check @TensorRewrite.Pilot.Tensor.reverseIndex_comp
#print axioms TensorRewrite.Pilot.Tensor.reverseIndex_comp
#check @TensorRewrite.Pilot.Tensor.reverseIndex_reverseIndex
#print axioms TensorRewrite.Pilot.Tensor.reverseIndex_reverseIndex
#check @TensorRewrite.Pilot.Transpose.transpose_comp
#print axioms TensorRewrite.Pilot.Transpose.transpose_comp
#check @TensorRewrite.Pilot.Transpose.transpose_constant
#print axioms TensorRewrite.Pilot.Transpose.transpose_constant
#check @TensorRewrite.Pilot.Transpose.transpose_identity
#print axioms TensorRewrite.Pilot.Transpose.transpose_identity
#check @TensorRewrite.Pilot.ZeroMacProfile.negative_zero_incompatible
#print axioms TensorRewrite.Pilot.ZeroMacProfile.negative_zero_incompatible
#check @TensorRewrite.Pilot.ZeroMacProfile.one_mac_positive
#print axioms TensorRewrite.Pilot.ZeroMacProfile.one_mac_positive
#check @TensorRewrite.Pilot.ZeroMacProfile.positive_zero_consistent
#print axioms TensorRewrite.Pilot.ZeroMacProfile.positive_zero_consistent
#check @TensorRewrite.Pilot.ZeroMacProfile.zero_bits_differ
#print axioms TensorRewrite.Pilot.ZeroMacProfile.zero_bits_differ
#check @TensorRewrite.Theory.BroadcastWindow.axesMap_strictMono
#print axioms TensorRewrite.Theory.BroadcastWindow.axesMap_strictMono
#check @TensorRewrite.Theory.BroadcastWindow.axes_decode
#print axioms TensorRewrite.Theory.BroadcastWindow.axes_decode
#check @TensorRewrite.Theory.BroadcastWindow.axes_extent
#print axioms TensorRewrite.Theory.BroadcastWindow.axes_extent
#check @TensorRewrite.Theory.BroadcastWindow.axis_kernel_unique
#print axioms TensorRewrite.Theory.BroadcastWindow.axis_kernel_unique
#check @TensorRewrite.Theory.BroadcastWindow.broadcast_index
#print axioms TensorRewrite.Theory.BroadcastWindow.broadcast_index
#check @TensorRewrite.Theory.BroadcastWindow.compact_count
#print axioms TensorRewrite.Theory.BroadcastWindow.compact_count
#check @TensorRewrite.Theory.BroadcastWindow.compact_index_value
#print axioms TensorRewrite.Theory.BroadcastWindow.compact_index_value
#check @TensorRewrite.Theory.BroadcastWindow.contribution_at_position
#print axioms TensorRewrite.Theory.BroadcastWindow.contribution_at_position
#check @TensorRewrite.Theory.BroadcastWindow.coupled_projection_refuted
#print axioms TensorRewrite.Theory.BroadcastWindow.coupled_projection_refuted
#check @TensorRewrite.Theory.BroadcastWindow.covered_offset
#print axioms TensorRewrite.Theory.BroadcastWindow.covered_offset
#check @TensorRewrite.Theory.BroadcastWindow.expansion_live_position
#print axioms TensorRewrite.Theory.BroadcastWindow.expansion_live_position
#check @TensorRewrite.Theory.BroadcastWindow.expansion_sample
#print axioms TensorRewrite.Theory.BroadcastWindow.expansion_sample
#check @TensorRewrite.Theory.BroadcastWindow.expansion_unique
#print axioms TensorRewrite.Theory.BroadcastWindow.expansion_unique
#check @TensorRewrite.Theory.BroadcastWindow.foldl_single_live
#print axioms TensorRewrite.Theory.BroadcastWindow.foldl_single_live
#check @TensorRewrite.Theory.BroadcastWindow.linearize_expand
#print axioms TensorRewrite.Theory.BroadcastWindow.linearize_expand
#check @TensorRewrite.Theory.BroadcastWindow.live_axis_sample
#print axioms TensorRewrite.Theory.BroadcastWindow.live_axis_sample
#check @TensorRewrite.Theory.BroadcastWindow.nonneutral_reducer_refuted
#print axioms TensorRewrite.Theory.BroadcastWindow.nonneutral_reducer_refuted
#check @TensorRewrite.Theory.BroadcastWindow.reduce_converted_sequence
#print axioms TensorRewrite.Theory.BroadcastWindow.reduce_converted_sequence
#check @TensorRewrite.Theory.BroadcastWindow.reduce_sequence
#print axioms TensorRewrite.Theory.BroadcastWindow.reduce_sequence
#check @TensorRewrite.Theory.BroadcastWindow.reduce_source
#print axioms TensorRewrite.Theory.BroadcastWindow.reduce_source
#check @TensorRewrite.Theory.BroadcastWindow.reshape_index
#print axioms TensorRewrite.Theory.BroadcastWindow.reshape_index
#check @TensorRewrite.Theory.BroadcastWindow.sample_if
#print axioms TensorRewrite.Theory.BroadcastWindow.sample_if
#check @TensorRewrite.Theory.BroadcastWindow.sample_live
#print axioms TensorRewrite.Theory.BroadcastWindow.sample_live
#check @TensorRewrite.Theory.BroadcastWindow.sequence_map
#print axioms TensorRewrite.Theory.BroadcastWindow.sequence_map
#check @TensorRewrite.Theory.BroadcastWindow.sequence_value
#print axioms TensorRewrite.Theory.BroadcastWindow.sequence_value
#check @TensorRewrite.Theory.BroadcastWindow.uncovered_output_refuted
#print axioms TensorRewrite.Theory.BroadcastWindow.uncovered_output_refuted
#check @TensorRewrite.Theory.ContractionAlgebra.dot_add_left
#print axioms TensorRewrite.Theory.ContractionAlgebra.dot_add_left
#check @TensorRewrite.Theory.ContractionAlgebra.dot_add_right
#print axioms TensorRewrite.Theory.ContractionAlgebra.dot_add_right
#check @TensorRewrite.Theory.Convolution.basePosition_reverse
#print axioms TensorRewrite.Theory.Convolution.basePosition_reverse
#check @TensorRewrite.Theory.Convolution.convolve_bias_scale
#print axioms TensorRewrite.Theory.Convolution.convolve_bias_scale
#check @TensorRewrite.Theory.Convolution.convolve_empty_fiber
#print axioms TensorRewrite.Theory.Convolution.convolve_empty_fiber
#check @TensorRewrite.Theory.Convolution.convolve_empty_kernel
#print axioms TensorRewrite.Theory.Convolution.convolve_empty_kernel
#check @TensorRewrite.Theory.Convolution.convolve_empty_spatial_input
#print axioms TensorRewrite.Theory.Convolution.convolve_empty_spatial_input
#check @TensorRewrite.Theory.Convolution.convolve_input_add
#print axioms TensorRewrite.Theory.Convolution.convolve_input_add
#check @TensorRewrite.Theory.Convolution.convolve_kernel_add
#print axioms TensorRewrite.Theory.Convolution.convolve_kernel_add
#check @TensorRewrite.Theory.Convolution.convolve_kernel_scale
#print axioms TensorRewrite.Theory.Convolution.convolve_kernel_scale
#check @TensorRewrite.Theory.Convolution.convolve_no_channels
#print axioms TensorRewrite.Theory.Convolution.convolve_no_channels
#check @TensorRewrite.Theory.Convolution.convolve_zero_input
#print axioms TensorRewrite.Theory.Convolution.convolve_zero_input
#check @TensorRewrite.Theory.Convolution.convolve_zero_kernel
#print axioms TensorRewrite.Theory.Convolution.convolve_zero_kernel
#check @TensorRewrite.Theory.Convolution.inputIndex?_negative
#print axioms TensorRewrite.Theory.Convolution.inputIndex?_negative
#check @TensorRewrite.Theory.Convolution.inputIndex?_position
#print axioms TensorRewrite.Theory.Convolution.inputIndex?_position
#check @TensorRewrite.Theory.Convolution.spatialInput?_empty
#print axioms TensorRewrite.Theory.Convolution.spatialInput?_empty
#check @TensorRewrite.Theory.Convolution.term_empty_spatial_input
#print axioms TensorRewrite.Theory.Convolution.term_empty_spatial_input
#check @TensorRewrite.Theory.Convolution.term_input_add
#print axioms TensorRewrite.Theory.Convolution.term_input_add
#check @TensorRewrite.Theory.Convolution.term_kernel_add
#print axioms TensorRewrite.Theory.Convolution.term_kernel_add
#check @TensorRewrite.Theory.Convolution.term_kernel_scale
#print axioms TensorRewrite.Theory.Convolution.term_kernel_scale
#check @TensorRewrite.Theory.Convolution.term_zero_input
#print axioms TensorRewrite.Theory.Convolution.term_zero_input
#check @TensorRewrite.Theory.Convolution.term_zero_kernel
#print axioms TensorRewrite.Theory.Convolution.term_zero_kernel
#check @TensorRewrite.Theory.ConvolutionDot.convolution_output_dot_output
#print axioms TensorRewrite.Theory.ConvolutionDot.convolution_output_dot_output
#check @TensorRewrite.Theory.ConvolutionDot.convolve_eq_dot
#print axioms TensorRewrite.Theory.ConvolutionDot.convolve_eq_dot
#check @TensorRewrite.Theory.ConvolutionDot.dot_eq_channel_sum
#print axioms TensorRewrite.Theory.ConvolutionDot.dot_eq_channel_sum
#check @TensorRewrite.Theory.ConvolutionDot.dot_eq_convolve
#print axioms TensorRewrite.Theory.ConvolutionDot.dot_eq_convolve
#check @TensorRewrite.Theory.ConvolutionDot.dot_output_convolution_output
#print axioms TensorRewrite.Theory.ConvolutionDot.dot_output_convolution_output
#check @TensorRewrite.Theory.ConvolutionDot.lhs_index_channel
#print axioms TensorRewrite.Theory.ConvolutionDot.lhs_index_channel
#check @TensorRewrite.Theory.ConvolutionDot.lhs_index_row
#print axioms TensorRewrite.Theory.ConvolutionDot.lhs_index_row
#check @TensorRewrite.Theory.ConvolutionDot.matrix_output_feature
#print axioms TensorRewrite.Theory.ConvolutionDot.matrix_output_feature
#check @TensorRewrite.Theory.ConvolutionDot.matrix_output_row
#print axioms TensorRewrite.Theory.ConvolutionDot.matrix_output_row
#check @TensorRewrite.Theory.ConvolutionDot.rhs_index_channel
#print axioms TensorRewrite.Theory.ConvolutionDot.rhs_index_channel
#check @TensorRewrite.Theory.ConvolutionDot.rhs_index_feature
#print axioms TensorRewrite.Theory.ConvolutionDot.rhs_index_feature
#check @TensorRewrite.Theory.ConvolutionDot.sum_contract_positions
#print axioms TensorRewrite.Theory.ConvolutionDot.sum_contract_positions
#check @TensorRewrite.Theory.ConvolutionFloat.binary32_fold_omission_refuted
#print axioms TensorRewrite.Theory.ConvolutionFloat.binary32_fold_omission_refuted
#check @TensorRewrite.Theory.ConvolutionFloat.binary32_pointwise_dot
#print axioms TensorRewrite.Theory.ConvolutionFloat.binary32_pointwise_dot
#check @TensorRewrite.Theory.ConvolutionFloat.binary32_reference_eq
#print axioms TensorRewrite.Theory.ConvolutionFloat.binary32_reference_eq
#check @TensorRewrite.Theory.ConvolutionFloat.binary32_reversal_refuted
#print axioms TensorRewrite.Theory.ConvolutionFloat.binary32_reversal_refuted
#check @TensorRewrite.Theory.ConvolutionOrdered.channel_position_eq
#print axioms TensorRewrite.Theory.ConvolutionOrdered.channel_position_eq
#check @TensorRewrite.Theory.ConvolutionOrdered.contribution_count_eq
#print axioms TensorRewrite.Theory.ConvolutionOrdered.contribution_count_eq
#check @TensorRewrite.Theory.ConvolutionOrdered.convolve_eq_dot
#print axioms TensorRewrite.Theory.ConvolutionOrdered.convolve_eq_dot
#check @TensorRewrite.Theory.ConvolutionOrdered.convolve_semiring
#print axioms TensorRewrite.Theory.ConvolutionOrdered.convolve_semiring
#check @TensorRewrite.Theory.ConvolutionOrdered.convolve_single_channel
#print axioms TensorRewrite.Theory.ConvolutionOrdered.convolve_single_channel
#check @TensorRewrite.Theory.ConvolutionOrdered.dot_eq_convolve
#print axioms TensorRewrite.Theory.ConvolutionOrdered.dot_eq_convolve
#check @TensorRewrite.Theory.ConvolutionOrdered.map_finRange_cast
#print axioms TensorRewrite.Theory.ConvolutionOrdered.map_finRange_cast
#check @TensorRewrite.Theory.ConvolutionOrdered.map_finRange_singleton
#print axioms TensorRewrite.Theory.ConvolutionOrdered.map_finRange_singleton
#check @TensorRewrite.Theory.ConvolutionOrdered.term_eq_dot_product
#print axioms TensorRewrite.Theory.ConvolutionOrdered.term_eq_dot_product
#check @TensorRewrite.Theory.ConvolutionOrdered.term_pointwise
#print axioms TensorRewrite.Theory.ConvolutionOrdered.term_pointwise
#check @TensorRewrite.Theory.ConvolutionOrdered.terms_eq_dot_terms
#print axioms TensorRewrite.Theory.ConvolutionOrdered.terms_eq_dot_terms
#check @TensorRewrite.Theory.ConvolutionPointwise.axis_inputIndex_eq
#print axioms TensorRewrite.Theory.ConvolutionPointwise.axis_inputIndex_eq
#check @TensorRewrite.Theory.ConvolutionPointwise.base_position_eq
#print axioms TensorRewrite.Theory.ConvolutionPointwise.base_position_eq
#check @TensorRewrite.Theory.ConvolutionPointwise.convolve_eq_channelSum
#print axioms TensorRewrite.Theory.ConvolutionPointwise.convolve_eq_channelSum
#check @TensorRewrite.Theory.ConvolutionPointwise.convolve_single_channel
#print axioms TensorRewrite.Theory.ConvolutionPointwise.convolve_single_channel
#check @TensorRewrite.Theory.ConvolutionPointwise.dilatedExtent_one
#print axioms TensorRewrite.Theory.ConvolutionPointwise.dilatedExtent_one
#check @TensorRewrite.Theory.ConvolutionPointwise.elementCount_unit
#print axioms TensorRewrite.Theory.ConvolutionPointwise.elementCount_unit
#check @TensorRewrite.Theory.ConvolutionPointwise.kernel_count_eq_one
#print axioms TensorRewrite.Theory.ConvolutionPointwise.kernel_count_eq_one
#check @TensorRewrite.Theory.ConvolutionPointwise.kernel_index_unique
#print axioms TensorRewrite.Theory.ConvolutionPointwise.kernel_index_unique
#check @TensorRewrite.Theory.ConvolutionPointwise.output_extent_eq
#print axioms TensorRewrite.Theory.ConvolutionPointwise.output_extent_eq
#check @TensorRewrite.Theory.ConvolutionPointwise.output_shape_eq
#print axioms TensorRewrite.Theory.ConvolutionPointwise.output_shape_eq
#check @TensorRewrite.Theory.ConvolutionPointwise.spatial_input_eq
#print axioms TensorRewrite.Theory.ConvolutionPointwise.spatial_input_eq
#check @TensorRewrite.Theory.ConvolutionPointwise.sum_kernel_positions
#print axioms TensorRewrite.Theory.ConvolutionPointwise.sum_kernel_positions
#check @TensorRewrite.Theory.ConvolutionPointwise.term_pointwise
#print axioms TensorRewrite.Theory.ConvolutionPointwise.term_pointwise
#check @TensorRewrite.Theory.ConvolutionSeparable.axis_inputIndex_eq
#print axioms TensorRewrite.Theory.ConvolutionSeparable.axis_inputIndex_eq
#check @TensorRewrite.Theory.ConvolutionSeparable.convolve_eq_productReduction
#print axioms TensorRewrite.Theory.ConvolutionSeparable.convolve_eq_productReduction
#check @TensorRewrite.Theory.ConvolutionSeparable.derive_geometry
#print axioms TensorRewrite.Theory.ConvolutionSeparable.derive_geometry
#check @TensorRewrite.Theory.ConvolutionSeparable.expand_project
#print axioms TensorRewrite.Theory.ConvolutionSeparable.expand_project
#check @TensorRewrite.Theory.ConvolutionSeparable.output_extent_formula
#print axioms TensorRewrite.Theory.ConvolutionSeparable.output_extent_formula
#check @TensorRewrite.Theory.ConvolutionSeparable.project_expand
#print axioms TensorRewrite.Theory.ConvolutionSeparable.project_expand
#check @TensorRewrite.Theory.ConvolutionSeparable.reduced_position_apply
#print axioms TensorRewrite.Theory.ConvolutionSeparable.reduced_position_apply
#check @TensorRewrite.Theory.ConvolutionSeparable.reverse_involution
#print axioms TensorRewrite.Theory.ConvolutionSeparable.reverse_involution
#check @TensorRewrite.Theory.ConvolutionSeparable.spanning_extent_eq
#print axioms TensorRewrite.Theory.ConvolutionSeparable.spanning_extent_eq
#check @TensorRewrite.Theory.ConvolutionSeparable.spatial_input_eq
#print axioms TensorRewrite.Theory.ConvolutionSeparable.spatial_input_eq
#check @TensorRewrite.Theory.ConvolutionSeparable.term_reduced
#print axioms TensorRewrite.Theory.ConvolutionSeparable.term_reduced
#check @TensorRewrite.Theory.FiniteSum.foldl_add_eq_sum
#print axioms TensorRewrite.Theory.FiniteSum.foldl_add_eq_sum
#check @TensorRewrite.Theory.FiniteSum.reduce_add_eq_fiber_sum
#print axioms TensorRewrite.Theory.FiniteSum.reduce_add_eq_fiber_sum
#check @TensorRewrite.Theory.FiniteSum.reshapeEquiv_apply
#print axioms TensorRewrite.Theory.FiniteSum.reshapeEquiv_apply
#check @TensorRewrite.Theory.FiniteSum.sum_add
#print axioms TensorRewrite.Theory.FiniteSum.sum_add
#check @TensorRewrite.Theory.FiniteSum.sum_reshape
#print axioms TensorRewrite.Theory.FiniteSum.sum_reshape
#check @TensorRewrite.Theory.FiniteSum.sum_swap
#print axioms TensorRewrite.Theory.FiniteSum.sum_swap
#check @TensorRewrite.Theory.FloatNegation.reindex_neg
#print axioms TensorRewrite.Theory.FloatNegation.reindex_neg
#check @TensorRewrite.Theory.FloatNegation.reverse_neg
#print axioms TensorRewrite.Theory.FloatNegation.reverse_neg
#check @TensorRewrite.Theory.FloatNegation.scalar_involution
#print axioms TensorRewrite.Theory.FloatNegation.scalar_involution
#check @TensorRewrite.Theory.FloatNegation.tensor_involution
#print axioms TensorRewrite.Theory.FloatNegation.tensor_involution
#check @TensorRewrite.Theory.FullSpanWindow.axis_sample
#print axioms TensorRewrite.Theory.FullSpanWindow.axis_sample
#check @TensorRewrite.Theory.FullSpanWindow.input_original
#print axioms TensorRewrite.Theory.FullSpanWindow.input_original
#check @TensorRewrite.Theory.FullSpanWindow.input_shape
#print axioms TensorRewrite.Theory.FullSpanWindow.input_shape
#check @TensorRewrite.Theory.FullSpanWindow.kept_output_extent
#print axioms TensorRewrite.Theory.FullSpanWindow.kept_output_extent
#check @TensorRewrite.Theory.FullSpanWindow.kept_sample
#print axioms TensorRewrite.Theory.FullSpanWindow.kept_sample
#check @TensorRewrite.Theory.FullSpanWindow.original_input
#print axioms TensorRewrite.Theory.FullSpanWindow.original_input
#check @TensorRewrite.Theory.FullSpanWindow.original_reduce_reshape
#print axioms TensorRewrite.Theory.FullSpanWindow.original_reduce_reshape
#check @TensorRewrite.Theory.FullSpanWindow.output_count
#print axioms TensorRewrite.Theory.FullSpanWindow.output_count
#check @TensorRewrite.Theory.FullSpanWindow.output_linearize
#print axioms TensorRewrite.Theory.FullSpanWindow.output_linearize
#check @TensorRewrite.Theory.FullSpanWindow.output_reshape
#print axioms TensorRewrite.Theory.FullSpanWindow.output_reshape
#check @TensorRewrite.Theory.FullSpanWindow.reduce_reshape
#print axioms TensorRewrite.Theory.FullSpanWindow.reduce_reshape
#check @TensorRewrite.Theory.FullSpanWindow.reduced_output_extent
#print axioms TensorRewrite.Theory.FullSpanWindow.reduced_output_extent
#check @TensorRewrite.Theory.FullSpanWindow.reduced_sample
#print axioms TensorRewrite.Theory.FullSpanWindow.reduced_sample
#check @TensorRewrite.Theory.FullSpanWindow.sample_valid
#print axioms TensorRewrite.Theory.FullSpanWindow.sample_valid
#check @TensorRewrite.Theory.FullSpanWindow.sampled_fiber
#print axioms TensorRewrite.Theory.FullSpanWindow.sampled_fiber
#check @TensorRewrite.Theory.FullSpanWindow.values_fiber
#print axioms TensorRewrite.Theory.FullSpanWindow.values_fiber
#check @TensorRewrite.Theory.LatticeIndex.assemble_bind
#print axioms TensorRewrite.Theory.LatticeIndex.assemble_bind
#check @TensorRewrite.Theory.LatticeIndex.assemble_eq_some_iff
#print axioms TensorRewrite.Theory.LatticeIndex.assemble_eq_some_iff
#check @TensorRewrite.Theory.LatticeIndex.decode_eq_some_iff
#print axioms TensorRewrite.Theory.LatticeIndex.decode_eq_some_iff
#check @TensorRewrite.Theory.LatticeIndex.window_eq_some_iff
#print axioms TensorRewrite.Theory.LatticeIndex.window_eq_some_iff
#check @TensorRewrite.Theory.LogicalFamily.allRules_complete
#print axioms TensorRewrite.Theory.LogicalFamily.allRules_complete
#check @TensorRewrite.Theory.LogicalFamily.allRules_nodup
#print axioms TensorRewrite.Theory.LogicalFamily.allRules_nodup
#check @TensorRewrite.Theory.LogicalFamily.predicate_count
#print axioms TensorRewrite.Theory.LogicalFamily.predicate_count
#check @TensorRewrite.Theory.LogicalFamily.rewrite_sound
#print axioms TensorRewrite.Theory.LogicalFamily.rewrite_sound
#check @TensorRewrite.Theory.LogicalFamily.word_count
#print axioms TensorRewrite.Theory.LogicalFamily.word_count
#check @TensorRewrite.Theory.LogicalFamily.word_keys_uniform
#print axioms TensorRewrite.Theory.LogicalFamily.word_keys_uniform
#check @TensorRewrite.Theory.OrderedCoordinates.enumerate_scalar
#print axioms TensorRewrite.Theory.OrderedCoordinates.enumerate_scalar
#check @TensorRewrite.Theory.OrderedCoordinates.enumerate_uncons
#print axioms TensorRewrite.Theory.OrderedCoordinates.enumerate_uncons
#check @TensorRewrite.Theory.OrderedCoordinates.enumerate_uncons_map
#print axioms TensorRewrite.Theory.OrderedCoordinates.enumerate_uncons_map
#check @TensorRewrite.Theory.OrderedCoordinates.map_finRange_mul
#print axioms TensorRewrite.Theory.OrderedCoordinates.map_finRange_mul
#check @TensorRewrite.Theory.PadBroadcast.converted_fill_refuted
#print axioms TensorRewrite.Theory.PadBroadcast.converted_fill_refuted
#check @TensorRewrite.Theory.PadBroadcast.expansion_axis
#print axioms TensorRewrite.Theory.PadBroadcast.expansion_axis
#check @TensorRewrite.Theory.PadBroadcast.expansion_covers
#print axioms TensorRewrite.Theory.PadBroadcast.expansion_covers
#check @TensorRewrite.Theory.PadBroadcast.expansion_output_extent
#print axioms TensorRewrite.Theory.PadBroadcast.expansion_output_extent
#check @TensorRewrite.Theory.PadBroadcast.fused_window
#print axioms TensorRewrite.Theory.PadBroadcast.fused_window
#check @TensorRewrite.Theory.PadBroadcast.kept_pointwise
#print axioms TensorRewrite.Theory.PadBroadcast.kept_pointwise
#check @TensorRewrite.Theory.PadBroadcast.reduce_converted_sequence
#print axioms TensorRewrite.Theory.PadBroadcast.reduce_converted_sequence
#check @TensorRewrite.Theory.PadBroadcast.reduce_sequence
#print axioms TensorRewrite.Theory.PadBroadcast.reduce_sequence
#check @TensorRewrite.Theory.PadBroadcast.reduce_sequenceAlong
#print axioms TensorRewrite.Theory.PadBroadcast.reduce_sequenceAlong
#check @TensorRewrite.Theory.PadBroadcast.retained_spacing_refuted
#print axioms TensorRewrite.Theory.PadBroadcast.retained_spacing_refuted
#check @TensorRewrite.Theory.PadBroadcast.sequenceAlong_map
#print axioms TensorRewrite.Theory.PadBroadcast.sequenceAlong_map
#check @TensorRewrite.Theory.PadBroadcast.sequence_map
#print axioms TensorRewrite.Theory.PadBroadcast.sequence_map
#check @TensorRewrite.Theory.PadBroadcast.unequal_fill_refuted
#print axioms TensorRewrite.Theory.PadBroadcast.unequal_fill_refuted
#check @TensorRewrite.Theory.PadWindow.axis_compose
#print axioms TensorRewrite.Theory.PadWindow.axis_compose
#check @TensorRewrite.Theory.PadWindow.contribution_fusion
#print axioms TensorRewrite.Theory.PadWindow.contribution_fusion
#check @TensorRewrite.Theory.PadWindow.convert_initial_fusion
#print axioms TensorRewrite.Theory.PadWindow.convert_initial_fusion
#check @TensorRewrite.Theory.PadWindow.convert_reduce_fusion
#print axioms TensorRewrite.Theory.PadWindow.convert_reduce_fusion
#check @TensorRewrite.Theory.PadWindow.dilated_extent_nonempty
#print axioms TensorRewrite.Theory.PadWindow.dilated_extent_nonempty
#check @TensorRewrite.Theory.PadWindow.empty_high_formula_refuted
#print axioms TensorRewrite.Theory.PadWindow.empty_high_formula_refuted
#check @TensorRewrite.Theory.PadWindow.fused_high_nonempty
#print axioms TensorRewrite.Theory.PadWindow.fused_high_nonempty
#check @TensorRewrite.Theory.PadWindow.fused_high_unit_base
#print axioms TensorRewrite.Theory.PadWindow.fused_high_unit_base
#check @TensorRewrite.Theory.PadWindow.fused_output_extent
#print axioms TensorRewrite.Theory.PadWindow.fused_output_extent
#check @TensorRewrite.Theory.PadWindow.fused_position
#print axioms TensorRewrite.Theory.PadWindow.fused_position
#check @TensorRewrite.Theory.PadWindow.map_pad
#print axioms TensorRewrite.Theory.PadWindow.map_pad
#check @TensorRewrite.Theory.PadWindow.occupied_bound
#print axioms TensorRewrite.Theory.PadWindow.occupied_bound
#check @TensorRewrite.Theory.PadWindow.output_shape
#print axioms TensorRewrite.Theory.PadWindow.output_shape
#check @TensorRewrite.Theory.PadWindow.pad_sample_iff
#print axioms TensorRewrite.Theory.PadWindow.pad_sample_iff
#check @TensorRewrite.Theory.PadWindow.reduce_fusion
#print axioms TensorRewrite.Theory.PadWindow.reduce_fusion
#check @TensorRewrite.Theory.PadWindow.sample_compose
#print axioms TensorRewrite.Theory.PadWindow.sample_compose
#check @TensorRewrite.Theory.PadWindow.sample_embedded
#print axioms TensorRewrite.Theory.PadWindow.sample_embedded
#check @TensorRewrite.Theory.PadWindow.unequal_fill_refuted
#print axioms TensorRewrite.Theory.PadWindow.unequal_fill_refuted
#check @TensorRewrite.Theory.PadWindow.values_fusion
#print axioms TensorRewrite.Theory.PadWindow.values_fusion
#check @TensorRewrite.Theory.PrefixWindow.additive_prefix
#print axioms TensorRewrite.Theory.PrefixWindow.additive_prefix
#check @TensorRewrite.Theory.PrefixWindow.constant_additive_prefix
#print axioms TensorRewrite.Theory.PrefixWindow.constant_additive_prefix
#check @TensorRewrite.Theory.PrefixWindow.i32_prefix_product
#print axioms TensorRewrite.Theory.PrefixWindow.i32_prefix_product
#check @TensorRewrite.Theory.PrefixWindow.i64_prefix_product
#print axioms TensorRewrite.Theory.PrefixWindow.i64_prefix_product
#check @TensorRewrite.Theory.PrefixWindow.kernel_enumerate
#print axioms TensorRewrite.Theory.PrefixWindow.kernel_enumerate
#check @TensorRewrite.Theory.PrefixWindow.map_finRange_add
#print axioms TensorRewrite.Theory.PrefixWindow.map_finRange_add
#check @TensorRewrite.Theory.PrefixWindow.natural_prefix_count
#print axioms TensorRewrite.Theory.PrefixWindow.natural_prefix_count
#check @TensorRewrite.Theory.PrefixWindow.negative_axis
#print axioms TensorRewrite.Theory.PrefixWindow.negative_axis
#check @TensorRewrite.Theory.PrefixWindow.nonfixed_padding_refuted
#print axioms TensorRewrite.Theory.PrefixWindow.nonfixed_padding_refuted
#check @TensorRewrite.Theory.PrefixWindow.padding_partition
#print axioms TensorRewrite.Theory.PrefixWindow.padding_partition
#check @TensorRewrite.Theory.PrefixWindow.prefix_constant
#print axioms TensorRewrite.Theory.PrefixWindow.prefix_constant
#check @TensorRewrite.Theory.PrefixWindow.prefix_length
#print axioms TensorRewrite.Theory.PrefixWindow.prefix_length
#check @TensorRewrite.Theory.PrefixWindow.prefix_output_extent
#print axioms TensorRewrite.Theory.PrefixWindow.prefix_output_extent
#check @TensorRewrite.Theory.PrefixWindow.reduce_prefix
#print axioms TensorRewrite.Theory.PrefixWindow.reduce_prefix
#check @TensorRewrite.Theory.PrefixWindow.retained_bound
#print axioms TensorRewrite.Theory.PrefixWindow.retained_bound
#check @TensorRewrite.Theory.PrefixWindow.retained_output_extent
#print axioms TensorRewrite.Theory.PrefixWindow.retained_output_extent
#check @TensorRewrite.Theory.PrefixWindow.retained_sample
#print axioms TensorRewrite.Theory.PrefixWindow.retained_sample
#check @TensorRewrite.Theory.PrefixWindow.sample_axis
#print axioms TensorRewrite.Theory.PrefixWindow.sample_axis
#check @TensorRewrite.Theory.PrefixWindow.sample_invalid
#print axioms TensorRewrite.Theory.PrefixWindow.sample_invalid
#check @TensorRewrite.Theory.PrefixWindow.sample_valid
#print axioms TensorRewrite.Theory.PrefixWindow.sample_valid
#check @TensorRewrite.Theory.PrefixWindow.semiring_prefix_product
#print axioms TensorRewrite.Theory.PrefixWindow.semiring_prefix_product
#check @TensorRewrite.Theory.PrefixWindow.signed_count_exact_iff
#print axioms TensorRewrite.Theory.PrefixWindow.signed_count_exact_iff
#check @TensorRewrite.Theory.PrefixWindow.signed_width_boundary_refuted
#print axioms TensorRewrite.Theory.PrefixWindow.signed_width_boundary_refuted
#check @TensorRewrite.Theory.PrefixWindow.split_kernel_range
#print axioms TensorRewrite.Theory.PrefixWindow.split_kernel_range
#check @TensorRewrite.Theory.PrefixWindow.unit_enumerate_map
#print axioms TensorRewrite.Theory.PrefixWindow.unit_enumerate_map
#check @TensorRewrite.Theory.PrefixWindow.unsigned_count_exact_iff
#print axioms TensorRewrite.Theory.PrefixWindow.unsigned_count_exact_iff
#check @TensorRewrite.Theory.PrefixWindow.values_prefix
#print axioms TensorRewrite.Theory.PrefixWindow.values_prefix
#check @TensorRewrite.Theory.PrefixWindow.values_scan_range
#print axioms TensorRewrite.Theory.PrefixWindow.values_scan_range
#check @TensorRewrite.Theory.PrefixWindow.word_count_overflow_refuted
#print axioms TensorRewrite.Theory.PrefixWindow.word_count_overflow_refuted
#check @TensorRewrite.Theory.PrefixWindow.word_prefix_count
#print axioms TensorRewrite.Theory.PrefixWindow.word_prefix_count
#check @TensorRewrite.Theory.PrefixWindow.word_prefix_product
#print axioms TensorRewrite.Theory.PrefixWindow.word_prefix_product
#check @TensorRewrite.Theory.PrefixWindow.word_prefix_signed_iff
#print axioms TensorRewrite.Theory.PrefixWindow.word_prefix_signed_iff
#check @TensorRewrite.Theory.PrefixWindow.word_prefix_unsigned_iff
#print axioms TensorRewrite.Theory.PrefixWindow.word_prefix_unsigned_iff
#check @TensorRewrite.Theory.PrefixWindow.word_replicate_fold
#print axioms TensorRewrite.Theory.PrefixWindow.word_replicate_fold
#check @TensorRewrite.Theory.ReductionAlgebra.concat_add
#print axioms TensorRewrite.Theory.ReductionAlgebra.concat_add
#check @TensorRewrite.Theory.ReductionAlgebra.constant_absorb
#print axioms TensorRewrite.Theory.ReductionAlgebra.constant_absorb
#check @TensorRewrite.Theory.ReductionAlgebra.constant_add
#print axioms TensorRewrite.Theory.ReductionAlgebra.constant_add
#check @TensorRewrite.Theory.ReductionAlgebra.constant_and
#print axioms TensorRewrite.Theory.ReductionAlgebra.constant_and
#check @TensorRewrite.Theory.ReductionAlgebra.constant_max
#print axioms TensorRewrite.Theory.ReductionAlgebra.constant_max
#check @TensorRewrite.Theory.ReductionAlgebra.constant_min
#print axioms TensorRewrite.Theory.ReductionAlgebra.constant_min
#check @TensorRewrite.Theory.ReductionAlgebra.constant_or
#print axioms TensorRewrite.Theory.ReductionAlgebra.constant_or
#check @TensorRewrite.Theory.ReductionAlgebra.coordinate_sum
#print axioms TensorRewrite.Theory.ReductionAlgebra.coordinate_sum
#check @TensorRewrite.Theory.ReductionAlgebra.empty_components
#print axioms TensorRewrite.Theory.ReductionAlgebra.empty_components
#check @TensorRewrite.Theory.ReductionAlgebra.empty_constant_refuted
#print axioms TensorRewrite.Theory.ReductionAlgebra.empty_constant_refuted
#check @TensorRewrite.Theory.ReductionAlgebra.map_reduction
#print axioms TensorRewrite.Theory.ReductionAlgebra.map_reduction
#check @TensorRewrite.Theory.ReductionAlgebra.negate_sum
#print axioms TensorRewrite.Theory.ReductionAlgebra.negate_sum
#check @TensorRewrite.Theory.ReductionAlgebra.nonassociative_regrouping_refuted
#print axioms TensorRewrite.Theory.ReductionAlgebra.nonassociative_regrouping_refuted
#check @TensorRewrite.Theory.ReductionAlgebra.repeated_initializer_refuted
#print axioms TensorRewrite.Theory.ReductionAlgebra.repeated_initializer_refuted
#check @TensorRewrite.Theory.ReductionAlgebra.sameCount_components
#print axioms TensorRewrite.Theory.ReductionAlgebra.sameCount_components
#check @TensorRewrite.Theory.ReductionAlgebra.sum_reduction
#print axioms TensorRewrite.Theory.ReductionAlgebra.sum_reduction
#check @TensorRewrite.Theory.ReductionFiber.elementCount_shape
#print axioms TensorRewrite.Theory.ReductionFiber.elementCount_shape
#check @TensorRewrite.Theory.ReductionFiber.fiberValues_constant
#print axioms TensorRewrite.Theory.ReductionFiber.fiberValues_constant
#check @TensorRewrite.Theory.ReductionFiber.fiberValues_map
#print axioms TensorRewrite.Theory.ReductionFiber.fiberValues_map
#check @TensorRewrite.Theory.ReductionFiber.fiberValues_sum
#print axioms TensorRewrite.Theory.ReductionFiber.fiberValues_sum
#check @TensorRewrite.Theory.ReductionFiber.foldl_map_hom
#print axioms TensorRewrite.Theory.ReductionFiber.foldl_map_hom
#check @TensorRewrite.Theory.ReductionFiber.foldl_replicate_absorb
#print axioms TensorRewrite.Theory.ReductionFiber.foldl_replicate_absorb
#check @TensorRewrite.Theory.ReductionFiber.merge_split
#print axioms TensorRewrite.Theory.ReductionFiber.merge_split
#check @TensorRewrite.Theory.ReductionFiber.output_merge
#print axioms TensorRewrite.Theory.ReductionFiber.output_merge
#check @TensorRewrite.Theory.ReductionFiber.reduced_merge
#print axioms TensorRewrite.Theory.ReductionFiber.reduced_merge
#check @TensorRewrite.Theory.ReductionFiber.sum_flatMap
#print axioms TensorRewrite.Theory.ReductionFiber.sum_flatMap
#check @TensorRewrite.Theory.ReductionFiber.sum_head_tail
#print axioms TensorRewrite.Theory.ReductionFiber.sum_head_tail
#check @TensorRewrite.Theory.ReductionWindow.affine_none_of_axis
#print axioms TensorRewrite.Theory.ReductionWindow.affine_none_of_axis
#check @TensorRewrite.Theory.ReductionWindow.axis_unit_position
#print axioms TensorRewrite.Theory.ReductionWindow.axis_unit_position
#check @TensorRewrite.Theory.ReductionWindow.axis_unit_sample
#print axioms TensorRewrite.Theory.ReductionWindow.axis_unit_sample
#check @TensorRewrite.Theory.ReductionWindow.bounded_none_of_outside
#print axioms TensorRewrite.Theory.ReductionWindow.bounded_none_of_outside
#check @TensorRewrite.Theory.ReductionWindow.empty_input_components
#print axioms TensorRewrite.Theory.ReductionWindow.empty_input_components
#check @TensorRewrite.Theory.ReductionWindow.foldl_replicate_fixed
#print axioms TensorRewrite.Theory.ReductionWindow.foldl_replicate_fixed
#check @TensorRewrite.Theory.ReductionWindow.padding_fixed_refuted
#print axioms TensorRewrite.Theory.ReductionWindow.padding_fixed_refuted
#check @TensorRewrite.Theory.ReductionWindow.padding_skip_refuted
#print axioms TensorRewrite.Theory.ReductionWindow.padding_skip_refuted
#check @TensorRewrite.Theory.ReductionWindow.pointwise
#print axioms TensorRewrite.Theory.ReductionWindow.pointwise
#check @TensorRewrite.Theory.ReductionWindow.pointwise_eliminate
#print axioms TensorRewrite.Theory.ReductionWindow.pointwise_eliminate
#check @TensorRewrite.Theory.ReductionWindow.reduce_empty_input
#print axioms TensorRewrite.Theory.ReductionWindow.reduce_empty_input
#check @TensorRewrite.Theory.ReductionWindow.reduce_empty_input_fixed
#print axioms TensorRewrite.Theory.ReductionWindow.reduce_empty_input_fixed
#check @TensorRewrite.Theory.ReductionWindow.reduce_empty_kernel
#print axioms TensorRewrite.Theory.ReductionWindow.reduce_empty_kernel
#check @TensorRewrite.Theory.ReductionWindow.reduce_empty_output
#print axioms TensorRewrite.Theory.ReductionWindow.reduce_empty_output
#check @TensorRewrite.Theory.ReductionWindow.reduce_unit
#print axioms TensorRewrite.Theory.ReductionWindow.reduce_unit
#check @TensorRewrite.Theory.ReductionWindow.sample_empty_input
#print axioms TensorRewrite.Theory.ReductionWindow.sample_empty_input
#check @TensorRewrite.Theory.ReductionWindow.sample_unit_affine
#print axioms TensorRewrite.Theory.ReductionWindow.sample_unit_affine
#check @TensorRewrite.Theory.ReductionWindow.unit_count
#print axioms TensorRewrite.Theory.ReductionWindow.unit_count
#check @TensorRewrite.Theory.ReductionWindow.unit_crop_all
#print axioms TensorRewrite.Theory.ReductionWindow.unit_crop_all
#check @TensorRewrite.Theory.ReductionWindow.unit_crop_low_all
#print axioms TensorRewrite.Theory.ReductionWindow.unit_crop_low_all
#check @TensorRewrite.Theory.ReductionWindow.unit_gather
#print axioms TensorRewrite.Theory.ReductionWindow.unit_gather
#check @TensorRewrite.Theory.ReductionWindow.unit_gather_add_zero
#print axioms TensorRewrite.Theory.ReductionWindow.unit_gather_add_zero
#check @TensorRewrite.Theory.ReductionWindow.unit_gather_initial
#print axioms TensorRewrite.Theory.ReductionWindow.unit_gather_initial
#check @TensorRewrite.Theory.ReductionWindow.unit_gather_max
#print axioms TensorRewrite.Theory.ReductionWindow.unit_gather_max
#check @TensorRewrite.Theory.ReductionWindow.unit_gather_min
#print axioms TensorRewrite.Theory.ReductionWindow.unit_gather_min
#check @TensorRewrite.Theory.ReductionWindow.unit_index_unique
#print axioms TensorRewrite.Theory.ReductionWindow.unit_index_unique
#check @TensorRewrite.Theory.ReductionWindow.values_empty_input
#print axioms TensorRewrite.Theory.ReductionWindow.values_empty_input
#check @TensorRewrite.Theory.ReductionWindow.values_length
#print axioms TensorRewrite.Theory.ReductionWindow.values_length
#check @TensorRewrite.Theory.ReductionWindow.values_unit
#print axioms TensorRewrite.Theory.ReductionWindow.values_unit
#check @TensorRewrite.Theory.Remainder.integer_nested
#print axioms TensorRewrite.Theory.Remainder.integer_nested
#check @TensorRewrite.Theory.Remainder.integer_nested_tensor
#print axioms TensorRewrite.Theory.Remainder.integer_nested_tensor
#check @TensorRewrite.Theory.Remainder.natural_add_msb_false
#print axioms TensorRewrite.Theory.Remainder.natural_add_msb_false
#check @TensorRewrite.Theory.Remainder.natural_add_toNat
#print axioms TensorRewrite.Theory.Remainder.natural_add_toNat
#check @TensorRewrite.Theory.Remainder.natural_msb_false
#print axioms TensorRewrite.Theory.Remainder.natural_msb_false
#check @TensorRewrite.Theory.Remainder.power_mask
#print axioms TensorRewrite.Theory.Remainder.power_mask
#check @TensorRewrite.Theory.Remainder.power_toNat
#print axioms TensorRewrite.Theory.Remainder.power_toNat
#check @TensorRewrite.Theory.Remainder.signed_correction_refuted
#print axioms TensorRewrite.Theory.Remainder.signed_correction_refuted
#check @TensorRewrite.Theory.Remainder.signed_iota
#print axioms TensorRewrite.Theory.Remainder.signed_iota
#check @TensorRewrite.Theory.Remainder.signed_iota_offset_lhs
#print axioms TensorRewrite.Theory.Remainder.signed_iota_offset_lhs
#check @TensorRewrite.Theory.Remainder.signed_iota_offset_rhs
#print axioms TensorRewrite.Theory.Remainder.signed_iota_offset_rhs
#check @TensorRewrite.Theory.Remainder.signed_mask_tensor
#print axioms TensorRewrite.Theory.Remainder.signed_mask_tensor
#check @TensorRewrite.Theory.Remainder.signed_nested
#print axioms TensorRewrite.Theory.Remainder.signed_nested
#check @TensorRewrite.Theory.Remainder.signed_nested_tensor
#print axioms TensorRewrite.Theory.Remainder.signed_nested_tensor
#check @TensorRewrite.Theory.Remainder.signed_offset
#print axioms TensorRewrite.Theory.Remainder.signed_offset
#check @TensorRewrite.Theory.Remainder.signed_power_mask
#print axioms TensorRewrite.Theory.Remainder.signed_power_mask
#check @TensorRewrite.Theory.Remainder.signed_power_msb
#print axioms TensorRewrite.Theory.Remainder.signed_power_msb
#check @TensorRewrite.Theory.Remainder.signed_wrap_refuted
#print axioms TensorRewrite.Theory.Remainder.signed_wrap_refuted
#check @TensorRewrite.Theory.Remainder.unsigned_iota
#print axioms TensorRewrite.Theory.Remainder.unsigned_iota
#check @TensorRewrite.Theory.Remainder.unsigned_iota_offset_lhs
#print axioms TensorRewrite.Theory.Remainder.unsigned_iota_offset_lhs
#check @TensorRewrite.Theory.Remainder.unsigned_iota_offset_rhs
#print axioms TensorRewrite.Theory.Remainder.unsigned_iota_offset_rhs
#check @TensorRewrite.Theory.Remainder.unsigned_mask_tensor
#print axioms TensorRewrite.Theory.Remainder.unsigned_mask_tensor
#check @TensorRewrite.Theory.Remainder.unsigned_nested
#print axioms TensorRewrite.Theory.Remainder.unsigned_nested
#check @TensorRewrite.Theory.Remainder.unsigned_nested_tensor
#print axioms TensorRewrite.Theory.Remainder.unsigned_nested_tensor
#check @TensorRewrite.Theory.Remainder.unsigned_offset
#print axioms TensorRewrite.Theory.Remainder.unsigned_offset
#check @TensorRewrite.Theory.Remainder.unsigned_power_mask
#print axioms TensorRewrite.Theory.Remainder.unsigned_power_mask
#check @TensorRewrite.Theory.Remainder.unsigned_wrap_refuted
#print axioms TensorRewrite.Theory.Remainder.unsigned_wrap_refuted
#check @TensorRewrite.Theory.ScalarDomains.complex_log_exp_counterexample
#print axioms TensorRewrite.Theory.ScalarDomains.complex_log_exp_counterexample
#check @TensorRewrite.Theory.ScalarDomains.complex_log_exp_iff
#print axioms TensorRewrite.Theory.ScalarDomains.complex_log_exp_iff
#check @TensorRewrite.Theory.ScalarDomains.complex_log_exp_tensor_iff
#print axioms TensorRewrite.Theory.ScalarDomains.complex_log_exp_tensor_iff
#check @TensorRewrite.Theory.ScalarDomains.complex_sqrt_square_counterexample
#print axioms TensorRewrite.Theory.ScalarDomains.complex_sqrt_square_counterexample
#check @TensorRewrite.Theory.ScalarDomains.complex_sqrt_square_iff_real
#print axioms TensorRewrite.Theory.ScalarDomains.complex_sqrt_square_iff_real
#check @TensorRewrite.Theory.ScalarDomains.complex_sqrt_square_ofReal
#print axioms TensorRewrite.Theory.ScalarDomains.complex_sqrt_square_ofReal
#check @TensorRewrite.Theory.ScalarDomains.complex_sqrt_square_tensor_iff
#print axioms TensorRewrite.Theory.ScalarDomains.complex_sqrt_square_tensor_iff
#check @TensorRewrite.Theory.ScalarDomains.complex_square_sqrt
#print axioms TensorRewrite.Theory.ScalarDomains.complex_square_sqrt
#check @TensorRewrite.Theory.ScalarDomains.real_log_exp
#print axioms TensorRewrite.Theory.ScalarDomains.real_log_exp
#check @TensorRewrite.Theory.ScalarDomains.real_log_exp_tensor
#print axioms TensorRewrite.Theory.ScalarDomains.real_log_exp_tensor
#check @TensorRewrite.Theory.ScalarDomains.real_log_sqrt_pos
#print axioms TensorRewrite.Theory.ScalarDomains.real_log_sqrt_pos
#check @TensorRewrite.Theory.ScalarDomains.real_log_sqrt_tensor_pos
#print axioms TensorRewrite.Theory.ScalarDomains.real_log_sqrt_tensor_pos
#check @TensorRewrite.Theory.ScalarDomains.real_sqrt_square
#print axioms TensorRewrite.Theory.ScalarDomains.real_sqrt_square
#check @TensorRewrite.Theory.ScalarDomains.real_sqrt_square_tensor
#print axioms TensorRewrite.Theory.ScalarDomains.real_sqrt_square_tensor
#check @TensorRewrite.Theory.SlicePad.attributes_count
#print axioms TensorRewrite.Theory.SlicePad.attributes_count
#check @TensorRewrite.Theory.SlicePad.attributes_valid
#print axioms TensorRewrite.Theory.SlicePad.attributes_valid
#check @TensorRewrite.Theory.SlicePad.bounded_isSome
#print axioms TensorRewrite.Theory.SlicePad.bounded_isSome
#check @TensorRewrite.Theory.SlicePad.bounded_value
#print axioms TensorRewrite.Theory.SlicePad.bounded_value
#check @TensorRewrite.Theory.SlicePad.ceil_le_iff
#print axioms TensorRewrite.Theory.SlicePad.ceil_le_iff
#check @TensorRewrite.Theory.SlicePad.ceil_mono
#print axioms TensorRewrite.Theory.SlicePad.ceil_mono
#check @TensorRewrite.Theory.SlicePad.coordinate_after_pad
#print axioms TensorRewrite.Theory.SlicePad.coordinate_after_pad
#check @TensorRewrite.Theory.SlicePad.first_le_last
#print axioms TensorRewrite.Theory.SlicePad.first_le_last
#check @TensorRewrite.Theory.SlicePad.graph_gather
#print axioms TensorRewrite.Theory.SlicePad.graph_gather
#check @TensorRewrite.Theory.SlicePad.graph_index
#print axioms TensorRewrite.Theory.SlicePad.graph_index
#check @TensorRewrite.Theory.SlicePad.graph_shape
#print axioms TensorRewrite.Theory.SlicePad.graph_shape
#check @TensorRewrite.Theory.SlicePad.last_le_output
#print axioms TensorRewrite.Theory.SlicePad.last_le_output
#check @TensorRewrite.Theory.SlicePad.limit_le_input
#print axioms TensorRewrite.Theory.SlicePad.limit_le_input
#check @TensorRewrite.Theory.SlicePad.pad_interval
#print axioms TensorRewrite.Theory.SlicePad.pad_interval
#check @TensorRewrite.Theory.SlicePad.padded_extent
#print axioms TensorRewrite.Theory.SlicePad.padded_extent
#check @TensorRewrite.Theory.SlicePad.padding_admission
#print axioms TensorRewrite.Theory.SlicePad.padding_admission
#check @TensorRewrite.Theory.SlicePad.rounded_start_refuted
#print axioms TensorRewrite.Theory.SlicePad.rounded_start_refuted
#check @TensorRewrite.Theory.SlicePad.slice_bounded
#print axioms TensorRewrite.Theory.SlicePad.slice_bounded
#check @TensorRewrite.Theory.SlicePad.slice_coordinate
#print axioms TensorRewrite.Theory.SlicePad.slice_coordinate
#check @TensorRewrite.Theory.SlicePad.start_cast
#print axioms TensorRewrite.Theory.SlicePad.start_cast
#check @TensorRewrite.Theory.SlicePad.start_le_input
#print axioms TensorRewrite.Theory.SlicePad.start_le_input
#check @TensorRewrite.Theory.SlicePad.start_le_limit
#print axioms TensorRewrite.Theory.SlicePad.start_le_limit
#check @TensorRewrite.Theory.SlicePad.unclipped_shape_refuted
#print axioms TensorRewrite.Theory.SlicePad.unclipped_shape_refuted
#check @TensorRewrite.Theory.SlicePad.unit_window_add_zero
#print axioms TensorRewrite.Theory.SlicePad.unit_window_add_zero
#check @TensorRewrite.Theory.SlicePad.unit_window_graph
#print axioms TensorRewrite.Theory.SlicePad.unit_window_graph
#check @TensorRewrite.Theory.SlicePad.unit_window_max
#print axioms TensorRewrite.Theory.SlicePad.unit_window_max
#check @TensorRewrite.Theory.SlicePad.unit_window_min
#print axioms TensorRewrite.Theory.SlicePad.unit_window_min
#check @TensorRewrite.Theory.SlicePad.valid_interval
#print axioms TensorRewrite.Theory.SlicePad.valid_interval
#check @TensorRewrite.Theory.UniformSum.binary32_uniform_product_refuted
#print axioms TensorRewrite.Theory.UniformSum.binary32_uniform_product_refuted
#check @TensorRewrite.Theory.WindowTransport.contribution_map
#print axioms TensorRewrite.Theory.WindowTransport.contribution_map
#check @TensorRewrite.Theory.WindowTransport.reduce_equiv
#print axioms TensorRewrite.Theory.WindowTransport.reduce_equiv
#check @TensorRewrite.Theory.WindowTransport.reduce_map
#print axioms TensorRewrite.Theory.WindowTransport.reduce_map
#check @TensorRewrite.Theory.WindowTransport.singleton_reduce
#print axioms TensorRewrite.Theory.WindowTransport.singleton_reduce
#check @TensorRewrite.Theory.WindowTransport.values_map
#print axioms TensorRewrite.Theory.WindowTransport.values_map
#check @TensorRewrite.Theory.WindowTupleFamily.allRules_complete
#print axioms TensorRewrite.Theory.WindowTupleFamily.allRules_complete
#check @TensorRewrite.Theory.WindowTupleFamily.allRules_nodup
#print axioms TensorRewrite.Theory.WindowTupleFamily.allRules_nodup
#check @TensorRewrite.Theory.WindowTupleFamily.rewrite_sound
#print axioms TensorRewrite.Theory.WindowTupleFamily.rewrite_sound
#check @TensorRewrite.Theory.WindowTupleFloat.binary32_tuple
#print axioms TensorRewrite.Theory.WindowTupleFloat.binary32_tuple
#check @TensorRewrite.Theory.WindowTupleFloat.binary32_tuple_bits
#print axioms TensorRewrite.Theory.WindowTupleFloat.binary32_tuple_bits
