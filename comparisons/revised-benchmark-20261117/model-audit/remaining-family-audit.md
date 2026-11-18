# Remaining source families at 18394ce

This is a read-only crosswalk at `18394ce32f86ff0cab183007fec94e9f26f89c03`. The 488 labels are return sites, delegated calls, or branches in pinned XLA `e58e523b11f1fde802a493a776d158007486e1bf`. Of these, 218 have a reviewed mathematical case or historical reuse link, and 270 lack either link. The catalog has 134 proofs and 23 refutations of explicit expression/domain cases. The number of distinct mathematical cases still open cannot be calculated from 270. The source register uses a stronger observation and has seven configured record refutations and 481 unresolved rows. [Source ledger](../outcome-ledger.json) · [Source pins](../../../sources/manifest.json) · [Adopted plan](../../../docs/experiment-plan.md)

The 118 executed paper cases have separate stable IDs in the Zenodo 10.5281/zenodo.14159871 artifact. Its historical Lean outcomes were 116 proofs, one refutation (`slice/rule13`) and one vacuous result (`conv/rule01`). New evidence does not supply their discovery times. The source catalog already has explicit historical reuse links for DynamicSlice/Broadcast and Reduce/Dot. Neither adding 118 to 157 nor subtracting 118 from 488 gives coverage of distinct rules. [Historical cases, with statements, proof files and results](../../tensorright-v1/cases.json) · [Catalog/reuse construction](../model_cases.py)

## Which records warrant work first

1. **One nonempty scalar-broadcast reduction family.** At simplifier lines 9419–9440 one matcher selects four operations. Positive fiber size follows from the earlier empty dispatch at 8851–8855 and 9057–9059 for a scalar result, and reducing all broadcast dimensions leaves one scalar. `constant_and`, `constant_or`, `constant_min` and `constant_max` prove that the actual initializer and repeated value reduce to the source operand order. The follow-up below checked the four public statements against these branches. Bool predicates and a mathematical linear order are precise starting domains. Floating NaNs and signed zeros require their own observation if selected. No claim of four fresh proof discoveries. [Source](../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc#L9419) · [Existing terminals](../../../TensorRewrite/Theory/ReductionAlgebra.lean#L31)
2. **One new model witness to test.** `HandleReduce/negate-sum` explicitly requires floating elements. The `negate_sum` additive-group theorem uses exact arithmetic. Check the two original and replacement folds on two positive zeros with positive-zero initializer under strict binary32 round-to-nearest-even and bit-pattern observation. Each addition of positive and negative zero in the original returns positive zero, whereas negating the positive-zero replacement sum gives negative zero. Length two avoids singleton forwarding. Verify source reduction seed and signed-zero permissions, freeze the precise observation and obtain an independent check before counting. Native reachability and any source-level violation remain open. [Source](../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc#L9097) · [Exact-domain prior](../../../TensorRewrite/Theory/ReductionAlgebra.lean#L76)
3. **Adjacent slices and pad ends.** `concat/rule04` already proves `touching_slices` for two legal slices. The arbitrary-context pair and ordered run lemmas are also present. Check the source loop's actual compatibility and remaining-axis slice guards for the maximal run; prefer a reuse crosswalk when hypotheses match. The low/high scalar pad IDs have historical `concat/rule05` and `concat/rule06` respectively. Validate broadcast width, axis and all other extents against the full source extraction before linking. [Historical proofs](../../tensorright-v1/Concatenate.lean#L65) · [Context extension](../../../TensorRewrite/Theory/ConcatenationAdjacent.lean#L73) · [Source](../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc#L2227)
4. **Reduction through reshape remains a separate active obligation.** The two lexical exits at 9260/9287 keep different lists of unmodified axes. A common row-major bijection would justify sharing a case only after showing it matches the two generated reduction fibers and the assumed reducer semantics. This audit assigns no worker and records no proof.

## Alias and exclusion checks

The 270 unlinked IDs include 24 without a primary site ID. The other 246 occupy 161 distinct primary replacement sites; 38 of these sites have multiple unlinked labels (123 labels total). These are relationships among unlinked rows only. The table preserves line numbers for all 270, including delegated calls. Same line licenses source inspection, never automatic semantic deduplication. For example, line 9435 distinguishes Boolean and ordered scalar operators. Conversely, distinct lines 9204 and 9038 are the caller and terminal of `MergeReduces`. There is no second transformation at 9204. The historical theorem `reduce/rule05` uses three grouped shapes and additive commutativity; matching the source still requires the physical-axis lifting and the input reducer/initializer contract. [Source bindings](../../../census/site-case-map.json) · [Caller](../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc#L9204) · [Helper](../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc#L9014) · [Historical reduction](../../tensorright-v1/GroupedSums.lean#L78)

Other concrete aliases include the AllReduce and ReduceScatter handlers forwarding to exactly the same helper at 1495/1500, and the Conv-to-Multiply delegation invoking the helper at 11270. Their destination computations and type/shape variants must still be checked. Generic `ReplaceInstructionIfCompatible` and `ReplaceWithBitcast` rows require a caller's original and replacement computation before treating them as a mathematical rule. The 4 operand placements in the conv/add/multiply helper share a site; pure commutativity and floating exceptional behavior require separate domains. RNG reshaping needs a distribution or stream observation, dense layout/bitcast needs a physical shape and element encoding, collective rewrites need reduction/replica semantics, and effects need an explicit observation if included. These narrower dependencies affect their own cases. The adopted plan permits pure exact-model work without resolving those extensions. [Pinned simplifier](../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc) · [Theory scope](../../../docs/theory-scope.md)

No new owner ruling is required for the three bounded candidates above under the current contract. Kevin and Arie's decision remains mandatory before a large or expensive campaign. A project-wide denominator would require an explicit versioned, reviewed normalization of original calculation, replacement, domain and observation for all records including delegations/shared sites. Decide unresolved optional semantic profiles individually only when they change the intended mathematical question; source-label counts do not determine that choice. [Assignment contract](../CONTRACT.md)

## Exhaustive unresolved crosswalk

The first column is the site-map's C++ owner. Append a slash and any listed suffix to recover the exact lexical ID. Parentheses give the source line. Inherited status **N** means no inherited attempt evidence and a formulation/domain split is needed (87 IDs); **P** means partial model evidence requires partition review (126); **F** means a declared value family is complete but full-record partitions remain open (57). Among the same 270, the newer work-state field marks 181 as inherited partial, 87 with no inherited attempt and two as revised evidence. Those two are `HandleCompare/nonnegative-ge` and `HandleCompare/nonnegative-le`, which already have historical configured witnesses and reviewed model refutations outside this catalog. Preserve their evidence and record-specific residuals. No unlinked ID is being declared newly proved, disproved, or never attempted solely from missing links.

### arithmetic-cases (57)

| Source family | Inherited | Branch suffix and source line |
|---|---|---|
| HandleAdd | F | `constant-right` (945), `constant-subtract-broadcast-scalars` (994), `constant-subtract-direct-constants` (994), `constant-sum-broadcast-scalars` (973), `constant-sum-direct-constants` (973), `factor-lhs-lhs` (1087), `factor-lhs-rhs` (1087), `factor-rhs-lhs` (1087), `factor-rhs-rhs` (1087) |
| HandleAdd | P | `partial-update-lhs` (1051), `partial-update-rhs` (1051), `scatter-concat` (1237), `scatter-nested` (1245) |
| HandleCompare | F | `nonnegative-ge` (5944), `nonnegative-gt` (5941), `nonnegative-le` (5947), `nonnegative-lt` (5938) |
| HandleDivide | P | `broadcast-reciprocal` (2736), `constant-broadcast` (2711), `constant-direct` (2711), `exp-denominator` (2636), `exp-pair` (2624), `fractions` (2751), `nested-denominator` (2769), `nested-numerator` (2760), `one` (2597), `power-denominator` (2656), `predicate-scalar-broadcast` (2785), `rsqrt-denominator` (2674), `sqrt-denominator` (2665) |
| HandleMaximum | F | `clamp-lhs-lhs` (4983), `clamp-lhs-rhs` (4983), `clamp-lower-lhs` (4997), `clamp-lower-rhs` (4997), `clamp-rhs-lhs` (4983), `clamp-rhs-rhs` (4983), `lhs-extreme` (4942), `nested-left-lhs` (4953), `nested-left-rhs` (4953), `nested-right-first` (4957), `nested-right-second` (4964), `rhs-extreme` (4946), `self` (4928) |
| HandleMaximum | N | `sink-erf` (5024), `sink-logistic` (5024), `sink-tanh` (5024) |
| HandleMinimum | F | `clamp-lhs-lhs` (5094), `clamp-lhs-rhs` (5094), `clamp-rhs-lhs` (5094), `clamp-rhs-rhs` (5094), `lhs-extreme` (5053), `nested-left-lhs` (5064), `nested-left-rhs` (5064), `nested-right-first` (5068), `nested-right-second` (5075), `rhs-extreme` (5057), `self` (5039) |

### collective-rotation-cases (11)

| Source family | Inherited | Branch suffix and source line |
|---|---|---|
| HandleAllReduce | N | `shared-handler` (1495) |
| HandleAllReduceOrReduceScatter | P | `sum-floating` (1483), `sum-integral` (1483) |
| HandleReduceScatter | N | `shared-handler` (1500) |
| HandleRemainder | P | `iota-add-lhs` (6695), `iota-add-rhs` (6695), `iota-in-range` (6660), `nested` (6621), `power-two-signed` (6636), `power-two-unsigned` (6636) |
| TryToSinkBroadcastAfterElementwiseOps | N | `eligible-user` (6544) |

### convolution-cases (26)

| Source family | Inherited | Branch suffix and source line |
|---|---|---|
| HandleConvolution | N | `onednn-delegation` (11258), `operand-swap-delegation` (11248), `scalar-movement-delegation` (11226), `to-dot-delegation` (11265), `to-multiply-delegation` (11270) |
| HandleConvolution | P | `empty` (11232) |
| PromoteConvolutionToF32IfNotOnednnCompatible | N | `promote-and-continue` (10976) |
| ScalarMultiplyReduction | N | `target-lhs` (748), `target-rhs` (748) |
| SimplifyConvToDot | P | `pointwise-layout` (11098) |
| SimplifyConvToMultiply | N | `pointwise-001` (11219), `pointwise-010` (11219), `pointwise-011` (11219), `reduce-001` (11219), `reduce-010` (11219), `reduce-011` (11219), `reduce-101` (11219), `reduce-110` (11219), `reduce-111` (11219) |
| SimplifyConvToMultiply | P | `pointwise-000` (11219), `reduce-000` (11219), `reduce-100` (11219) |
| TryToReorderConvAddMultiply | P | `order-lhs-lhs` (5180), `order-lhs-rhs` (5180), `order-rhs-lhs` (5180), `order-rhs-rhs` (5180) |

### dot-cases (20)

| Source family | Inherited | Branch suffix and source line |
|---|---|---|
| AssociativeReorderNestedDot | N | `lhs-transpose` (4272), `rhs-transpose` (4272) |
| HandleDot | N | `outer-product-delegation` (4409), `parameter-swap-delegation` (4504), `reorder-contracting-lhs` (4470), `reorder-contracting-rhs` (4470), `strength-reduce-delegation` (4458) |
| HandleDot | P | `empty` (4399) |
| MoveDotParamToRhs | N | `parameter-left` (3089) |
| ReplaceInstructionIfCompatible | N | `single` (876), `span-single` (896), `span-tuple` (910) |
| ReplaceWithBitcast | N | `unary` (855) |
| RewriteAsMultiplyDotWithZeroLhsContractingDim | P | `casts-00` (3926), `casts-01` (3926), `casts-10` (3926), `casts-11` (3926) |
| RewriteBatchPlusContractingAsReduce | N | `no-free-both` (4362), `no-free-lhs` (4362), `no-free-rhs` (4362) |

### layout-cases (22)

| Source family | Inherited | Branch suffix and source line |
|---|---|---|
| HandleBitcast | N | `broadcast-delegation` (1633), `chain-delegation` (1615), `recursive-inner` (1592) |
| HandleBitcast | P | `compatible-stage` (1610), `compose-stage` (1599), `unary-sandwich` (1585) |
| HandleBitcastConvert | P | `compatible` (1952), `compose` (1905), `last-contiguous-axis` (1946), `same-physical-shape` (1923) |
| HandleCopy | N | `chain-bitcast` (1986), `compatible` (1972), `compose-copy` (1966), `compose-identity` (1964), `reshape-clone` (2000), `reshape-reorder-new-copy-bitcast` (2094), `reshape-reorder-new-copy-reshape` (2094), `reshape-reorder-omit-copy-bitcast` (2094), `reshape-reorder-omit-copy-reshape` (2094), `swap-delegation` (1957) |
| SwapCopyBitcastCopy | N | `move-bitcast` (1877), `move-copy` (1893) |

### reduction-cases (43)

| Source family | Inherited | Branch suffix and source line |
|---|---|---|
| HandleReduce | N | `broadcast-base-axes` (9490), `reshape-output-axes` (9287), `reshape-reduced-axes` (9260) |
| HandleReduce | P | `broadcast-replicated-axes` (9543), `concat` (9323), `merge-delegation` (9204), `negate-sum` (9103), `scalar-broadcast-and` (9435), `scalar-broadcast-maximum` (9435), `scalar-broadcast-minimum` (9435), `scalar-broadcast-or` (9435) |
| HandleReduceWindow | F | `singleton-tuple` (9634) |
| HandleReduceWindow | P | `cumsum-i32-canonicalize-literal` (9775), `cumsum-i32-reuse-literal` (9775), `cumsum-i64-canonicalize-literal` (9775), `cumsum-i64-reuse-literal` (9775), `empty-single` (9585), `empty-tuple` (9582), `full-dimensions` (9911), `pad-broadcast-convert-combined` (10098), `pad-broadcast-convert-existing` (10098), `pad-broadcast-direct-combined` (10098), `pad-broadcast-direct-existing` (10098), `pad-fold-convert` (10106), `pad-fold-direct` (10106), `scalar-single` (9585), `scalar-tuple` (9582), `singleton-add-no-pad-crop` (9868), `singleton-add-no-pad-no-crop` (9868), `singleton-add-pad-crop` (9868), `singleton-add-pad-no-crop` (9868), `singleton-crop-all-add` (9837), `singleton-crop-all-maximum` (9837), `singleton-crop-all-minimum` (9837), `singleton-maximum-no-pad-crop` (9868), `singleton-maximum-no-pad-no-crop` (9868), `singleton-maximum-pad-crop` (9868), `singleton-maximum-pad-no-crop` (9868), `singleton-minimum-no-pad-crop` (9868), `singleton-minimum-no-pad-no-crop` (9868), `singleton-minimum-pad-crop` (9868), `singleton-minimum-pad-no-crop` (9868) |
| MergeReduces | P | `combined-axes` (9038) |

### scalar-control-cases (30)

| Source family | Inherited | Branch suffix and source line |
|---|---|---|
| HandleClamp | F | `idempotent` (5111), `runtime-id` (5131) |
| HandleConvert | N | `binary-surround-delegation` (6096), `constant-fold` (6092), `same-type` (6061) |
| HandleCustomCall | N | `layout-copy` (6131), `layout-identity` (6129) |
| HandleLog | P | `exp` (5512), `power-complex` (5533), `power-real` (5533), `rsqrt` (5550), `sqrt` (5542) |
| HandlePower | P | `exp-base` (6424), `half` (6456), `minus-one` (6448), `one` (6414), `three` (6441), `two` (6431), `zero` (6410) |
| HandleReducePrecision | N | `full-width` (9563) |
| HandleRsqrt | P | `inverse-square` (8126), `reciprocal` (8134) |
| HandleScatter | P | `empty-indices` (10251), `empty-updates` (10244) |
| HandleSelect | P | `update-false-scalar-pred` (10231), `update-false-tensor-pred` (10231), `update-true-scalar-pred` (10231), `update-true-tensor-pred` (10231) |
| HandleSqrt | P | `square-complex` (10294), `square-real` (10297) |

### shape-cases (22)

| Source family | Inherited | Branch suffix and source line |
|---|---|---|
| HandleReshape | N | `bitcast-chain` (7195), `broadcast` (7089), `copy-reorder` (7076), `rng-shape` (6950), `transpose-chain-delegation` (6954), `transpose-hoist-delegation` (6963) |
| HandleReshape | P | `compose` (6941), `empty` (6927), `identity` (6935) |
| HandleSlice | N | `reduce-window` (8088), `reverse-reorder-delegation` (8104), `stride-delegation` (8111) |
| HandleTranspose | N | `broadcast-delegation` (10744), `chain-delegation` (10433), `degenerate-reshape` (10574), `rng-shape` (10581) |
| HandleTranspose | P | `layout-bitcast` (10585) |
| SimplifyTransposeOfBroadcast | N | `mapped-dims-layout` (2946) |
| TryHoistTransposeOfReshape | N | `contiguous-chunks` (6905) |
| TryRemovingBitcastOrReshapeTransposeChain | N | `layout-bitcast` (6844), `layout-identity` (6834), `logical-identity` (6852) |

### simple-cases (16)

| Source family | Inherited | Branch suffix and source line |
|---|---|---|
| HandleExp | P | `zero-broadcast` (6144), `zero-scalar` (6144) |
| HandleMultiply | F | `constant-product` (5302), `four-factors` (5274), `legacy-constant-product-broadcast-scalars` (5368), `legacy-constant-product-direct` (5368) |
| HandleMultiply | N | `conv-reorder-delegation` (5412) |
| HandleMultiply | P | `abs-square` (5229), `broadcast-factor` (5338), `exp-product` (5380), `rsqrt-square` (5406), `sqrt-square` (5394) |
| TrySimplifyTautologicalCompare | F | `Gt-Gt` (1298), `Gt-Lt` (1298), `Lt-Gt` (1298), `Lt-Lt` (1298) |

### tensor-index-cases (23)

| Source family | Inherited | Branch suffix and source line |
|---|---|---|
| HandleBroadcast | N | `sink-users-delegation` (5831) |
| HandleConcatenate | F | `adjacent-slices` (2227), `filter-all-empty` (2131), `filter-many-nonempty` (2131), `filter-one-nonempty` (2131), `flatten` (2156), `pad-high` (2262), `pad-low` (2262), `repeat-unit-axis` (2277), `unary` (2108) |
| HandleDynamicSlice | P | `constant-indices` (8297), `same-shape` (8155), `scalar` (8150), `zero-full-axis-indices` (8175) |
| HandleDynamicUpdateSlice | N | `pad-concatenate` (8539), `pad-scalar-list` (8539), `pad-tuple` (8539) |
| HandleDynamicUpdateSlice | P | `empty-update` (8670), `full-update` (8546), `nested` (8699), `zero-full-axis-indices` (8659) |
| HandleGather | N | `empty-input` (4637), `reshape-pad-hoist` (4853) |

## Reproduction and effort

At the pinned revision, read `census/mathematical-ledger.json:benchmark_records`, `census/site-case-map.json:bindings` and `comparisons/revised-benchmark-20261117/outcome-ledger.json:reviewed_mathematical_cases`. Form the union of the arrays `source_ids` from `cases` and `historical_reuse_links`, subtract it from the unique 488 `benchmark_id` values and assert equality with `source_ids_without_catalogued_case`. Join on `case_id`, assert that every remaining ID prefix equals the binding owner, then group by source batch, owner and `mathematical_target_status`. Primary-site multiplicities omit absent `site_id` values. The input ledger contains the immutable source hashes. This audit read all rows and inspected selected source and theorem bodies. No new kernel replay, implementation execution or independent proof acceptance occurred.

## Independent historical reuse decision

**Accept four source links as inherited theorem reuse** for `HandleReduce/scalar-broadcast-and` (Bool), `-or` (Bool), `-minimum` (a mathematical linear order, e.g. Int), and `-maximum` (the same ordered domain). Read the four public declarations, their proofs through `constant_absorb` and `foldl_replicate_absorb`, and the actual Plan/fiber definitions. Specialize the plan to `.reduce` on each input extent followed by `.scalar`. Its output has rank zero, and `fiberCount` is the product of input extents. An empty input takes the earlier BroadcastReduce exit. A singleton in layout-insensitive mode can also exit earlier. For positive multiplicity the enumerated constant tensor folds to exactly `op(value,initial)`; each actual input position and output coordinate is covered. Theorems allow any initializer, including source-required identities. A length-two broadcast is inhabited. Erasing the initializer would change an arbitrary-initializer conjunction at (value=true, initial=false); an empty conjunction would yield its initializer even if the value disagreed. The actual typed source selects the appropriate binary opcode and operand order. These cases do not cover arbitrary machine bitwise AND/OR or exceptional float ordering. [Reduction plan and fold](../../../TensorRewrite/Pilot/Reduction.lean) · [Absorption](../../../TensorRewrite/Theory/ReductionFiberLemmas.lean#L96) · [Source](../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc#L9419)

Both historical receipts attribute precisely `Classical.choice`, `Quot.sound` and `propext` to each of the four named declarations. The theory receipt records build and audit exit zero and its source hashes for ReductionAlgebra and ReductionFiberLemmas match current Git files. The reduction manifest SHA-256 matches the historical receipt, `906b1e51aa8143415177a5116d6056e44c3559b0dbafa4c6984d4b546c92dd83`. Historical controls include all-reduced extents with six elements and an empty fiber returning its initializer. This follow-up independently read the proof source, checked the receipts and their hashes, and did not recompile Mathlib or independently re-execute the historical build. Reuse adds zero fresh discoveries. [Historical reduction receipt](../../../reports/reduction-algebra.json) · [Historical theory build and dependency audit](../../../reports/theory-progress.json)

Audit worker's first checkout 01:14:40 UTC on November 18; initial inventory and source audit through 01:17:39 (179 seconds elapsed). The four-terminal follow-up and independent sink review overlapped during the same worker window beginning 01:17:48. Separate exclusive reasoning time and token usage were not measured.
