"""Check mathematical theory only; never invoke source extraction or native pass replay."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
from lean_size import count_source

ROOT = Path(__file__).resolve().parents[1]
ALLOWED = {'propext', 'Classical.choice', 'Quot.sound'}
THEOREMS = {
    'DynamicUpdate': ['start_bounds', 'embed_value', 'locate_embed', 'embed_locate', 'locate_eq_some_iff', 'embed_compose', 'locate_compose', 'full_start', 'full_embed', 'full_locate', 'zero_full_start', 'zero_full_embed', 'zero_full_locate', 'slice_eq_existing', 'slice_compose', 'slice_full', 'slice_scalar', 'slice_zero_full_axes', 'update_full', 'update_empty', 'slice_update', 'update_slice_self', 'slice_update_inside', 'update_nested', 'map_update', 'update_zero_full_axes', 'select_update_false', 'select_update_true', 'select_scalar_false', 'select_scalar_true', 'add_update_right', 'add_update_left', 'static_axis_count', 'static_axes_valid', 'static_index', 'slice_static', 'static_slice_update', 'static_slice_update_inside', 'decoded_signedness_refuted', 'raw_nested_sum_refuted', 'binary32_add_update_refuted'],
    'OrderFamily': ['eval_minOrder', 'eval_maxOrder', 'rewrite_sound', 'condition_admitted', 'rewrite_in_context', 'allRules_complete', 'allRuleKeys_nodup', 'rule_count', 'integer_family', 'real_family', 'unsigned_family', 'signed_family', 'unsigned_nonnegative', 'unsigned_zero', 'reversed_bounds_refuted', 'signedness_refuted', 'binary32_nan_self_refuted', 'binary32_zero_observation_refuted'],
    'Numerical': ['divide_one', 'divide_as_product', 'divide_constant', 'divide_reciprocal', 'divide_fractions', 'divide_nested_numerator', 'divide_nested_denominator', 'divide_broadcast', 'divide_predicate_broadcast', 'real_exp_product', 'real_exp_quotient', 'real_exp_denominator', 'real_power_denominator', 'real_abs_square', 'real_sqrt_square_iff', 'real_rsqrt_square_iff', 'real_power_zero', 'real_power_one', 'real_power_two', 'real_power_three', 'real_power_minus_one', 'real_power_half', 'real_power_exp', 'real_log_power_pos', 'real_log_rsqrt_pos', 'real_rsqrt_inverse_square', 'real_rsqrt_inverse_square_iff', 'real_rsqrt_reciprocal', 'real_divide_sqrt', 'real_divide_rsqrt', 'real_exp_zero', 'complex_exp_zero', 'complex_exp_product', 'complex_exp_quotient', 'complex_exp_denominator', 'complex_power_denominator', 'complex_sqrt_square', 'complex_rsqrt_square', 'complex_power_zero', 'complex_power_one', 'complex_power_two', 'complex_power_three', 'complex_power_minus_one', 'complex_power_half', 'complex_power_exp_strip', 'complex_log_power_iff', 'complex_divide_sqrt', 'complex_divide_rsqrt', 'real_sqrt_square_refuted', 'real_rsqrt_inverse_square_refuted', 'real_power_denominator_refuted', 'complex_rsqrt_reciprocal_refuted', 'complex_power_exp_refuted'],
    'ArithmeticFamily': ['binary32_add_assoc_refuted', 'binary32_mul_assoc_refuted', 'binary32_mul_zero_refuted', 'subtract_broadcast', 'add_broadcast_constants', 'subtract_add_broadcast_constants', 'multiply_broadcast_constants', 'broadcast_uniform_factor', 'eval_addOrder', 'eval_mulOrder', 'rewrite_sound', 'rewrite_in_context', 'allRules_complete', 'allRuleKeys_nodup', 'rule_count', 'integer_family', 'real_family', 'complex_family', 'word_family'],
    'ScatterBatching': ['inserted_extent', 'rawBatchAxis_extent', 'rawIndex_batch_value', 'pairAt_mapped', 'pairAt_unmapped', 'window_paired_zero', 'batch_coordinate_bound', 'identityAxes_decode', 'canonical_offset', 'canonical_position', 'target_eq_canonical', 'target_eq_some_iff', 'target_no_pairs', 'target_batch_coordinate', 'forgetting_batching_refuted', 'entries_eq_canonical', 'run_eq_canonical', 'entries_length', 'run_empty', 'run_relayout_indices', 'word_translate_distinct', 'run_combine_nested'],
    'IndexVector': ['batch_raw', 'component_raw', 'raw_split', 'vectorAxis_bound', 'implicit_components', 'elementCount_raw', 'read_pack', 'pack_read', 'read_map', 'read_relayout', 'relayout_refl', 'relayout_trans'],
    'ScatterIndices': ['entries_eq_layout', 'scatter_eq_layout', 'scatter_eq_ordered', 'entries_length', 'scatter_relayout_indices', 'scatter_empty', 'word_translate_distinct', 'empty_index_tensor_not_single_map'],

    'ScatterLayout': ['project_expand', 'expand_project', 'enumerate_expand', 'elementCount_full', 'update_coordinate', 'adapt_expand', 'adapt_map', 'entries_eq_ordered', 'raw_storage_order_refuted', 'scatter_eq_ordered', 'entries_length', 'scatter_empty', 'scatter_map', 'scatter_translate', 'word_translate_distinct', 'scatter_combine_nested'],
    'ScatterConcat': ['concatenate_left', 'concatenate_right', 'enumerate_concatenate', 'entries_coordinates', 'target_rebatch', 'entries_concatenate', 'scatter_concatenate', 'scatter_combine', 'word_combine_distinct'],
    'OrderedScatter': ['repeated_parameter_refuted', 'duplicate_order_refuted', 'binary32_translate_refuted', 'clamping_refuted', 'entries_full_window', 'values_full_window', 'offset_mapped', 'offset_unmapped', 'target_eq_some_iff', 'entries_length', 'entries_empty_batch', 'entries_empty_window', 'empty_vector_offset', 'full_window_target', 'filterMap_finRange_single', 'scatter_map', 'empty_components', 'scatter_translate', 'word_translate_distinct', 'step_at', 'run_at', 'run_append', 'values_append', 'step_map', 'run_map', 'foldl_translate', 'foldl_combine', 'run_empty', 'scatter_empty', 'full_window_map', 'run_translate', 'run_combine', 'run_combine_nested', 'word_combine', 'entries_map', 'distinct_word_operation'],
    'Remainder': ['power_toNat', 'power_mask', 'natural_msb_false', 'signed_power_msb', 'natural_add_toNat', 'natural_add_msb_false', 'integer_nested', 'unsigned_nested', 'signed_nested', 'unsigned_power_mask', 'signed_power_mask', 'unsigned_offset', 'signed_offset', 'integer_nested_tensor', 'unsigned_nested_tensor', 'signed_nested_tensor', 'unsigned_mask_tensor', 'signed_mask_tensor', 'unsigned_iota', 'signed_iota', 'unsigned_iota_offset_rhs', 'unsigned_iota_offset_lhs', 'signed_iota_offset_rhs', 'signed_iota_offset_lhs', 'signed_correction_refuted', 'unsigned_wrap_refuted', 'signed_wrap_refuted'],
    'UniformSum': ['binary32_uniform_product_refuted'],

    'PadBroadcast': ['kept_pointwise', 'expansion_axis', 'expansion_output_extent', 'expansion_covers', 'fused_window', 'reduce_sequenceAlong', 'sequenceAlong_map', 'reduce_sequence', 'sequence_map', 'reduce_converted_sequence', 'unequal_fill_refuted', 'converted_fill_refuted', 'retained_spacing_refuted'],
    'WindowTransport': ['contribution_map', 'values_map', 'reduce_map', 'reduce_equiv', 'singleton_reduce'],
    'WindowTupleFamily': ['rewrite_sound', 'allRules_complete', 'allRules_nodup'],
    'WindowTupleFloat': ['binary32_tuple', 'binary32_tuple_bits'],
    'BroadcastWindow': ['covered_offset', 'expansion_live_position', 'expansion_sample', 'expansion_unique', 'axes_decode', 'axes_extent', 'compact_count', 'axesMap_strictMono', 'compact_index_value', 'broadcast_index', 'linearize_expand', 'reshape_index', 'sequence_value', 'live_axis_sample', 'sample_live', 'axis_kernel_unique', 'sample_if', 'foldl_single_live', 'contribution_at_position', 'reduce_source', 'reduce_sequence', 'sequence_map', 'reduce_converted_sequence', 'nonneutral_reducer_refuted', 'uncovered_output_refuted', 'coupled_projection_refuted'],

    'PrefixWindow': ['retained_output_extent', 'retained_bound', 'retained_sample', 'prefix_output_extent', 'unit_enumerate_map', 'kernel_enumerate', 'values_scan_range', 'padding_partition', 'sample_axis', 'sample_valid', 'negative_axis', 'sample_invalid', 'map_finRange_add', 'split_kernel_range', 'word_replicate_fold', 'unsigned_count_exact_iff', 'signed_count_exact_iff', 'values_prefix', 'reduce_prefix', 'prefix_length', 'prefix_constant', 'additive_prefix', 'constant_additive_prefix', 'natural_prefix_count', 'semiring_prefix_product', 'word_prefix_product', 'word_prefix_count', 'word_prefix_unsigned_iff', 'word_prefix_signed_iff', 'i32_prefix_product', 'i64_prefix_product', 'nonfixed_padding_refuted', 'word_count_overflow_refuted', 'signed_width_boundary_refuted'],

    'LatticeIndex': ['decode_eq_some_iff', 'window_eq_some_iff', 'assemble_eq_some_iff', 'assemble_bind'],
    'PadWindow': ['occupied_bound', 'pad_sample_iff', 'sample_embedded', 'fused_position', 'fused_output_extent', 'dilated_extent_nonempty', 'fused_high_nonempty', 'fused_high_unit_base', 'axis_compose', 'output_shape', 'sample_compose', 'contribution_fusion', 'values_fusion', 'reduce_fusion', 'map_pad', 'convert_reduce_fusion', 'convert_initial_fusion', 'empty_high_formula_refuted', 'unequal_fill_refuted'],

    'OrderedCoordinates': ['map_finRange_mul', 'enumerate_scalar', 'enumerate_uncons', 'enumerate_uncons_map'],
    'FullSpanWindow': ['kept_output_extent', 'reduced_output_extent', 'kept_sample', 'reduced_sample', 'input_shape', 'original_input', 'input_original', 'axis_sample', 'sample_valid', 'output_count', 'output_linearize', 'output_reshape', 'sampled_fiber', 'values_fiber', 'reduce_reshape', 'original_reduce_reshape'],

    'SlicePad': ['ceil_le_iff', 'ceil_mono', 'first_le_last', 'last_le_output', 'valid_interval', 'start_le_input', 'start_cast', 'slice_coordinate', 'slice_bounded', 'padded_extent', 'start_le_limit', 'limit_le_input', 'attributes_count', 'attributes_valid', 'bounded_isSome', 'bounded_value', 'pad_interval', 'coordinate_after_pad', 'graph_shape', 'padding_admission', 'graph_index', 'graph_gather', 'unit_window_graph', 'unit_window_add_zero', 'unit_window_min', 'unit_window_max', 'rounded_start_refuted', 'unclipped_shape_refuted'],
    'ReductionWindow': ['values_length', 'sample_empty_input', 'values_empty_input', 'unit_count', 'unit_index_unique', 'values_unit', 'axis_unit_position', 'axis_unit_sample', 'sample_unit_affine', 'foldl_replicate_fixed', 'bounded_none_of_outside', 'affine_none_of_axis', 'reduce_empty_kernel', 'reduce_empty_input', 'reduce_empty_input_fixed', 'reduce_empty_output', 'reduce_unit', 'unit_gather', 'unit_gather_initial', 'unit_gather_add_zero', 'unit_gather_min', 'unit_gather_max', 'pointwise', 'pointwise_eliminate', 'unit_crop_all', 'unit_crop_low_all', 'empty_input_components', 'padding_fixed_refuted', 'padding_skip_refuted'],
    'ReductionFiber': ['elementCount_shape', 'output_merge', 'reduced_merge', 'merge_split', 'fiberValues_map', 'fiberValues_constant', 'foldl_replicate_absorb', 'sum_head_tail', 'sum_flatMap', 'fiberValues_sum', 'foldl_map_hom'],
    'ReductionAlgebra': ['constant_absorb', 'constant_and', 'constant_or', 'constant_min', 'constant_max', 'constant_add', 'negate_sum', 'concat_add', 'coordinate_sum', 'sum_reduction', 'map_reduction', 'empty_components', 'sameCount_components', 'empty_constant_refuted', 'repeated_initializer_refuted', 'nonassociative_regrouping_refuted'],
    'ScalarDomains': ['complex_square_sqrt', 'complex_sqrt_square_ofReal',
                      'real_log_exp', 'real_sqrt_square', 'real_log_sqrt_pos',
                      'complex_log_exp_iff', 'complex_sqrt_square_iff_real',
                      'complex_log_exp_counterexample', 'complex_sqrt_square_counterexample',
                      'real_log_exp_tensor', 'complex_log_exp_tensor_iff',
                      'complex_sqrt_square_tensor_iff', 'real_sqrt_square_tensor',
                      'real_log_sqrt_tensor_pos'],
    'ConvolutionOrdered': ['map_finRange_cast', 'map_finRange_singleton', 'convolve_semiring', 'term_pointwise', 'contribution_count_eq', 'channel_position_eq', 'term_eq_dot_product', 'terms_eq_dot_terms', 'convolve_eq_dot', 'dot_eq_convolve', 'convolve_single_channel'],
    'ConvolutionFloat': ['binary32_pointwise_dot', 'binary32_reference_eq', 'binary32_fold_omission_refuted', 'binary32_reversal_refuted'],

    'ConvolutionSeparable': ['output_extent_formula', 'spanning_extent_eq', 'derive_geometry', 'axis_inputIndex_eq', 'spatial_input_eq', 'project_expand', 'expand_project', 'reverse_involution', 'reduced_position_apply', 'term_reduced', 'convolve_eq_productReduction'],
    'ConvolutionDot': ['lhs_index_row', 'lhs_index_channel', 'rhs_index_feature', 'rhs_index_channel', 'matrix_output_row', 'matrix_output_feature', 'convolution_output_dot_output', 'dot_output_convolution_output', 'sum_contract_positions', 'dot_eq_channel_sum', 'convolve_eq_dot', 'dot_eq_convolve'],
    'ConvolutionPointwise': ['dilatedExtent_one', 'output_extent_eq', 'output_shape_eq', 'elementCount_unit', 'kernel_count_eq_one', 'kernel_index_unique', 'base_position_eq', 'axis_inputIndex_eq', 'spatial_input_eq', 'term_pointwise', 'sum_kernel_positions', 'convolve_eq_channelSum', 'convolve_single_channel'],
    'FloatNegation': ['scalar_involution', 'tensor_involution', 'reindex_neg', 'reverse_neg'],
    'FiniteSum': ['foldl_add_eq_sum', 'reduce_add_eq_fiber_sum', 'reshapeEquiv_apply',
                  'sum_reshape', 'sum_swap', 'sum_add'],
    'ContractionAlgebra': ['dot_add_left', 'dot_add_right'],
    'LogicalFamily': ['rewrite_sound', 'allRules_complete', 'allRules_nodup',
                      'word_keys_uniform', 'predicate_count', 'word_count'],
    'Convolution': ['inputIndex?_negative', 'basePosition_reverse', 'inputIndex?_position', 'term_zero_kernel', 'term_zero_input', 'convolve_zero_kernel', 'convolve_zero_input', 'convolve_empty_fiber', 'spatialInput?_empty', 'term_empty_spatial_input', 'convolve_empty_spatial_input', 'convolve_empty_kernel', 'convolve_no_channels', 'term_kernel_add', 'term_input_add', 'term_kernel_scale', 'convolve_kernel_add', 'convolve_input_add', 'convolve_kernel_scale', 'convolve_bias_scale'],
}



def measure_file(name,category,root=ROOT,overrides=None):
    path=root/name;source=path.read_text();lines=source.splitlines(keepends=True)
    digest=hashlib.sha256(path.read_bytes()).hexdigest()
    if overrides is None:
        overrides=json.loads((root/'census/lean-category-overrides-v1.json').read_text())['files']
    override=next((r for r in overrides if r['path']==name),None)
    if override is None:
        return [dict(path=name,category=category,sha256=digest,**count_source(source))]
    assert digest==override['sha256'],name
    rows=[];cursor=1
    for region in override['regions']:
        first=region['first'];last=region['last']
        assert first==cursor and first<=last<=len(lines),region
        assert region['category'] in {'S','H','R','A','C'}
        fragment=''.join(lines[first-1:last])
        rows.append(dict(path=name,category=region['category'],sha256=digest,
                         source_region=dict(first=first,last=last),
                         **count_source(fragment)))
        cursor=last+1
    assert cursor==len(lines)+1
    assert sum(r['code_lines'] for r in rows)==count_source(source)['code_lines']
    return rows


def main():
    build = subprocess.run(['lake', 'build'], cwd=ROOT, text=True, capture_output=True)
    (ROOT / 'reports/theory-build.log').write_text(build.stdout + build.stderr)
    if build.returncode:
        print((build.stdout + build.stderr)[-6000:]); raise SystemExit(build.returncode)
    audit = subprocess.run(['lake', 'env', 'lean', 'tests/fixtures/TheoryAudit.lean'],
                           cwd=ROOT, text=True, capture_output=True)
    assert audit.returncode == 0, audit.stdout + audit.stderr
    dependencies = {}
    for group, names in THEOREMS.items():
        for name in names:
            full_name = 'TensorRewrite.Theory.' + group + '.' + name
            match = re.search(re.escape(full_name) + r"' depends on axioms: \[([^\]]*)\]",
                              audit.stdout)
            if match:
                axioms = {a.strip() for a in match[1].split(',') if a.strip()}
            else:
                assert full_name + "' does not depend on any axioms" in audit.stdout, audit.stdout
                axioms = set()
            assert axioms <= ALLOWED, (full_name, axioms)
            dependencies[full_name] = sorted(axioms)
    categories = {'TensorRewrite/Theory/FloatNegation.lean': 'R',
                  'TensorRewrite/Theory/SlicePad.lean': 'S',
                  'TensorRewrite/Theory/SlicePadLemmas.lean': 'H',
                  'TensorRewrite/Theory/SlicePadFactor.lean': 'R',
                  'TensorRewrite/Theory/SlicePadCounterexamples.lean': 'C',
                  'TensorRewrite/Theory/ReductionWindow.lean': 'S',
                  'TensorRewrite/Theory/ReductionWindowLemmas.lean': 'H',
                  'TensorRewrite/Theory/ReductionWindowAlgebra.lean': 'R',
                  'TensorRewrite/Theory/ReductionWindowCounterexamples.lean': 'C',
                  'TensorRewrite/Theory/ReductionFiber.lean': 'S',
                  'TensorRewrite/Theory/ReductionFiberLemmas.lean': 'H',
                  'TensorRewrite/Theory/ReductionAlgebra.lean': 'R',
                  'TensorRewrite/Theory/ReductionCounterexamples.lean': 'C',
                  'TensorRewrite/Theory/ScalarDomainLemmas.lean': 'H',
                  'TensorRewrite/Theory/ScalarDomains.lean': 'R',
                  'TensorRewrite/Theory/ScalarDomainCounterexamples.lean': 'C',
                  'TensorRewrite/Theory/FiniteSum.lean': 'H',
                  'TensorRewrite/Theory/ContractionAlgebra.lean': 'R',
                  'TensorRewrite/Theory/LogicalFamily.lean': 'S',
                  'TensorRewrite/Theory/LogicalFamilyProof.lean': 'R',
                  'TensorRewrite/Theory/Convolution.lean': 'S',
                  'TensorRewrite/Theory/ConvolutionLemmas.lean': 'H',
                  'TensorRewrite/Theory/ConvolutionAlgebra.lean': 'R',
                  'TensorRewrite/Theory/ConvolutionPointwise.lean': 'S',
                  'TensorRewrite/Theory/ConvolutionPointwiseLemmas.lean': 'H',
                  'TensorRewrite/Theory/ConvolutionPointwiseAlgebra.lean': 'R',
                  'TensorRewrite/Theory/ConvolutionDot.lean': 'S',
                  'TensorRewrite/Theory/ConvolutionDotLemmas.lean': 'H',
                  'TensorRewrite/Theory/ConvolutionDotProof.lean': 'R',
                  'TensorRewrite/Theory/ConvolutionSeparable.lean': 'S',
                  'TensorRewrite/Theory/ConvolutionSeparableLemmas.lean': 'H',
                  'TensorRewrite/Theory/ConvolutionSeparableReindex.lean': 'H',
                  'TensorRewrite/Theory/ConvolutionSeparableProof.lean': 'R',
                  'TensorRewrite/Theory/ConvolutionOrdered.lean': 'S',
                  'TensorRewrite/Theory/ConvolutionOrderedLemmas.lean': 'H',
                  'TensorRewrite/Theory/ConvolutionOrderedProof.lean': 'R',
                  'TensorRewrite/Theory/ConvolutionFloat.lean': 'R',
                  'TensorRewriteTheory.lean': 'A'}
    categories.update({
        'TensorRewrite/Theory/DynamicUpdate.lean': 'S',
        'TensorRewrite/Theory/DynamicUpdateLemmas.lean': 'H',
        'TensorRewrite/Theory/DynamicUpdateProof.lean': 'R',
        'TensorRewrite/Theory/DynamicUpdateStatic.lean': 'R',
        'TensorRewrite/Theory/DynamicUpdateCounterexamples.lean': 'C',

        'TensorRewrite/Theory/OrderFamily.lean': 'S',
        'TensorRewrite/Theory/OrderWord.lean': 'S',
        'TensorRewrite/Theory/OrderFamilyProof.lean': 'R',
        'TensorRewrite/Theory/OrderInstances.lean': 'R',
        'TensorRewrite/Theory/OrderCounterexamples.lean': 'C',

        'TensorRewrite/Theory/NumericalField.lean': 'R',
        'TensorRewrite/Theory/NumericalReal.lean': 'R',
        'TensorRewrite/Theory/NumericalComplex.lean': 'R',
        'TensorRewrite/Theory/NumericalCounterexamples.lean': 'C',

        'TensorRewrite/Theory/ArithmeticFamily.lean': 'S',
        'TensorRewrite/Theory/ArithmeticFamilyProof.lean': 'R',
        'TensorRewrite/Theory/ArithmeticBroadcast.lean': 'R',
        'TensorRewrite/Theory/ArithmeticFloatCounterexamples.lean': 'C',
        'TensorRewrite/Theory/ScatterBatching.lean': 'S',
        'TensorRewrite/Theory/ScatterBatchingLemmas.lean': 'H',
        'TensorRewrite/Theory/ScatterBatchingProof.lean': 'R',
        'TensorRewrite/Theory/ScatterBatchingCounterexample.lean': 'C',
        'TensorRewrite/Theory/IndexVector.lean': 'S',
        'TensorRewrite/Theory/IndexVectorLemmas.lean': 'H',
        'TensorRewrite/Theory/ScatterIndices.lean': 'S',
        'TensorRewrite/Theory/ScatterIndicesProof.lean': 'R',
        'TensorRewrite/Theory/ScatterIndicesCounterexample.lean': 'C',
        'TensorRewrite/Theory/ScatterLayout.lean': 'S',
        'TensorRewrite/Theory/ScatterLayoutLemmas.lean': 'H',
        'TensorRewrite/Theory/ScatterLayoutProof.lean': 'R',
        'TensorRewrite/Theory/ScatterLayoutCounterexample.lean': 'C',
        'TensorRewrite/Theory/ScatterConcat.lean': 'S',
        'TensorRewrite/Theory/ScatterConcatLemmas.lean': 'H',
        'TensorRewrite/Theory/ScatterConcatProof.lean': 'R',
        'TensorRewrite/Theory/OrderedScatter.lean': 'S',
        'TensorRewrite/Theory/OrderedScatterCounterexamples.lean': 'C',
        'TensorRewrite/Theory/OrderedScatterFullWindow.lean': 'H',
        'TensorRewrite/Theory/OrderedScatterGeometry.lean': 'H',
        'TensorRewrite/Theory/OrderedScatterGraph.lean': 'R',
        'TensorRewrite/Theory/OrderedScatterLemmas.lean': 'H',
        'TensorRewrite/Theory/OrderedScatterProof.lean': 'R',
        'TensorRewrite/Theory/OrderedScatterTransport.lean': 'H',

        'TensorRewrite/Theory/Remainder.lean': 'S',
        'TensorRewrite/Theory/RemainderLemmas.lean': 'H',
        'TensorRewrite/Theory/RemainderScalar.lean': 'R',
        'TensorRewrite/Theory/RemainderProof.lean': 'R',
        'TensorRewrite/Theory/RemainderCounterexamples.lean': 'C',
        'TensorRewrite/Theory/UniformSumCounterexample.lean': 'C',

        'TensorRewrite/Theory/PadBroadcast.lean': 'S',
        'TensorRewrite/Theory/PadBroadcastPlan.lean': 'S',
        'TensorRewrite/Theory/PadBroadcastTarget.lean': 'S',
        'TensorRewrite/Theory/PadBroadcastGeometry.lean': 'H',
        'TensorRewrite/Theory/PadBroadcastCompile.lean': 'H',
        'TensorRewrite/Theory/PadBroadcastLemmas.lean': 'H',
        'TensorRewrite/Theory/PadBroadcastProof.lean': 'R',
        'TensorRewrite/Theory/PadBroadcastCounterexamples.lean': 'C',

        'TensorRewrite/Theory/WindowTransport.lean': 'S',
        'TensorRewrite/Theory/WindowTransportLemmas.lean': 'H',
        'TensorRewrite/Theory/WindowTransportProof.lean': 'R',
        'TensorRewrite/Theory/WindowTupleFamily.lean': 'S',
        'TensorRewrite/Theory/WindowTupleFamilyProof.lean': 'R',
        'TensorRewrite/Theory/WindowTupleFloat.lean': 'R',
        'TensorRewrite/Theory/BroadcastWindow.lean': 'S',
        'TensorRewrite/Theory/BroadcastWindowGeometry.lean': 'H',
        'TensorRewrite/Theory/BroadcastWindowTarget.lean': 'S',
        'TensorRewrite/Theory/BroadcastWindowIndex.lean': 'H',
        'TensorRewrite/Theory/BroadcastWindowSampling.lean': 'H',
        'TensorRewrite/Theory/BroadcastWindowFold.lean': 'H',
        'TensorRewrite/Theory/BroadcastWindowProof.lean': 'R',
        'TensorRewrite/Theory/BroadcastWindowCounterexamples.lean': 'C',

        'TensorRewrite/Theory/PrefixWindow.lean': 'S',
        'TensorRewrite/Theory/PrefixWindowStride.lean': 'H',
        'TensorRewrite/Theory/PrefixWindowTarget.lean': 'S',
        'TensorRewrite/Theory/PrefixWindowLemmas.lean': 'H',
        'TensorRewrite/Theory/PrefixWindowSampling.lean': 'H',
        'TensorRewrite/Theory/PrefixWindowArithmetic.lean': 'H',
        'TensorRewrite/Theory/PrefixWindowProof.lean': 'R',
        'TensorRewrite/Theory/PrefixWindowInteger.lean': 'R',
        'TensorRewrite/Theory/PrefixWindowCounterexamples.lean': 'C',

        'TensorRewrite/Theory/LatticeIndex.lean': 'H',
        'TensorRewrite/Theory/PadWindow.lean': 'S',
        'TensorRewrite/Theory/PadWindowLemmas.lean': 'H',
        'TensorRewrite/Theory/PadWindowProof.lean': 'R',
        'TensorRewrite/Theory/PadWindowCounterexamples.lean': 'C',

        'TensorRewrite/Theory/OrderedCoordinates.lean': 'H',
        'TensorRewrite/Theory/FullSpanWindow.lean': 'S',
        'TensorRewrite/Theory/FullSpanWindowLemmas.lean': 'H',
        'TensorRewrite/Theory/FullSpanWindowProof.lean': 'R',
    })
    rows = []
    for name, category in categories.items():
        rows.extend(measure_file(name,category))
    integration = json.loads((ROOT / 'reports/library-setup.json').read_text())
    baseline = json.loads((ROOT / 'reports/pilot-values.json').read_text())
    category_lines = {c: sum(r['code_lines'] for r in rows if r['category'] == c)
                      for c in ('S', 'H', 'R', 'A', 'C')}
    total_categories = {c: baseline['category_lines'][c] + category_lines[c]
                        for c in category_lines}
    total_categories['A'] += integration['new_integration_code_lines']
    count = sum(r['code_lines'] for r in rows)
    assert sum(total_categories.values()) == 2796 + count
    report = dict(status='kernel_checked_mathematical_theory', new_theorem_count=len(dependencies),
                  code_correspondence_performed=False, code_correspondence_future_work=True,
                  source_rewrite_acceptance_claimed=False, mathematical_workload_denominator=None,
                  independently_reviewed_statements=False, build_exit_code=build.returncode,
                  audit_exit_code=audit.returncode, axiom_dependencies=dependencies,
                  files=rows, new_theory_lines=count, previous_custom_lean_lines=2796,
                  category_override_manifest='census/lean-category-overrides-v1.json',
                  category_lines=category_lines, total_custom_category_lines=total_categories,
                  total_custom_lean_lines=2796+count, dependency_packages=integration['packages'],
                  proof_reuse={'FloatNegation.scalar_involution': 'FloatLib Model.neg_neg',
                               'ScalarDomains.real_log_exp': 'Mathlib Real.log_exp',
                               'ScalarDomains.real_sqrt_square': 'Mathlib Real.sqrt_mul_self_eq_abs',
                               'ScalarDomains.complex_log_exp_iff':
                                   'Mathlib Complex.log_exp and principal argument bounds',
                               'ScalarDomains.complex_sqrt_square_iff_real':
                                   'Mathlib principal complex sqrt and normSq; new domain derivation',
                               'FiniteSum.sum_reshape': 'Mathlib Equiv.sum_comp plus existing index theory',
                               'ConvolutionPointwise.convolve_eq_channelSum':
                                   'Mathlib Fin.sum_univ_def and Equiv.sum_comp; derived window geometry',
                               'ConvolutionDot.convolve_eq_dot':
                                   'existing contraction/index inverses, channel reduction, Mathlib sums',
                               'FiniteSum.sum_swap': 'Mathlib Finset.sum_comm',
                               'FiniteSum.sum_add': 'Mathlib Finset.sum_add_distrib'},
                  scope='actual ordered full-window Scatter, reducer roles and trace fusion; '
                        'exact and all-width remainder masks/Iota offsets; fixed-order uniform float diagnostic; '
                        'derived raw Pad/window reshape/Broadcast composition and converted fill; '
                        'covered singleton-window reshape/Broadcast and complete pure singleton tuple family; '
                        'ordered cumulative windows, exact/modular Iota products and count-conversion domains; '
                        'Pad/window fusion with derived empty-safe geometry and converted fill; '
                        'canonical full-span ordered window/reduction/reshape; '
                        'derived Map/Slice/Pad shape and index factorization; '
                        'ordered window folds and unit-window affine gathers; '
                        'exact real and principal-complex log/sqrt domains; '
                        'format-general floating negation; exact finite sums and semiring '
                        'contraction/convolution exact algebra and typed logical family; '
                        'no IEEE reassociation/distributivity claim',
                  theorem_profiles={
                      name: (
                             'actual decoded-Int bounded DynamicSlice/UpdateSlice windows; '
                             'derived membership/embedding inverses, combined-clamp nested updates, '
                             'empty/full and zero-full-axis laws; arbitrary-data Select/map, '
                             'AddZeroClass additive graphs, derived legal unit-stride static Slice; '
                             'signedness/raw-sum/binary32 negative-zero refutations separate; '
                             'no machine conversion, arbitrary-stride, effect or physical closure'
                             if '.DynamicUpdate.' in name else
                             'closed exact linear-order family:44 rule/order/direction instances; '
                             'integer/real and signed/unsigned actual words at all widths; '
                             'explicit pointwise bound/nonnegative/range conditions with executable '
                             'admission equivalence; pure whole-tensor result tags and contexts; '
                             'actual IEEE NaN/signed-zero observations separate; no full record claim'
                             if '.OrderFamily.' in name else
                             'exact totalized Field division with actual bounded Broadcast; '
                             'Mathlib real rpow/exp/sqrt and principal complex cpow/sqrt; '
                             'pointwise sign/positive/nonzero and principal-strip domains explicit; '
                             'five exact premise-dropping refutations; no machine division, '
                             'rounded transcendental, flags, effects, physical or whole-record claim'
                             if '.Numerical.' in name else
                             'closed pure arithmetic trees:43 rule/order instances; actual '
                             'CommRing for Int/Real/Complex/all-width BitVec; shared input identity '
                             'and Boolean conversion/selection explicit; complete unique enumeration '
                             'and context congruence; actual bounded Broadcast sum/product/subtraction '
                             'rebuilding, uniform scalar factor only where stated; separate actual '
                             'binary32 tree refutations of add/product associativity and zero '
                             'annihilation; no IEEE ring, flags/effects/layout or whole-record claim'
                             if '.ArithmeticFamily.' in name else
                             'actual paired operand/index batching; equal extents and inserted '
                             'operand axes disjoint from original vector-indexed axes; arbitrary '
                             'pair ordering and subset of batch axes; actual raw axis projection; '
                             'derive signed positions, identity-vector starts, targets and event/state '
                             'equivalence; empty/relayout laws need no reducer algebra; distinct-role '
                             'word translation and assoc/comm nested fusion only where stated; '
                             'forgetting batching has a concrete slice counterexample; no general '
                             'Transpose/Concat graph bridge, whole-window drop, IEEE algebra, '
                             'external IR admission or full record/workload closure'
                             if '.ScatterBatching.' in name else
                             'actual explicit zero-component raw index tensor with two batches: '
                             'zero raw index elements but two events, decimal Scatter12 versus first-update Map1; '
                             'no external guard or compiler behavior claim'
                             if name.endswith('.ScatterIndices.empty_index_tensor_not_single_map') else
                             'raw vector dimension at arbitrary position or implicit one-component vector; '
                             'bounded coordinate and pack/read inverses; lossless vector-axis relayout; '
                             'actual interleaved raw index/update Scatter bridge with explicit singleton '
                             'window insertion and per-element drop; arbitrary state for input/relayout '
                             'laws, distinct-role all-width word translation only; no decoder equivalence, '
                             'operand/index batching, general transpose/permutation, IEEE algebra, '
                             'external admission or whole-record closure'
                             if '.IndexVector.' in name or '.ScatterIndices.' in name else
                             'actual interleaved update tensor and compact/full window index inverses; '
                             'arbitrary singleton insertions; exact original batch/window event list; '
                             'arbitrary whole-state reducer for layout bridge; explicit hom/assoc/comm '
                             'only for named algebraic laws; distinct-role all-width word translation; '
                             'raw storage order has a concrete counterexample; no operand/index batching, '
                             'implicit index-vector or relative-window permutation bridge, IEEE algebra, '
                             'external IR admission or whole-record closure'
                             if '.ScatterLayout.' in name else
                             'actual leading-axis index/update tensor concatenation; arbitrary common trailing batch ranks/extents; full-rank Scatter windows and shared injective signed axes; derived exact event append with duplicates and elementwise drops; arbitrary whole-state reducer for sequential composition, assoc+comm for result fusion, all-width word Add with distinct parameter roles; no arbitrary Concat axis or general Scatter dimension numbers/IEEE algebra/external IR/whole-record closure'
                             if '.ScatterConcat.' in name else {
                          'repeated_parameter_refuted':
                              'actual duplicate scalar-address word trace with repeated-current '
                              'Add parameters; original11 versus transformed4 at width4',
                          'duplicate_order_refuted':
                              'same two actual scalar-address updates in reversed order under '
                              'pure decimal reducer give12 versus21',
                          'binary32_translate_refuted':
                              'actual full-window scalar binary32 Scatter/Add translation; finite '
                              'original stored bits0 versus transformed0x3f800000; no IEEE associativity',
                          'clamping_refuted':
                              'declared negative-address element drop retains original2; '
                              'clamping that event to coordinate0 instead gives11'
                             }[name.rsplit('.',1)[1]]
                             if '.OrderedScatter.' in name and name.endswith('_refuted') else
                             'arbitrary-rank whole-state ordered events and actual full-rank windows; '
                             'injective signed index axes, omitted starts0, per-element out-of-bounds '
                             'drop without clamping; empty/full-window Map and actual parameter roles; '
                             'assoc or assoc+comm only for named fusion laws, modular word instances; '
                             'no tensor-input Concat/dimension-number/transpose bridge, general '
                             'Scatter, floating associativity, effect or whole-record closure claim'
                             if '.OrderedScatter.' in name else
                             'ordered repeated modular addition for arbitrary count/width/initializer; '
                             'same-width count cast and modular product; no replica geometry, '
                             'communication, host literal or external schedule correspondence'
                             if name.endswith('PrefixWindow.word_replicate_fold') else
                             'actual FloatLib binary32 nearest-even stored bits; ten ordered '
                             'additions of encoding0x3dcccccd from positive zero yield0x3f800001; '
                             'multiplication by exact ten yields0x3f800000; no collective '
                             'all-schedule/refinement refutation or source bug claim'
                             if '.UniformSum.' in name else
                             {
                          'signed_correction_refuted':
                              'signed four-bit minus-five modulo positive four gives minus-one; '
                              'unsigned mask without sign correction gives positive three',
                          'unsigned_wrap_refuted':
                              'unsigned four-bit Iota coordinate7 plus divisor10 wraps to1; '
                              'remainder1 differs from original remainder7',
                          'signed_wrap_refuted':
                              'four-bit coordinate5 plus divisor3 fits unsigned yet crosses the '
                              'sign bit; truncating remainder minus-two differs from positive two'
                             }[name.rsplit('.',1)[1]]
                             if '.Remainder.' in name and name.endswith('_refuted') else
                             'exact Int.tmod and arbitrary-width unsigned/modular signed BitVec.srem; '
                             'explicit total divisor-zero behavior; signed Select/Negate/And and '
                             'bounded same-width Iota with decoded divisor and no-wrap domains; '
                             'arbitrary finite tensor rank/extents; no floating fmod, flags, '
                             'external IR admission, source or whole-record closure claim'
                             if '.Remainder.' in name else
                             {
                          'unequal_fill_refuted':
                              'covered original singleton with explicit Pad fill2, implicit fill0 '
                              'and addition initializer0; source9 versus target5',
                          'converted_fill_refuted':
                              'conversion x+1 maps source Pad fill0 to1, differing from '
                              'addition initializer0; source8 versus converted target6',
                          'retained_spacing_refuted':
                              'original extent2 with interior spacing2 and canceled edge Pad; '
                              'fused extent3 contradicts a retained extent2'
                             }[name.rsplit('.',1)[1]]
                             if '.PadBroadcast.' in name and name.endswith('_refuted') else
                             'raw independent Pad/window axes compile to actual fused attributes; '
                             'singleton coverage from first/last occupied offset; retained unit '
                             'spacing/base/stride/kernel with signed edge cancellation; actual '
                             'Reshape/Broadcast and derived shape transports; two-sided initializer '
                             'identities and actual direct/converted fill equality; no associativity '
                             'or arbitrary geometry/numerical/whole-record closure claim'
                             if '.PadBroadcast.' in name else
                             {
                          'nonneutral_reducer_refuted':
                              'Nat addition with actual initializer/padding1 and input5; '
                              'a covered pair window returns7 while reshape/Broadcast returns5',
                          'uncovered_output_refuted':
                              'neutral Nat addition on a singleton window whose first output '
                              'misses the input; coverage false and actual output0',
                          'coupled_projection_refuted':
                              'pure two-component coupled state on a scalar window; dropping '
                              'the second component changes the observed first result1 to0'
                             }[name.rsplit('.',1)[1]]
                             if '.BroadcastWindow.' in name and name.endswith('_refuted') else
                             'pure singleton-input covering windows and pointwise retained axes; '
                             'coverage derived from integer attributes; real reshape and signed-axis '
                             'Broadcast with derived counts/ordered axes/index maps; exactly one live '
                             'contribution in the original order; two explicit initializer identities; '
                             'no associativity, rounded identity, Pad fusion or whole-record closure'
                             if '.BroadcastWindow.' in name else
                             'all-rank/all-modeled-window pure state transport; operation homomorphism '
                             'requires actual mapped initializer/padding; arbitrary reducer under an '
                             'equivalence; complete singleton tuple-of-tensors value family; no larger '
                             'coupled tuple projection, effects/layout or source cloning claim'
                             if '.WindowTransport.' in name or '.WindowTupleFamily.' in name else
                             'actual FloatLib binary32 addition; same ordered singleton/scalar folds '
                             'with actual initializer/padding; identical stored values/bits including '
                             'exceptional encodings; no flags or changed-schedule claim'
                             if '.WindowTupleFloat.' in name else
                             'one cumulative axis at any position with arbitrary retained positive strides; '
                             'derived output bounds and exact leading-padding/prefix lists; '
                             'initializer fixed point only when dropping leading padding; '
                             'AddMonoid/Semiring laws only where stated; all-width BitVec modular '
                             'Iota/product including 32/64-bit cases; unsigned/signed exact count '
                             'range iff statements; no rounded arithmetic or wrapper/source closure'
                             if '.PrefixWindow.' in name else
                             'independent nonnegative-edge/interior Pad and arbitrary window geometry; '
                             'derived fused spacings/low/high/output shape including empty inputs; '
                             'identical complete ordered lists/folds with the same explicit/implicit '
                             'fill; arbitrary operation/initializer and pure heterogeneous conversion '
                             'retaining converted fill; no external IR admission/flags/layout claim'
                             if '.PadWindow.' in name or '.LatticeIndex.' in name else
                             'canonical mixed kept/full-span window geometry; arbitrary ranks/extents; '
                             'ordered contribution list equals actual Reduction.fiberValues; '
                             'derived equal output counts and logical reshape; arbitrary scalar '
                             'type/operation/initializer/padding; no algebraic law, IEEE/FMA/flags, '
                             'external IR admission or whole-record closure'
                             if '.FullSpanWindow.' in name or '.OrderedCoordinates.' in name else
                             'pure Map/Slice/nonnegative-Pad graph with derived signed-ceiling '
                             'valid interval, legal ordinary Slice attributes and reconstructed '
                             'output shape; arbitrary affine output extent, positive stride and '
                             'signed low padding; arbitrary scalar maps; window corollaries require '
                             'unit kernel/undilated input and padding law; exact AddZeroClass or '
                             'LinearOrder only where stated; no IEEE identity/flags/layout claim'
                             if '.SlicePad.' in name else
                             'ordered window folds with explicit initializer and every invalid '
                             'sample contribution; bounded convolution axis geometry; arbitrary '
                             'scalar/whole-state operations; unit kernel/undilated input for '
                             'affine crop-stride gather; explicit padding fixed-point and '
                             'initializer laws; AddZeroClass/LinearOrder only where stated; '
                             'no IEEE algebra or separate Slice-Pad graph equivalence'
                             if '.ReductionWindow.' in name else
                             'bounded recursive reduction axis plans with derived kept/reduced '
                             'coordinate inverses and actual fiber-sum bridge; constant fibers '
                             'retain the initializer and nonempty premise for absorption; exact '
                             'AddMonoid/AddCommMonoid/AddCommGroup or Boolean/LinearOrder laws '
                             'are explicit; tuple reducers use whole-state initializer laws; '
                             'no IEEE algebra, windows or full-family closure'
                             if '.ReductionFiber.' in name or '.ReductionAlgebra.' in name else
                             'exact real and principal-complex values; real log/exp all inputs; '
                             'real log/sqrt restricted to positive inputs; complex log/exp iff '
                             '-pi < imaginary part <= pi; complex sqrt-square/magnitude iff real '
                             'axis; arbitrary-rank pointwise tensor lifts; no rounded or fast-math '
                             'semantics' if '.ScalarDomains.' in name else
                             'all supported FloatLib value formats; bit-exact negation; '
                             'flags not observed' if '.FloatNegation.' in name else
                             'pure predicate/word tensor values; all ranks/extents/word widths; '
                             'equal-input xor requires value equality' if '.LogicalFamily.' in name else
                             'exact finite sums and ordered reductions under explicitly stated '
                             'AddMonoid/AddCommMonoid and equal-count premises' if '.FiniteSum.' in name
                             else 'explicit ordered binary32 values; shared separate product/add fold; '
                                  'bit-exact pointwise Dot and reference equality; concrete signed-zero '
                                  'and reversed-fold refutations; flags/FMA/backend policy outside model'
                             if '.ConvolutionFloat.' in name
                             else 'arbitrary scalar types/product/add/initializer/finish; identical '
                                  'pointwise convolution and Dot lists/folds; no scalar algebra assumed'
                             if '.ConvolutionOrdered.' in name
                             else 'mixed unit-kernel/output-one windows; undilated/unpadded/unit stride; '
                                  'one input channel; arbitrary rank/extents/groups/features; '
                                  'nonunit-axis reduction and kernel reversal; exact Semiring'
                             if '.ConvolutionSeparable.' in name
                             else 'pointwise convolution as per-group matrix Dot; batch/spatial row '
                                  'flattening with inverse coordinate maps; exact Semiring and identity '
                                  'finish; arbitrary ranks, extents, groups and channels; no IEEE/layout'
                             if '.ConvolutionDot.' in name
                             else 'unit spatial kernel/stride/base dilation; zero padding; arbitrary '
                                  'kernel dilation/reversal, rank, extents, groups and channel counts; '
                                  'exact semiring; channel reduction and single-channel product'
                             if '.ConvolutionPointwise.' in name
                             else 'factored static convolution; positive stride/dilations; signed padding; '
                                  'bounded grouping/sampling; Semiring for algebra; no IEEE contract'
                             if '.Convolution.' in name or '.ConvolutionPointwise.' in name
                             else 'arbitrary static contraction plans; Semiring; identity finish; '
                                  'no rounded floating-point algebra instance')
                      for name in dependencies},
                  audit_stdout=audit.stdout)
    (ROOT / 'reports/theory-progress.json').write_text(json.dumps(report, indent=2)+'\n')
    print('Mathematical theory passed: '+str(len(dependencies))+' theorems; '+str(count)+
          ' new Lean lines; code correspondence deferred.')


if __name__ == '__main__':
    main()
