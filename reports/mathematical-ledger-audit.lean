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
#check @TensorRewrite.Pilot.SelectContraction.hoistedContraction_eq
#print axioms TensorRewrite.Pilot.SelectContraction.hoistedContraction_eq
#check @TensorRewrite.Pilot.SelectContraction.nonzero_sum_refutes
#print axioms TensorRewrite.Pilot.SelectContraction.nonzero_sum_refutes
#check @TensorRewrite.Pilot.SelectContraction.not_universally_valid
#print axioms TensorRewrite.Pilot.SelectContraction.not_universally_valid
#check @TensorRewrite.Pilot.SliceShape.coordinate_bounds
#print axioms TensorRewrite.Pilot.SliceShape.coordinate_bounds
#check @TensorRewrite.Pilot.SliceShape.remove_redundant_stride_not_preserving
#print axioms TensorRewrite.Pilot.SliceShape.remove_redundant_stride_not_preserving
#check @TensorRewrite.Pilot.SliceShape.remove_redundant_stride_refutes
#print axioms TensorRewrite.Pilot.SliceShape.remove_redundant_stride_refutes
#check @TensorRewrite.Pilot.SliceShape.reorder_reverse_not_preserving
#print axioms TensorRewrite.Pilot.SliceShape.reorder_reverse_not_preserving
#check @TensorRewrite.Pilot.SliceShape.reorder_reverse_refutes
#print axioms TensorRewrite.Pilot.SliceShape.reorder_reverse_refutes
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
#check @TensorRewrite.Theory.ContractionAlgebra.dot_add_left
#print axioms TensorRewrite.Theory.ContractionAlgebra.dot_add_left
#check @TensorRewrite.Theory.ContractionAlgebra.dot_add_right
#print axioms TensorRewrite.Theory.ContractionAlgebra.dot_add_right
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
