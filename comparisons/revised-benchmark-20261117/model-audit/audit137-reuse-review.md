# Finite audit of 137 unlinked labels at d3a90a7

At source ledger d3a90a78d8aef76674aa42453f737f2b36d5b3d3, the exact set is reviewed_mathematical_cases.source_ids_without_catalogued_case in comparisons/revised-benchmark-20261117/outcome-ledger.json. It has 137 distinct IDs, with 351 already linked of the 488 lexical records. The independent 118-case artifact remains separate. This review contributes 16 historical reuse rows covering 18 of the 137 labels, all from earlier proofs. This is source-to-statement linkage, with zero fresh proof discoveries or Lean replays. Central ledger integration belongs to the coordinator.

## Verified cohort

At simplifier lines 941–995, addition commutation has a direct constant on the left. Reassociation uses fixed operand order. The two broadcasts are of scalar literals; specialize the historical broadcast lemmas at rank zero and preserve the original sign in (c1−a)+c2. Lines 5255–5372 admit product reassociation under the nonfloating/noncomplex or fast-math gate. The early direct AnyOrder matcher subsumes the later fixed direct branch. Its broadcast alternate remains distinct because Broadcast(ConstantScalar) has Broadcast opcode. The four-factor rule has three independent order bits. Broadcast factor requires a scalar constant and an actual broadcast of a nonconstant; its exact common-extent broadcast profile uses the original broadcast axis map. The ring equality applies independently of host FP settings. Strict IEEE associativity does not follow. See Rule.lhs/rhs, rewrite_sound and ArithmeticBroadcast for bounded index maps and proper smaller graph arithmetic.

At 8142–8156, scalar dynamic slice is the rank-zero specialization of the full-window law (also independently stated by slice_scalar); the two labels share a row. At 8263–8300 the static replacement refuses a negative or unavailable integer. With fitting extents and per-axis nonnegative constants the emitted unit slice is exactly Window.staticAxes, so slice_static applies. At 8545 and 8669 update_full and update_empty handle an equal-shaped patch or any empty patch axis. At 6913–6945 the empty literal keeps the target shape, the identity reshape retains its input, and shape-count transitivity justifies nested reshape fusion. The historical reshape proofs carry the arbitrary intermediate shape and its count equalities. No physical buffer, metadata, native execution or legacy index parsing claim is needed.

The following independently observed receipts cover the rows. For each non-pilot declaration I checked its fully qualified name in both theory-progress.json.audit_stdout and axiom_dependencies, and matched the defining file against files[].sha256. For pilot reshape declarations the exact names and axioms are in the standalone clean audit log lines 127–129. The pilot source hash below identifies the source inspected and is not a new toolchain replay.

| Row suffix | Declaration or specialization | Recorded axioms |
|---|---|---|
| add-order | TensorRewrite.Theory.ArithmeticFamily.rewrite_sound instantiated with Rule.addComm | ['Quot.sound', 'propext'] |
| add-sum | TensorRewrite.Theory.ArithmeticFamily.rewrite_sound instantiated with Rule.addAssoc false false | ['Quot.sound', 'propext'] |
| add-sum-broadcast | TensorRewrite.Theory.ArithmeticFamily.add_broadcast_constants | ['Quot.sound', 'propext'] |
| sub-add | TensorRewrite.Theory.ArithmeticFamily.rewrite_sound instantiated with Rule.subAddConstants false | ['Quot.sound', 'propext'] |
| sub-add-broadcast | TensorRewrite.Theory.ArithmeticFamily.subtract_add_broadcast_constants | ['Quot.sound', 'propext'] |
| mul-product | TensorRewrite.Theory.ArithmeticFamily.rewrite_sound instantiated with Rule.mulAssoc inner outer | ['Quot.sound', 'propext'] |
| mul-four | TensorRewrite.Theory.ArithmeticFamily.rewrite_sound instantiated with Rule.fourFactors outer left right | ['Quot.sound', 'propext'] |
| mul-product-broadcast | TensorRewrite.Theory.ArithmeticFamily.multiply_broadcast_constants | ['Quot.sound', 'propext'] |
| mul-factor-broadcast | TensorRewrite.Theory.ArithmeticFamily.broadcast_uniform_factor | ['Quot.sound', 'propext'] |
| slice-full | TensorRewrite.Theory.DynamicUpdate.slice_full | ['Classical.choice', 'Quot.sound', 'propext'] |
| slice-const | TensorRewrite.Theory.DynamicUpdate.slice_static | ['Classical.choice', 'Quot.sound', 'propext'] |
| update-full | TensorRewrite.Theory.DynamicUpdate.update_full | ['Classical.choice', 'Quot.sound', 'propext'] |
| update-empty | TensorRewrite.Theory.DynamicUpdate.update_empty | ['Classical.choice', 'Quot.sound', 'propext'] |
| reshape-empty | TensorRewrite.Pilot.Reshape.reshapeTensor_empty | [propext, Classical.choice, Quot.sound] |
| reshape-id | TensorRewrite.Pilot.Reshape.reshapeTensor_identity | [propext, Classical.choice, Quot.sound] |
| reshape-compose | TensorRewrite.Pilot.Reshape.reshapeTensor_compose | [propext, Classical.choice, Quot.sound] |

Observed SHA-256 digests.

```
852a798f782560f1d63f4c023e21c825034d84667e6e1e9b20ff692cf6b644a2  TensorRewrite/Pilot/ReshapeRules.lean
4f1ee4f8abf04a8a6acd5d901f26ab997aee0e32320a1d6f9e1384faa7f491d0  TensorRewrite/Theory/ArithmeticBroadcast.lean
d87ddddf5e8d87cc877d99ba4562227a6b174b087c1a5d2e29418549d0d676fc  TensorRewrite/Theory/ArithmeticFamilyProof.lean
127563aead9ffc00b2878b1b3daf4b7b1865dedaa05a99548bcbdc1f9ca21c08  TensorRewrite/Theory/DynamicUpdateProof.lean
73d33ca49cff77600f623ea452a38714bf9e2cef8bab798fcd393a4736619d95  TensorRewrite/Theory/DynamicUpdateStatic.lean
60862a5581a0273d2d17ac98d8536b16251bf735662d98a744d1e2f235c551c1  reports/mathematical-clean-replay-v1-logs/standalone-pilot-audit.log
6ff429f749d829a9d155f1d1e7e45884eb6c198ac40772d5d2945fcae68266b4  reports/theory-progress.json
1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f  sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc
```

## Exhaustive routing index

Each of the 137 IDs appears once below, with kind and line from census/site-case-map.json and inherited evidence from census/mathematical-ledger.json.benchmark_records. The categories are work queues. An inherited name need not prove the output graph; absence of a name is no novelty claim. In particular, V distinguishes an inadmissible tuple, a positive-rank concat obstruction, and a rank-zero legacy-vector specialization already covered by the accepted update-to-pad model. See dus-index-container-scope.md. D includes delegated call paths only: a callee proof transfers after checking the invoked success/failure branch and graph mutations. W has no freestanding rewrite. L can be bounded once exact physical shapes, layouts, and observations are chosen. C requires coordinate or conversion reasoning, with oneDNN promotion needing a backend-policy profile. No cost estimate for a native campaign was measured or authorized.

Highest-value follow-up: inspect the theorem bodies and guards for HandleSqrt/square-real versus square-complex (real absolute value versus signed complex branch cut); HandleExp/zero-* (one scalar identity with separate output constructors); HandleDot/empty (contracted dimension versus empty output); and HandleReduceWindow/empty-* (initializer behavior for output with padding and arbitrary reducer). All have concrete existing pointers. Check the Compare nonnegative LE/GE witnesses before claiming an unattempted rule. Broader physical-dot/conv conversion or package rebuilds are unnecessary for those four reviews.

### C — contracting coordinates, conversion or backend profile (23)

| Source ID | Binding | Inherited declaration evidence |
|---|---|---|
| AssociativeReorderNestedDot/lhs-transpose | 4272 ReplaceInstruction | none recorded |
| AssociativeReorderNestedDot/rhs-transpose | 4272 ReplaceInstruction | none recorded |
| HandleDot/reorder-contracting-lhs | 4470 ReplaceInstruction | none recorded |
| HandleDot/reorder-contracting-rhs | 4470 ReplaceInstruction | none recorded |
| MoveDotParamToRhs/parameter-left | 3089 ReplaceInstruction | none recorded |
| PromoteConvolutionToF32IfNotOnednnCompatible/promote-and-continue | 10976 ReplaceInstruction | none recorded |
| RewriteAsMultiplyDotWithZeroLhsContractingDim/casts-00 | 3926 ReplaceWithNewInstruction | dot_no_contract, dot_no_contract_of_finish_identity |
| RewriteAsMultiplyDotWithZeroLhsContractingDim/casts-01 | 3926 ReplaceWithNewInstruction | dot_no_contract, dot_no_contract_of_finish_identity |
| RewriteAsMultiplyDotWithZeroLhsContractingDim/casts-10 | 3926 ReplaceWithNewInstruction | dot_no_contract, dot_no_contract_of_finish_identity |
| RewriteAsMultiplyDotWithZeroLhsContractingDim/casts-11 | 3926 ReplaceWithNewInstruction | dot_no_contract, dot_no_contract_of_finish_identity |
| RewriteBatchPlusContractingAsReduce/no-free-both | 4362 ReplaceInstruction | none recorded |
| RewriteBatchPlusContractingAsReduce/no-free-lhs | 4362 ReplaceInstruction | none recorded |
| RewriteBatchPlusContractingAsReduce/no-free-rhs | 4362 ReplaceInstruction | none recorded |
| SimplifyConvToDot/pointwise-layout | 11098 ReplaceInstruction | convolve_eq_dot, binary32_pointwise_dot, convolve_eq_dot and 1 more |
| SimplifyConvToMultiply/pointwise-001 | 11219 ReplaceInstruction | none recorded |
| SimplifyConvToMultiply/pointwise-010 | 11219 ReplaceInstruction | none recorded |
| SimplifyConvToMultiply/pointwise-011 | 11219 ReplaceInstruction | none recorded |
| SimplifyConvToMultiply/reduce-001 | 11219 ReplaceInstruction | none recorded |
| SimplifyConvToMultiply/reduce-010 | 11219 ReplaceInstruction | none recorded |
| SimplifyConvToMultiply/reduce-011 | 11219 ReplaceInstruction | none recorded |
| SimplifyConvToMultiply/reduce-101 | 11219 ReplaceInstruction | none recorded |
| SimplifyConvToMultiply/reduce-110 | 11219 ReplaceInstruction | none recorded |
| SimplifyConvToMultiply/reduce-111 | 11219 ReplaceInstruction | none recorded |

### D — resolve call path and selected terminal (18)

| Source ID | Binding | Inherited declaration evidence |
|---|---|---|
| HandleBitcast/broadcast-delegation | 1633 SimplifyTransposeOfBroadcast | none recorded |
| HandleBitcast/chain-delegation | 1615 TryRemovingBitcastOrReshapeTransposeChain | none recorded |
| HandleBitcast/recursive-inner | 1592 HandleBitcast | none recorded |
| HandleConvert/binary-surround-delegation | 6096 TryRemoveUpcastAndDowncastSurroundingBinaryOp | none recorded |
| HandleConvolution/onednn-delegation | 11258 PromoteConvolutionToF32IfNotOnednnCompatible | none recorded |
| HandleConvolution/operand-swap-delegation | 11248 SwapConvOperands | none recorded |
| HandleConvolution/to-dot-delegation | 11265 SimplifyConvToDot | none recorded |
| HandleCopy/swap-delegation | 1957 SwapCopyBitcastCopy | none recorded |
| HandleDot/outer-product-delegation | 4409 RewriteAsMultiplyDotWithZeroLhsContractingDim | none recorded |
| HandleDot/parameter-swap-delegation | 4504 MoveDotParamToRhs | none recorded |
| HandleDot/strength-reduce-delegation | 4458 RewriteBatchPlusContractingAsReduce | none recorded |
| HandleReduce/merge-delegation | 9204 MergeReduces | concat_add |
| HandleReshape/transpose-chain-delegation | 6954 TryRemovingBitcastOrReshapeTransposeChain | none recorded |
| HandleReshape/transpose-hoist-delegation | 6963 TryHoistTransposeOfReshape | none recorded |
| HandleSlice/reverse-reorder-delegation | 8104 TryToReorderSliceAndReverse | none recorded |
| HandleSlice/stride-delegation | 8111 RemoveRedundantStride | none recorded |
| HandleTranspose/broadcast-delegation | 10744 SimplifyTransposeOfBroadcast | none recorded |
| HandleTranspose/chain-delegation | 10433 TryRemovingBitcastOrReshapeTransposeChain | none recorded |

### H — inherited theorem pointer; compare exact source domain and calculation (38)

| Source ID | Binding | Inherited declaration evidence |
|---|---|---|
| HandleAdd/scatter-concat | 1237 ReplaceWithNewInstruction | run_combine, word_combine, entries_concatenate and 2 more |
| HandleAdd/scatter-nested | 1245 ReplaceOperandWith | run_combine_nested, run_combine_nested, scatter_combine_nested |
| HandleCompare/nonnegative-ge | 5944 ReplaceInstruction | false_consistent, quiet_nan_is_nan, quiet_nan_left_refutes and 8 more |
| HandleCompare/nonnegative-gt | 5941 ReplaceInstruction | integer_family, real_family, rewrite_sound and 2 more |
| HandleCompare/nonnegative-le | 5947 ReplaceInstruction | false_consistent, quiet_nan_is_nan, quiet_nan_left_refutes and 8 more |
| HandleCompare/nonnegative-lt | 5938 ReplaceInstruction | integer_family, real_family, rewrite_sound and 2 more |
| HandleConvolution/empty | 11232 ReplaceInstruction | convolve_empty_kernel, convolve_empty_spatial_input, convolve_no_channels |
| HandleDot/empty | 4399 ReplaceWithNewInstruction | dot_empty_contract, dot_empty_lhs, dot_empty_output and 1 more |
| HandleExp/zero-broadcast | 6144 ReplaceInstruction | complex_exp_zero, real_exp_zero |
| HandleExp/zero-scalar | 6144 ReplaceInstruction | complex_exp_zero, real_exp_zero |
| HandleLog/sqrt | 5542 ReplaceWithNewInstruction | real_log_sqrt_tensor_pos |
| HandleMultiply/abs-square | 5229 ReplaceOperandWith | real_abs_square |
| HandleMultiply/exp-product | 5380 ReplaceWithNewInstruction | complex_exp_product, real_exp_product |
| HandleMultiply/rsqrt-square | 5406 ReplaceWithNewInstruction | complex_rsqrt_square, real_rsqrt_square_iff |
| HandleMultiply/sqrt-square | 5394 ReplaceInstruction | complex_sqrt_square, real_sqrt_square_iff |
| HandleReduce/concat | 9323 ReplaceInstruction | concat_add |
| HandleReduceWindow/cumsum-i32-canonicalize-literal | 9775 ReplaceWithNewInstruction | i32_prefix_product, semiring_prefix_product |
| HandleReduceWindow/cumsum-i64-canonicalize-literal | 9775 ReplaceWithNewInstruction | i64_prefix_product, semiring_prefix_product |
| HandleReduceWindow/cumsum-i64-reuse-literal | 9775 ReplaceWithNewInstruction | i64_prefix_product, semiring_prefix_product |
| HandleReduceWindow/empty-single | 9585 ReplaceInstruction | reduce_empty_input_fixed, reduce_empty_output |
| HandleReduceWindow/empty-tuple | 9582 ReplaceWithNewInstruction | empty_input_components, reduce_empty_input_fixed, reduce_empty_output |
| HandleReduceWindow/pad-broadcast-convert-combined | 10098 ReplaceWithNewInstruction | reduce_converted_sequence |
| HandleReduceWindow/pad-broadcast-convert-existing | 10098 ReplaceWithNewInstruction | reduce_converted_sequence |
| HandleReduceWindow/pad-broadcast-direct-combined | 10098 ReplaceWithNewInstruction | reduce_sequence |
| HandleReduceWindow/pad-broadcast-direct-existing | 10098 ReplaceWithNewInstruction | reduce_sequence |
| HandleReduceWindow/pad-fold-convert | 10106 ReplaceWithNewInstruction | convert_initial_fusion, convert_reduce_fusion |
| HandleReduceWindow/pad-fold-direct | 10106 ReplaceWithNewInstruction | reduce_fusion |
| HandleReduceWindow/scalar-single | 9585 ReplaceInstruction | pointwise_eliminate |
| HandleReduceWindow/scalar-tuple | 9582 ReplaceWithNewInstruction | pointwise_eliminate |
| HandleReduceWindow/singleton-tuple | 9634 CloneWithReplacements | singleton_reduce, rewrite_sound |
| HandleScatter/empty-updates | 10244 ReplaceInstructionIfCompatible | empty_components, scatter_empty, run_empty and 2 more |
| HandleSqrt/square-complex | 10294 ReplaceWithNewInstruction | complex_sqrt_square_counterexample, complex_sqrt_square_tensor_iff |
| HandleSqrt/square-real | 10297 ReplaceWithNewInstruction | real_sqrt_square_tensor |
| MergeReduces/combined-axes | 9038 ReplaceWithNewInstruction | sum_reduction |
| TrySimplifyTautologicalCompare/Gt-Gt | 1298 ReplaceWithNewInstruction | integer_family, real_family, rewrite_sound and 2 more |
| TrySimplifyTautologicalCompare/Gt-Lt | 1298 ReplaceWithNewInstruction | integer_family, real_family, rewrite_sound and 2 more |
| TrySimplifyTautologicalCompare/Lt-Gt | 1298 ReplaceWithNewInstruction | integer_family, real_family, rewrite_sound and 2 more |
| TrySimplifyTautologicalCompare/Lt-Lt | 1298 ReplaceWithNewInstruction | integer_family, real_family, rewrite_sound and 2 more |

### L — validate physical offset/layout and copy/alias observations (27)

| Source ID | Binding | Inherited declaration evidence |
|---|---|---|
| HandleBitcast/compatible-stage | 1610 ReplaceInstructionIfCompatible | cell_bitcast_refl |
| HandleBitcast/compose-stage | 1599 ReplaceWithNewInstruction | cell_bitcast_compose |
| HandleBitcast/unary-sandwich | 1585 ReplaceWithNewInstruction | cell_bitcast_sandwich |
| HandleBitcastConvert/compatible | 1952 ReplaceInstructionIfCompatible | logical_convert_refl, physical_convert_refl |
| HandleBitcastConvert/compose | 1905 ReplaceWithNewInstruction | logical_convert_compose, physical_convert_compose |
| HandleBitcastConvert/last-contiguous-axis | 1946 ReplaceWithBitcast | join_split, physical_split_bit_count, split_join |
| HandleBitcastConvert/same-physical-shape | 1923 ReplaceWithBitcast | physical_convert_same_width, width_eq_of_nonempty |
| HandleCopy/chain-bitcast | 1986 ReplaceWithBitcast | none recorded |
| HandleCopy/compatible | 1972 ReplaceInstructionIfCompatible | none recorded |
| HandleCopy/reshape-clone | 2000 ReplaceWithNewInstruction | none recorded |
| HandleCopy/reshape-reorder-new-copy-bitcast | 2094 ReplaceInstruction | none recorded |
| HandleCopy/reshape-reorder-new-copy-reshape | 2094 ReplaceInstruction | none recorded |
| HandleCopy/reshape-reorder-omit-copy-bitcast | 2094 ReplaceInstruction | none recorded |
| HandleCopy/reshape-reorder-omit-copy-reshape | 2094 ReplaceInstruction | none recorded |
| HandleCustomCall/layout-copy | 6131 ReplaceWithNewInstruction | none recorded |
| HandleCustomCall/layout-identity | 6129 ReplaceInstruction | none recorded |
| HandleReshape/bitcast-chain | 7195 ReplaceWithBitcast | none recorded |
| HandleReshape/copy-reorder | 7076 ReplaceInstruction | none recorded |
| HandleTranspose/degenerate-reshape | 10574 ReplaceWithNewInstruction | none recorded |
| HandleTranspose/layout-bitcast | 10585 ReplaceWithBitcast | transpose_eq_bitcast |
| SimplifyTransposeOfBroadcast/mapped-dims-layout | 2946 ReplaceInstruction | none recorded |
| SwapCopyBitcastCopy/move-bitcast | 1877 ReplaceWithNewInstruction | none recorded |
| SwapCopyBitcastCopy/move-copy | 1893 ReplaceWithNewInstruction | none recorded |
| TryHoistTransposeOfReshape/contiguous-chunks | 6905 ReplaceWithNewInstruction | none recorded |
| TryRemovingBitcastOrReshapeTransposeChain/layout-bitcast | 6844 ReplaceWithNewInstruction | none recorded |
| TryRemovingBitcastOrReshapeTransposeChain/layout-identity | 6834 ReplaceInstruction | none recorded |
| TryRemovingBitcastOrReshapeTransposeChain/logical-identity | 6852 ReplaceInstruction | none recorded |

### R — reviewed in accompanying reuse rows (18)

| Source ID | Binding | Inherited declaration evidence |
|---|---|---|
| HandleAdd/constant-right | 945 ReplaceWithNewInstruction | add_comm, complex_family, integer_family and 4 more |
| HandleAdd/constant-subtract-broadcast-scalars | 994 ReplaceWithNewInstruction | sub_add_broadcast, complex_family, integer_family and 5 more |
| HandleAdd/constant-subtract-direct-constants | 994 ReplaceWithNewInstruction | sub_add_constant, complex_family, integer_family and 4 more |
| HandleAdd/constant-sum-broadcast-scalars | 973 ReplaceWithNewInstruction | add_broadcast_assoc, add_broadcast_constants, complex_family and 5 more |
| HandleAdd/constant-sum-direct-constants | 973 ReplaceWithNewInstruction | add_assoc, complex_family, integer_family and 4 more |
| HandleDynamicSlice/constant-indices | 8297 ReplaceWithNewInstruction | slice_static |
| HandleDynamicSlice/same-shape | 8155 ReplaceInstruction | slice_full |
| HandleDynamicSlice/scalar | 8150 ReplaceInstruction | slice_scalar |
| HandleDynamicUpdateSlice/empty-update | 8670 ReplaceInstruction | update_empty |
| HandleDynamicUpdateSlice/full-update | 8546 ReplaceInstruction | update_full |
| HandleMultiply/broadcast-factor | 5338 ReplaceWithNewInstruction | broadcast_factor_any_order, broadcast_uniform_factor |
| HandleMultiply/constant-product | 5302 ReplaceWithNewInstruction | mul_assoc, mul_assoc_any_order, complex_family and 5 more |
| HandleMultiply/four-factors | 5274 ReplaceWithNewInstruction | four_factors, four_factors_any_order, complex_family and 5 more |
| HandleMultiply/legacy-constant-product-broadcast-scalars | 5368 ReplaceWithNewInstruction | mul_broadcast_assoc, complex_family, integer_family and 5 more |
| HandleMultiply/legacy-constant-product-direct | 5368 ReplaceWithNewInstruction | complex_family, integer_family, real_family and 3 more |
| HandleReshape/compose | 6941 ReplaceWithNewInstruction | reshapeTensor_compose |
| HandleReshape/empty | 6927 ReplaceWithNewInstruction | reshapeTensor_empty |
| HandleReshape/identity | 6935 ReplaceInstruction | reshapeTensor_identity |

### U — source expression or missing bridge needs inspection (7)

| Source ID | Binding | Inherited declaration evidence |
|---|---|---|
| HandleConvert/constant-fold | 6092 ReplaceWithNewInstruction | none recorded |
| HandleConvert/same-type | 6061 ReplaceInstruction | none recorded |
| HandleGather/reshape-pad-hoist | 4853 ReplaceInstruction | none recorded |
| HandleMaximum/sink-erf | 5024 ReplaceWithNewInstruction | none recorded |
| HandleMaximum/sink-logistic | 5024 ReplaceWithNewInstruction | none recorded |
| HandleMaximum/sink-tanh | 5024 ReplaceWithNewInstruction | none recorded |
| HandleReshape/broadcast | 7089 ReplaceWithNewInstruction | none recorded |

### V — container admissibility audited (2)

| Source ID | Binding | Inherited declaration evidence |
|---|---|---|
| HandleDynamicUpdateSlice/pad-concatenate | 8539 ReplaceInstruction | none recorded |
| HandleDynamicUpdateSlice/pad-tuple | 8539 ReplaceInstruction | none recorded |

### W — wrapper needs original caller and observation (4)

| Source ID | Binding | Inherited declaration evidence |
|---|---|---|
| ReplaceInstructionIfCompatible/single | 876 ReplaceInstruction | none recorded |
| ReplaceInstructionIfCompatible/span-single | 896 ReplaceInstructionIfCompatible | none recorded |
| ReplaceInstructionIfCompatible/span-tuple | 910 ReplaceInstruction | none recorded |
| ReplaceWithBitcast/unary | 855 ReplaceInstruction | none recorded |

Reproducibility: extract the exact revision’s ledger with git show, select the array named above, then join strings to site-case-map.bindings.case_id and mathematical-ledger.benchmark_records.benchmark_id. Check that all 137 IDs are unique and that the table IDs equal that set. The companion JSON links 18 distinct IDs. No assertion that the remaining 119 are distinct mathematical cases. No elapsed historical discovery-time estimates.

Independent inspection started at 02:54:50 UTC, 2026-11-18. Initial source/cohort checkpoint at 02:57:18. No native or Lean builds, downloads or delegates. Compiler time zero; active reasoning and token costs unmeasured.
Audit and report completed 03:05:33 UTC.
