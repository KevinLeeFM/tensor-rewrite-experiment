# Independent Codex review: census/pilot v1

Reviewer: a separate Codex subagent, task `census_pilot_review`, explicitly
approved by the human in the parent conversation. Model identifier and reasoning
configuration are not exposed to this reviewer and remain unknown. Review date:
10 November 2026. This is an agent inspection, not accountable human sign-off or
checked C++ translation. No acceptance state or frozen artifact was changed.

**Disposition: retain zero accepted source rewrites and leave N/F unfrozen.**
The frozen logical proofs replay successfully and the twenty selected targets
have meaningful, appropriately limited statements. I found no failed Lean proof
or new axiom in that replay. I found packaging/reproduction defects and a small
structural-count labeling error. The semantic census and full source-to-theorem
correspondence review are incomplete; this review does not satisfy that gate.

## Authenticated inputs and execution

- Packet: `reviews/packets/census-pilot-v1.md` and descriptor `.json`.
- Archive SHA256:
  `f119335b261a0930a5a2497f5ba3339570d34c5ee6e4baf4a26345cf12b55ce3`.
- Manifest SHA256:
  `da6899931075f018df5d7189c10e8bb87ee4e2560433b2d96e3c1d85f1bdaca4`.
- All 560 manifest data inputs were checked for byte count and SHA256. The zip
  has 561 members because it additionally carries the authenticated manifest;
  there are no other unlisted members.
- XLA: `e58e523b11f1fde802a493a776d158007486e1bf`; pass SHA256
  `1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f`.
- Fresh extraction: `/tmp/census-review-8uw99atq`. It started without `.lake`.
  No live contraction or signed-promotion development was used as v1 evidence.
- Observed Lean: 4.35.0, commit
  `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, x86_64 Linux Release.

`python tools/check_pilot.py` passed all 38 build/audit/positive/negative checks.
It reproduced 71 value laws, 72 support lemmas and 211 audited declarations
across the separately counted groups. Measured custom Lean source is
S622/H772/R643/A26/C236 = **2299 lines**. Category totals, all axiom sets and
separate test/audit line counts equal the immutable originals. The only library
file outside the main LOC categories is `Pilot/Audit.lean`, intentionally
reported separately. All audited dependencies are subsets of the recorded
standard `propext`, `Classical.choice`, `Quot.sound`; 34 declarations have empty
axiom sets. These are kernel checks, not minimality or source-faithfulness proofs.

Sixteen additional archived/native/model integrity tools passed:
`check_native_permutation`, `check_pred_mul_nonfinite`,
`check_empty_slice_replay_evidence`, `check_scalar_select_replay_evidence`,
`check_pred_guard_evidence`, `check_index_map_evidence`,
`check_dynamic_index_evidence`, `check_nested_slice_evidence`,
`check_reshape_evidence`, `check_reduction_evidence`,
`check_dense_layout_evidence`, `check_modular_bridge_evidence`,
`check_modular_arithmetic_evidence`, `check_replacement_api_evidence`,
`check_boolean_control_family_evidence`, `check_control_effect_evidence`
(all `python tools/NAME.py`). These checked archived native results; they did
not rebuild or rerun XLA in this extraction.

Two selected checks could not run completely:

- `check_xla_replay_evidence.py`: missing `reports/xla-replay-v2/result.json`;
  v3 is bundled. This is a packaging defect, detailed below.
- `check_typed_call_evidence.py`: missing `reports/typed-ast-v1/result.json` and
  the external compiler/AST archive. The packet discloses this external boundary.
  I did not independently replay typed Clang extraction from the raw AST.

`python -B -m unittest discover -s tests -v` and the explicit `-p test_tools.py`
variant both exit zero while reporting **Ran 0 tests / NO TESTS RAN**. The Python
suite is absent from the snapshot. Therefore the previously recorded Python
suite result has not been independently reproduced by this review.

## Findings and proposed corrections

### P1 — source acceptance and semantic denominator remain blocked

This is an affirmed open requirement, not a newly discovered false theorem.
`census/review-ledger.json` still has pending handler/candidate records and
`denominator_frozen=false`; all 487 case IDs are overlapping source schemas.
The typed graph and static API paths provide candidate reachability, not
composed branch/alias/effect contracts. For example:

- `algebraic_simplifier.cc:943–949` creates a canonicalized Add through the
  default-false control-relay API; allocation can occur before replacement is
  skipped. A pure commutativity theorem does not describe this outcome.
- `:5575–5650` changes a barrier operand, shape, original-value metadata and
  user tuple indices without replacing the barrier node. Owner-wide links in
  `nonreplacement-effects.json` are not the exact path contract.
- `:11223–11276` executes scalar movement before later convolution helpers;
  accepted obligations must describe that continuing mutation sequence.
- `:8368–8432` mutates nested DynamicSlice and constructs typed clamps/casts/add;
  the mathematical decoded-start theorem alone does not establish finite-width
  or evaluator correspondence.

Correction: retain the existing provisional records, add reviewed caller/path
partitions with API outcome and observation obligations, and record independent
coverage per function and case. Do not derive N from 487, 339 lexical sites,
7391 syntactic calls, 292 typed local edges or 285 API endpoints/boundaries.
No whole-file positive or negative feasibility verdict follows from this packet.

### P1 — graph-context acceptance requires a schedule observation contract

The fixed-schedule effectful theorems are valid for their stated semantics.
They retain preceding effectful producers and compare complete state/error
outcomes for the same program order. They do not quantify over every order that
XLA's data/control graph permits.

The source existing-instruction relay
`dfs_hlo_visitor_with_default.h:384–398` is explicitly true, whereas
`:360–373` gives new-instruction relay a false default. The compatibility helper
`algebraic_simplifier.cc:867–889` rejects control predecessors, not all control
successors. The archived And/Boolean-family witnesses and
`ControlOrderCertificates.lean` show why losing an operand path matters even
when explicit successor edges are relayed. Native actors are retained,
side-effectful and executed synchronously in verified schedules, but these are
mock callbacks, not a production backend execution.

Correction: preserve the diagnostic status and formulate trace-set equality or
appropriate refinement for the adopted effect contract; source correspondence
must include retained actors, scheduling dependencies, failure, metadata and
sharding/frame effects. A fixed-schedule theorem must not discharge that gate.

### P2 — the frozen packet silently permits a zero-test Python validation

The manifest contains `tests/fixtures/*` and `tests/xla/*`, but no
`tests/test_tools.py`. Frozen `tools/checkpoint.py` invokes unittest discovery
and gates its exit code; unittest exits successfully on an empty suite. Thus a
fresh snapshot can appear to pass that step without executing its mutation or
evidence tests. This is a concrete reproducibility hole, independent of whether
the original live suite passed.

Correction: include the Python tests in a new immutable packet version, and
require the expected/nonzero discovered-test count. Preserve v1 and its hashes.
Do not call the v1 fresh extraction's Python checks a successful reproduction.

### P2 — a bundled evidence checker depends on an omitted baseline archive

`tools/check_xla_replay_evidence.py:6–15` unconditionally reads
`reports/xla-replay-v2/result.json`; that directory is absent from the manifest.
`reports/xla-replay-v3/` is included, but the checker fails before reaching it.
This prevents replay of the named offline validation using only this packet.
It does not refute the v3 native result or the necessary-IEEE Lean certificate.

Correction: bundle the small baseline evidence archive in the next packet, or
explicitly split/check the bundled strict archive independently and list the
older baseline as an external dependency. Preserve the original evidence and
record which checks are actually runnable from the packet alone. The typed AST
external dependency is already disclosed and should remain separately scoped.

### P3 — label the handler count as 57 overrides plus one shared helper

There are 58 `Handle*` definitions, but
`HandleAllReduceOrReduceScatter` is a non-override helper. The header declares
all 57 actual visitor handlers with `override`; this shared helper is declared
without it and is called by `HandleAllReduce` / `HandleReduceScatter` at
`:1493–1501`. The structural inventory is useful and includes the helper
correctly; the phrase “58 handlers” obscures this distinction.

Correction: use “58 Handle-prefixed definitions: 57 visitor handlers and one
shared helper,” or report both counts. Do not change semantic N on this basis.

### Advisory — retain legal-attribute and machine-representation adapters

`IndexMaps.BroadcastAxes` proves signed dimension length/range, and the value
laws remain valid even for repeated/unsorted axes. It does not itself encode
all HLO Broadcast legality conditions such as the source's required dimension
ordering/uniqueness. `DenseLiteral.address` likewise supplies an arbitrary total
bounded storage map. This generality is mathematically sound; it leaves concrete
source decoding to a separate adapter. Preserve that distinction in target6/15
correspondence rather than describing range proofs as a complete HLO verifier.
The broad `BitVec width` laws also include widths not present as legal source
primitives and need width/dtype and promotion/narrowing adapters.

## Disposition of the twenty named targets

“Model sound” below means the statement/proof is meaningful within the stated
profile and the kernel replay passed. It never means full source acceptance.
The theorem names/definitions are in frozen `TensorRewrite/Pilot/`; source line
numbers below refer to the pinned simplifier unless another file is named.

| # | Target | Independent disposition and remaining bridge |
| --- | --- | --- |
| 1 | Boolean.and_rhs_false; pure/effectful DAG laws | Model sound for arbitrary finite shapes. `HandleAnd:1503–1546` forwards the actual rhs under IsAll/compatibility; predecessor/producer and schedule effects are separate. Native reversed-order evidence is meaningful under its mock synchronous effect contract, not a source-acceptance theorem. |
| 2 | Boolean/Bitwise.xor_self | Model sound for one tensor used twice. `HandleXor:5472–5505` also accepts distinct `Identical` instructions with side-effect/layout/sharding conditions. That extra subcase is not proved by the pointer-self laws; retain its separate obligation. |
| 3 | Bitwise.and_rhs_zero | Model sound for arbitrary `width`, including overflow-free bitwise operations by construction. Legal integral primitive widths, signed representation, literal IsAll and source graph contracts remain to connect to `HandleAnd`. No floating interpretation is implied. |
| 4 | Subtract.sub_self | Model sound as modular words. `HandleSubtract:2454–2470` requires integral or fast-math and pointer equality. The theorem does not validate exceptional floating subtraction or adopt fast-math's allowed observations. |
| 5 | ModularArithmetic.factor_any_order | Model sound in all four captured shared-factor orientations. `:1072–1100` additionally checks one use for both products and integral/floats-are-real/power-of-two permissions. The word theorem does not discharge floating overflow/rounding permissions or matcher/source bindings. |
| 6 | ModularArithmetic.broadcast_factor_any_order | Model sound for a scalar shared word and a concrete bounded broadcast projection. `:5309–5343` requires the scalar constant and a Broadcast of NonConstant, may broadcast the constant to a nonscalar operand and retains dims. General nonscalar constant factoring is not thereby accepted; legal ordered/unique dimension decoding remains an adapter obligation. |
| 7 | Reverse.reverse_trivial | Model sound when every selected axis has extent one, precisely matching `:7217–7226`. The empty axis list is nonvacuously allowed; a selected zero-extent axis is outside this particular premise, consistent with the source guard. Other empty-tensor identities do not broaden that branch. |
| 8 | Transpose.transpose_comp | Model sound for arbitrary rank and witnessed inverse permutations/extents. The `p.comp q` order matches source `ComposePermutations(operand->dimensions(), transpose->dimensions())` at `:10423–10430`; casts transport bounds. Layout/API/control and actual list decoding remain open. |
| 9 | Reshape.reshapeTensor_identity | Model sound with total logical linearization/inverse, including rank zero and empty outputs. `:6933–6939` checks SameShape and uses existing-instruction replacement with frontend-attribute behavior. Logical value identity does not establish those frame effects. |
| 10 | Reshape.reshapeTensor_compose | Model sound for arbitrary input/intermediate/output ranks with equal mathematical counts. `:6941–6948` uses explicit relay true. Physical layouts, dynamic dimensions, finite shape arithmetic and graph replacement still require correspondence. |
| 11 | Reduction.reduceTensor_empty_input | Model sound; a present output coordinate forces an empty fiber and returns the actual initializer. Empty output equality is appropriately vacuous. Source `HandleReduce` / BroadcastReduce supports tuple cases and context not included by the single-output model. |
| 12 | Reduction.reduceTensor_sameCount | Model sound with the explicit left-identity law. `:9087–9096` relies on the HLO reducer contract; frozen `docs/operation_semantics.md:3859–3865` explicitly requires initializer identity. A merely verifier-accepted nonidentity reducer is not a source counterexample. Arbitrary reduction reassociation is not proved by this ordered fold. |
| 13 | DenseLayout.transpose_eq_bitcast | Model sound for untiled dense same-cell storage and the actual minor-order array equation. The tiled ArraySize outcome is a verifier-policy/direct-handler diagnostic, not a tiled value proof or full-pass/backend claim. Packing, memory spaces and source storage decoding remain separate. |
| 14 | DynamicIndex.sliceTensor_compose | Model sound for arbitrary static ranks and mathematical decoded starts. Source `:8368–8432` includes type-bound checks, casts and finite additions. The nested unsigned evaluator-relative counterexample is kept distinct from this logical law; neither establishes adopted backend behavior. |
| 15 | BooleanDag.and_rhs_true_of_isAll | Model sound: storage uniformity supplies a constant view premise through recognized total bounded reindexing, then graph input mapping preserves shared references/root. The seven wrappers match `UnwrapToConstant:99–117`. Concrete literal storage, legal wrapper attributes and every source graph/API/effect remain review obligations. |
| 16 | Float32Exceptional.false_inf_refutes | Meaningful nonvacuous necessary-IEEE refutation, not a finite multiplication implementation. Original rank-zero index exists, and canonical NaN consistency prevents an inconsistent relation from doing the work. Strict v3 fixture/log are bundled; the combined v2/v3 checker cannot run because v2 is absent. Floating family permissions/backend observations still need adoption. |
| 17 | SliceShape.remove_redundant_stride_refutes and witness | Meaningful shape refutation on legal extent4, declared0, [1:1:2]. `RemoveRedundantStride:7616–7653` changes limit to2/stride1; retained extent0 disagrees. Reverse-helper arithmetic uses truncation toward zero, matching the empty numerator. Native verifier failure and nonempty controls are archived and checked. Formal int64 range/source graph correspondence is still separate. |
| 18 | SelectContraction.nonzero_sum_refutes | Model sound for arbitrary Int lists and either uniform predicate when sum is nonzero. `ScalarMultiplyReduction:673–822` traverses the alternative Select branches, removes both scales and multiplies their constants. Native finite 8/12→24 with disabled-option controls is meaningful. No Lean binary32/convolution/source-traversal correspondence is proved by this mathematical certificate. |
| 19 | DynamicIndex.unsigned64_high_bit_disagrees | Correct distinction between the unsigned decoded value and the modeled observed s64 conversion; small concrete clamping witness is nonvacuous. Native archive supports an evaluator oracle mismatch. This is not independently adopted compiler/backend semantics or a source rewrite defect. |
| 20 | ControlOrder.original_requires_forward / replacement_admits_reverse | Model sound: original prerequisite path forces A before B, replacement admits B before A, and graph/event witnesses exist. Native HloSchedule membership/order checks and retained side-effectful actors support the concrete correspondence. Fixed-schedule theorem validity, newly allowed traces and production ABI behavior must remain distinct. |

## Census review extent and unreviewed work

I checked the enumeration of all 58 Handle-prefixed definitions against the
source/header and inspected source bodies for the 43 functions listed below.
“Body inspected” is a reading-depth statement: called helper contracts, legal
input partitions, frame effects and complete semantic source correspondence
are **not closed**. Fifteen larger bodies were only partially inspected or
screened through ledger/batch references, as marked. No case was promoted.

| Function | Frozen lines | Actual reading depth |
| --- | ---: | --- |
| HandleAbs | 916–924 | Full body read; dependencies/semantic acceptance open |
| HandleAdd | 926–1262 | Partial/ledger screening; incomplete body review |
| HandleAllGather | 1406–1417 | Full body read; dependencies/semantic acceptance open |
| HandleAllToAll | 1419–1430 | Full body read; dependencies/semantic acceptance open |
| HandleAllReduceOrReduceScatter | 1432–1491 | Full body read; dependencies/semantic acceptance open |
| HandleAllReduce | 1493–1496 | Full body read; dependencies/semantic acceptance open |
| HandleReduceScatter | 1498–1501 | Full body read; dependencies/semantic acceptance open |
| HandleAnd | 1503–1546 | Full body read; dependencies/semantic acceptance open |
| HandleBitcast | 1548–1639 | Full body read; dependencies/semantic acceptance open |
| HandleBitcastConvert | 1899–1954 | Full body read; dependencies/semantic acceptance open |
| HandleCopy | 1956–2101 | Partial/ledger screening; incomplete body review |
| HandleConcatenate | 2103–2283 | Partial/ledger screening; incomplete body review |
| HandleConstant | 2407–2452 | Full body read; dependencies/semantic acceptance open |
| HandleSubtract | 2454–2526 | Full body read; dependencies/semantic acceptance open |
| HandleDivide | 2592–2789 | Partial/ledger screening; incomplete body review |
| HandleDot | 4378–4510 | Full body read; dependencies/semantic acceptance open |
| HandleGather | 4634–4858 | Partial/ledger screening; incomplete body review |
| HandleMaximum | 4921–5030 | Full body read; dependencies/semantic acceptance open |
| HandleMinimum | 5032–5099 | Full body read; dependencies/semantic acceptance open |
| HandleClamp | 5101–5136 | Full body read; dependencies/semantic acceptance open |
| HandleMultiply | 5183–5413 | Full body read; dependencies/semantic acceptance open |
| HandleNegate | 5415–5423 | Full body read; dependencies/semantic acceptance open |
| HandleNot | 5425–5434 | Full body read; dependencies/semantic acceptance open |
| HandleOr | 5436–5470 | Full body read; dependencies/semantic acceptance open |
| HandleXor | 5472–5505 | Full body read; dependencies/semantic acceptance open |
| HandleLog | 5507–5556 | Full body read; dependencies/semantic acceptance open |
| HandleGetTupleElement | 5558–5573 | Full body read; dependencies/semantic acceptance open |
| HandleOptimizationBarrier | 5575–5650 | Full body read; dependencies/semantic acceptance open |
| HandleBroadcast | 5770–5905 | Partial/ledger screening; incomplete body review |
| HandleCompare | 5907–6051 | Partial/ledger screening; incomplete body review |
| HandleConvert | 6053–6097 | Full body read; dependencies/semantic acceptance open |
| HandleCustomCall | 6099–6137 | Full body read; dependencies/semantic acceptance open |
| HandleExp | 6139–6147 | Full body read; dependencies/semantic acceptance open |
| HandleComplex | 6150–6158 | Full body read; dependencies/semantic acceptance open |
| HandleReal | 6161–6171 | Full body read; dependencies/semantic acceptance open |
| HandleImag | 6174–6185 | Full body read; dependencies/semantic acceptance open |
| HandleIota | 6187–6196 | Full body read; dependencies/semantic acceptance open |
| HandlePad | 6198–6403 | Partial/ledger screening; incomplete body review |
| HandlePower | 6405–6462 | Full body read; dependencies/semantic acceptance open |
| HandleRemainder | 6614–6704 | Full body read; dependencies/semantic acceptance open |
| HandleReshape | 6911–7198 | Partial/ledger screening; incomplete body review |
| HandleReverse | 7217–7323 | Full body read; dependencies/semantic acceptance open |
| HandleShuffle | 7325–7401 | Full body read; dependencies/semantic acceptance open |
| HandleSlice | 7655–8117 | Partial/ledger screening; incomplete body review |
| HandleRsqrt | 8119–8140 | Full body read; dependencies/semantic acceptance open |
| HandleDynamicSlice | 8142–8433 | Partial/ledger screening; incomplete body review |
| HandleDynamicUpdateSlice | 8435–8732 | Partial/ledger screening; incomplete body review |
| HandleReduce | 9044–9550 | Partial/ledger screening; incomplete body review |
| HandleReducePrecision | 9552–9568 | Full body read; dependencies/semantic acceptance open |
| HandleReduceWindow | 9570–10113 | Partial/ledger screening; incomplete body review |
| HandleSelect | 10115–10235 | Full body read; dependencies/semantic acceptance open |
| HandleScatter | 10237–10258 | Full body read; dependencies/semantic acceptance open |
| HandleSort | 10260–10273 | Full body read; dependencies/semantic acceptance open |
| HandleSqrt | 10275–10303 | Full body read; dependencies/semantic acceptance open |
| HandleTranspose | 10407–10747 | Partial/ledger screening; incomplete body review |
| HandleConvolution | 11223–11276 | Full body read; dependencies/semantic acceptance open |
| HandleMap | 11278–11313 | Full body read; dependencies/semantic acceptance open |
| HandleConditional | 11343–11367 | Full body read; dependencies/semantic acceptance open |

The partial bodies are exactly: HandleAdd, HandleCopy, HandleConcatenate,
HandleDivide, HandleGather, HandleBroadcast, HandleCompare, HandlePad,
HandleReshape, HandleSlice, HandleDynamicSlice, HandleDynamicUpdateSlice,
HandleReduce, HandleReduceWindow, HandleTranspose. Some selected branches in
those bodies were inspected for the twenty targets; that does not close the
remaining branches.

All 103 non-Handle function definitions also remain unclosed as semantic
contracts. Full-body reading included UnwrapToConstant, the IsAll overloads,
IsAllFloat, ScalarMultiplyReduction, BitcastingOperandOfReshapeOrCopyChain,
ReplaceWithBitcast, both ReplaceInstructionIfCompatible overloads,
TryToReorderConvAddMultiply, TryToReorderSliceAndReverse, RemoveRedundantStride
and the RunImpl driver. The exhaustive 103-definition list below gives the exact
remaining closure surface, including already-read helpers; no omission from
this list should be inferred from a shared name or overload.

| Function definition | Frozen line | Closure status |
| --- | ---: | --- |
| `UnwrapToConstant` (`function-3205-3691`) | 99 | Open |
| `IsAll` (`function-3693-3870`) | 119 | Open |
| `IsAllFloat` (`function-3872-4058`) | 124 | Open |
| `IsAll` (`function-4060-4293`) | 129 | Open |
| `IsAnyOperandComplex` (`function-4295-4493`) | 135 | Open |
| `IsPositive` (`function-4495-5782`) | 144 | Open |
| `IsScalarConstant` (`function-5784-5946`) | 186 | Open |
| `GetConstantValue` (`function-5948-6861`) | 191 | Open |
| `IsScalarConstantZero` (`function-6863-7406`) | 213 | Open |
| `IsScalarConstantNegInf` (`function-7408-8266`) | 229 | Open |
| `IsScalarConstantInf` (`function-8268-9119`) | 252 | Open |
| `IsAllFpConstantPowerOf2` (`function-9367-10019`) | 279 | Open |
| `HasMatchDimensionTile` (`function-10021-10294`) | 300 | Open |
| `TransposeIsBitcast` (`function-10440-11125`) | 314 | Open |
| `IsConvertPairNoOp` (`function-11202-11810`) | 332 | Open |
| `SwapOperandsInDotPrecisionConfig` (`function-11812-12064`) | 348 | Open |
| `ValidateTilingOfBitcast` (`function-12185-15454`) | 357 | Open |
| `ConstructToDotMaps` (`function-15833-17263`) | 442 | Open |
| `ConstructFromDotMaps` (`function-17642-18531`) | 482 | Open |
| `DotHasOnlyBatchAndContractingOnOneOperand` (`function-18533-18907`) | 509 | Open |
| `GetReduceFlops` (`function-18960-19298`) | 520 | Open |
| `HasNegativePadding` (`function-19381-19714`) | 530 | Open |
| `IsNonNegative` (`function-19733-22243`) | 540 | Open |
| `ResetState` (`function-22245-22394`) | 609 | Open |
| `Run` (`function-22396-22701`) | 615 | Open |
| `SameShape` (`function-22703-22900`) | 623 | Open |
| `SameShape` (`function-22902-23158`) | 628 | Open |
| `IsOpCodeMultiplyCommutative` (`function-23173-23425`) | 638 | Open |
| `MakeScalarInstruction` (`function-23427-24521`) | 650 | Open |
| `ScalarMultiplyReduction` (`function-24540-29163`) | 673 | Open |
| `BitcastingOperandOfReshapeOrCopyChain` (`function-29165-29922`) | 824 | Open |
| `ReplaceWithBitcast` (`function-29924-30488`) | 844 | Open |
| `ReplaceInstructionIfCompatible` (`function-30649-31473`) | 861 | Open |
| `ReplaceInstructionIfCompatible` (`function-31475-32786`) | 882 | Open |
| `TrySimplifyTautologicalCompare` (`function-48207-50023`) | 1264 | Open |
| `IsInConditionalBranch` (`function-50613-51263`) | 1321 | Open |
| `MatchUniformCollectiveOperand` (`function-51265-52515`) | 1340 | Open |
| `CreateUniformCollectiveReplacement` (`function-52734-54196`) | 1372 | Open |
| `ComputeBitcastDimMap` (`function-63891-67333`) | 1650 | Open |
| `ReshapeLayoutDimensions` (`function-67335-70985`) | 1726 | Open |
| `InvertBitcastDimMap` (`function-70987-71684`) | 1807 | Open |
| `SwapCopyBitcastCopy` (`function-71686-74667`) | 1825 | Open |
| `TrySimplifyTautologicalBitcastConvert` (`function-90277-91349`) | 2285 | Open |
| `TryRemoveUpcastAndDowncastSurroundingBinaryOp` (`function-91351-94795`) | 2314 | Open |
| `BuildTupleConstant` (`function-94797-95536`) | 2391 | Open |
| `InvertConstant` (`function-100332-100544`) | 2529 | Open |
| `TryDivideToShift` (`function-100568-102869`) | 2536 | Open |
| `RemoveDegenerateDimensionFromDot` (`function-112206-115229`) | 2791 | Open |
| `SimplifyTransposeOfBroadcast` (`function-115681-118537`) | 2884 | Open |
| `RemoveTransposesFromDotOperands` (`function-118539-121686`) | 2951 | Open |
| `IsParameterLike` (`function-121834-122076`) | 3029 | Open |
| `MoveDotParamToRhs` (`function-122094-124543`) | 3042 | Open |
| `NormalizeDotOperandToBatchMajorAndContractingMinor` (`function-124545-125495`) | 3094 | Open |
| `AddReduce` (`function-125497-126112`) | 3115 | Open |
| `OptimizeDotOfConcat` (`function-126114-127143`) | 3127 | Open |
| `OptimizeDotOfConcatHelper` (`function-127145-131866`) | 3153 | Open |
| `OptimizeDotOfGather` (`function-131868-137422`) | 3271 | Open |
| `OptimizeDotOfReorderContractingDims` (`function-137886-146452`) | 3410 | Open |
| `AssociativeReorderDotOperator` (`function-146558-157582`) | 3621 | Open |
| `RewriteAsMultiplyDotWithZeroLhsContractingDim` (`function-157584-159757`) | 3883 | Open |
| `AssociativeReorderNestedDot` (`function-159759-173534`) | 3929 | Open |
| `RewriteBatchPlusContractingAsReduce` (`function-173536-177681`) | 4282 | Open |
| `SupportedDotPrecisionConfig` (`function-177683-178009`) | 4365 | Open |
| `MakeMultiplyForPrecisionAlgorithm` (`function-178011-178228`) | 4372 | Open |
| `GetPaddedDims` (`function-183554-184045`) | 4513 | Open |
| `CheckPaddedDimsForGatherOfPad` (`function-184961-188599`) | 4547 | Open |
| `MinMaxToClamp` (`function-199933-202060`) | 4861 | Open |
| `IsNondecreasingSublinear` (`function-202078-202365`) | 4908 | Open |
| `TryToReorderConvAddMultiply` (`function-210984-213156`) | 5138 | Open |
| `ReshapeLeavesDimensionsUnmodified` (`function-231754-232073`) | 5654 | Open |
| `OutputIsPermutationOfOperandElements` (`function-232231-232687`) | 5664 | Open |
| `OutputIsSubsetOfOperandElements` (`function-232837-233398`) | 5681 | Open |
| `IsContiguousChunk` (`function-233564-233923`) | 5703 | Open |
| `FindContiguousChunks` (`function-234533-235735`) | 5731 | Open |
| `TryToSinkBroadcastAfterElementwiseOps` (`function-264669-268206`) | 6464 | Open |
| `TryRemainderToAnd` (`function-268242-270870`) | 6552 | Open |
| `TryRemovingBitcastOrReshapeTransposeChain` (`function-275085-281838`) | 6706 | Open |
| `TryHoistTransposeOfReshape` (`function-281909-283438`) | 6867 | Open |
| `CountElementsLessThan` (`function-295759-296164`) | 7200 | Open |
| `TrySimplifyScalarSlice` (`function-303808-305840`) | 7403 | Open |
| `TryToReorderSliceAndReshape` (`function-305842-310573`) | 7455 | Open |
| `TryToReorderSliceAndReverse` (`function-310672-312995`) | 7572 | Open |
| `RemoveRedundantStride` (`function-312997-314271`) | 7616 | Open |
| `MatchArgMinMax` (`function-361064-362125`) | 8734 | Open |
| `MatchArgMin` (`function-362711-363161`) | 8775 | Open |
| `MatchArgMax` (`function-363747-364200`) | 8803 | Open |
| `ReductionComputationsEquivalent` (`function-364202-365331`) | 8815 | Open |
| `ShouldBroadcastReduce` (`function-365400-365649`) | 8851 | Open |
| `BroadcastReduce` (`function-365651-366573`) | 8857 | Open |
| `ReplaceReduceWithReshape` (`function-366575-367482`) | 8880 | Open |
| `ReorderReduceDotToDotReduce` (`function-367484-372131`) | 8903 | Open |
| `MergeReduces` (`function-372133-373384`) | 9014 | Open |
| `OnlyPermutesDegenerateDims` (`function-428590-429023`) | 10305 | Open |
| `IsPermutationOfIota` (`function-429025-429279`) | 10319 | Open |
| `TryFoldTransposeIntoScatter` (`function-429298-432453`) | 10332 | Open |
| `FoldConvInputPad` (`function-445989-448555`) | 10749 | Open |
| `FoldConvFilterPad` (`function-448557-450936`) | 10818 | Open |
| `SwapConvOperands` (`function-450938-451426`) | 10887 | Open |
| `PromoteConvolutionToF32IfNotOnednnCompatible` (`function-451428-454317`) | 10903 | Open |
| `SimplifyConvToDot` (`function-454319-459640`) | 10981 | Open |
| `SimplifyConvToMultiply` (`function-459642-464665`) | 11102 | Open |
| `RunImpl` (`function-468053-469109`) | 11315 | Open |
| `ShouldStrengthReduceDotToReduce` (`function-470176-471091`) | 11369 | Open |

No provisional case has a completely reviewed source/API/observation closure.
Thus all 487 case IDs remain unaccepted, including theorem-associated cases.
Their exact enumeration follows, grouped by the frozen batch; this is the
unreviewed-to-closure list, not a claim that none received any source reading.

### simple-cases.json — 51 open source cases

- `HandleAnd/lhs-true`
- `HandleAnd/lhs-zero`
- `HandleAnd/rhs-true`
- `HandleAnd/rhs-zero`
- `HandleOr/lhs-true`
- `HandleOr/lhs-zero`
- `HandleOr/rhs-true`
- `HandleOr/rhs-zero`
- `HandleNot/involution`
- `HandleNegate/involution`
- `HandleXor/equal-inputs`
- `HandleXor/lhs-zero`
- `HandleXor/rhs-zero`
- `TrySimplifyTautologicalCompare/Lt-Lt`
- `TrySimplifyTautologicalCompare/Lt-Gt`
- `TrySimplifyTautologicalCompare/Gt-Lt`
- `TrySimplifyTautologicalCompare/Gt-Gt`
- `HandleGetTupleElement/tuple-projection`
- `HandleComplex/components`
- `HandleReal/complex-projection`
- `HandleReal/noncomplex`
- `HandleImag/complex-projection`
- `HandleImag/noncomplex`
- `HandleIota/trivial-axis`
- `HandleExp/zero-scalar`
- `HandleExp/zero-broadcast`
- `HandleSubtract/self`
- `HandleSubtract/zero`
- `HandleSubtract/constant`
- `HandleSubtract/broadcast-constant`
- `HandleSubtract/sub-sub-self`
- `HandleSubtract/sub-add-self-left`
- `HandleSubtract/add-sub-self-left`
- `HandleSubtract/sub-add-self-right`
- `HandleSubtract/add-sub-self-right`
- `HandleMultiply/rhs-one`
- `HandleMultiply/rhs-zero`
- `HandleMultiply/lhs-one`
- `HandleMultiply/lhs-zero`
- `HandleMultiply/negated-operands`
- `HandleMultiply/abs-square`
- `HandleMultiply/predicate-convert`
- `HandleMultiply/four-factors`
- `HandleMultiply/constant-product`
- `HandleMultiply/broadcast-factor`
- `HandleMultiply/legacy-constant-product-direct`
- `HandleMultiply/legacy-constant-product-broadcast-scalars`
- `HandleMultiply/exp-product`
- `HandleMultiply/sqrt-square`
- `HandleMultiply/rsqrt-square`
- `HandleMultiply/conv-reorder-delegation`

### shape-cases.json — 58 open source cases

- `HandleReshape/empty`
- `HandleReshape/identity`
- `HandleReshape/compose`
- `HandleReshape/rng-shape`
- `HandleReverse/trivial-dimensions`
- `HandleReverse/cancel`
- `HandleReverse/symmetric-difference`
- `HandleReverse/binary-scalar-0`
- `HandleReverse/binary-scalar-1`
- `HandleReverse/inserted-unit-dimensions`
- `HandleSlice/identity`
- `HandleSlice/padding-only`
- `HandleSlice/undo-pad`
- `HandleSlice/inside-pad`
- `HandleTranspose/identity`
- `HandleTranspose/compose`
- `HandleReshape/copy-reorder`
- `HandleReshape/broadcast`
- `HandleReshape/iota-mixed-radix`
- `HandleReshape/dynamic-update-unit-dims`
- `HandleReshape/bitcast-chain`
- `HandleReshape/transpose-chain-delegation`
- `HandleReshape/transpose-hoist-delegation`
- `TryRemovingBitcastOrReshapeTransposeChain/layout-identity`
- `TryRemovingBitcastOrReshapeTransposeChain/layout-bitcast`
- `TryRemovingBitcastOrReshapeTransposeChain/logical-identity`
- `TryHoistTransposeOfReshape/contiguous-chunks`
- `HandleSlice/exact-dynamic-update`
- `HandleSlice/inside-dynamic-update`
- `HandleSlice/compose-unstrided`
- `HandleSlice/broadcast-only-dims`
- `HandleSlice/broadcast-sink`
- `HandleSlice/dot-operands`
- `HandleSlice/concat-exact-piece`
- `HandleSlice/concat-subrange-single`
- `HandleSlice/concat-subrange-multi`
- `HandleSlice/reduce-window`
- `HandleSlice/scalar-slice-delegation`
- `HandleSlice/reshape-reorder-delegation`
- `HandleSlice/reverse-reorder-delegation`
- `HandleSlice/stride-delegation`
- `HandleTranspose/dot-canonical`
- `HandleTranspose/dot-general`
- `HandleTranspose/degenerate-reshape`
- `HandleTranspose/rng-shape`
- `HandleTranspose/layout-bitcast`
- `HandleTranspose/space-depth-user-mutation`
- `HandleTranspose/scatter-fold-delegation`
- `HandleTranspose/chain-delegation`
- `HandleTranspose/broadcast-delegation`
- `TrySimplifyScalarSlice/concat-piece`
- `TrySimplifyScalarSlice/concat-slice`
- `TryToReorderSliceAndReshape/leading-slice`
- `TryToReorderSliceAndReverse/commute`
- `RemoveRedundantStride/single-element-axes`
- `TryFoldTransposeIntoScatter/simplified-scatter`
- `SimplifyTransposeOfBroadcast/mapped-dims-logical`
- `SimplifyTransposeOfBroadcast/mapped-dims-layout`

### scalar-control-cases.json — 55 open source cases

- `HandleAbs/nonnegative`
- `HandleClamp/idempotent`
- `HandleClamp/runtime-id`
- `HandleLog/exp`
- `HandleLog/power-real`
- `HandleLog/power-complex`
- `HandleLog/sqrt`
- `HandleLog/rsqrt`
- `HandleConvert/same-type`
- `HandleConvert/noop-pair`
- `HandleConvert/constant-fold`
- `HandleConvert/binary-surround-delegation`
- `HandleCustomCall/dynamic-roundtrip-raw-size`
- `HandleCustomCall/dynamic-roundtrip-clamped-size`
- `HandleCustomCall/layout-identity`
- `HandleCustomCall/layout-copy`
- `HandlePower/zero`
- `HandlePower/one`
- `HandlePower/exp-base`
- `HandlePower/two`
- `HandlePower/three`
- `HandlePower/minus-one`
- `HandlePower/half`
- `HandleRsqrt/inverse-square`
- `HandleRsqrt/reciprocal`
- `HandleReducePrecision/full-width`
- `HandleSelect/equal-values`
- `HandleSelect/true`
- `HandleSelect/false`
- `HandleSelect/not-predicate`
- `HandleSelect/true-false-direct`
- `HandleSelect/true-false-broadcast`
- `HandleSelect/false-true-direct`
- `HandleSelect/false-true-broadcast`
- `HandleSelect/boolean-compare-gt`
- `HandleSelect/boolean-compare-ge`
- `HandleSelect/boolean-compare-lt`
- `HandleSelect/boolean-compare-le`
- `HandleSelect/boolean-compare-eq`
- `HandleSelect/boolean-compare-ne`
- `HandleSelect/update-false-tensor-pred`
- `HandleSelect/update-false-scalar-pred`
- `HandleSelect/update-true-tensor-pred`
- `HandleSelect/update-true-scalar-pred`
- `HandleScatter/empty-updates`
- `HandleScatter/empty-indices`
- `HandleSort/trivial-single`
- `HandleSort/trivial-tuple`
- `HandleSqrt/square-complex`
- `HandleSqrt/square-real`
- `HandleMap/parameter-root`
- `HandleMap/constant-root-scalar`
- `HandleMap/constant-root-broadcast`
- `HandleMap/elementwise-root`
- `HandleConditional/predicate-convert`

### arithmetic-cases.json — 85 open source cases

- `HandleAdd/rhs-zero`
- `HandleAdd/lhs-zero`
- `HandleAdd/constant-right`
- `HandleAdd/constant-sum-direct-constants`
- `HandleAdd/constant-subtract-direct-constants`
- `HandleAdd/constant-sum-broadcast-scalars`
- `HandleAdd/constant-subtract-broadcast-scalars`
- `HandleAdd/cancel-subtract-lhs`
- `HandleAdd/partial-update-lhs`
- `HandleAdd/cancel-subtract-rhs`
- `HandleAdd/partial-update-rhs`
- `HandleAdd/factor-lhs-lhs`
- `HandleAdd/factor-lhs-rhs`
- `HandleAdd/factor-rhs-lhs`
- `HandleAdd/factor-rhs-rhs`
- `HandleAdd/scatter-concat`
- `HandleAdd/scatter-nested`
- `HandleAdd/scatter-single-rhs`
- `HandleAdd/scatter-single-lhs`
- `HandleDivide/one`
- `HandleDivide/power-two-unsigned`
- `HandleDivide/power-two-signed`
- `HandleDivide/exp-pair`
- `HandleDivide/exp-denominator`
- `HandleDivide/power-denominator`
- `HandleDivide/sqrt-denominator`
- `HandleDivide/rsqrt-denominator`
- `HandleDivide/constant-direct`
- `HandleDivide/constant-broadcast`
- `HandleDivide/broadcast-reciprocal`
- `HandleDivide/fractions`
- `HandleDivide/nested-numerator`
- `HandleDivide/nested-denominator`
- `HandleDivide/predicate-scalar-broadcast`
- `HandleMaximum/self`
- `HandleMaximum/lhs-extreme`
- `HandleMaximum/rhs-extreme`
- `HandleMaximum/nested-left-lhs`
- `HandleMaximum/nested-left-rhs`
- `HandleMaximum/nested-right-first`
- `HandleMaximum/nested-right-second`
- `HandleMaximum/clamp-lhs-lhs`
- `HandleMaximum/clamp-lhs-rhs`
- `HandleMaximum/clamp-rhs-lhs`
- `HandleMaximum/clamp-rhs-rhs`
- `HandleMinimum/self`
- `HandleMinimum/lhs-extreme`
- `HandleMinimum/rhs-extreme`
- `HandleMinimum/nested-left-lhs`
- `HandleMinimum/nested-left-rhs`
- `HandleMinimum/nested-right-first`
- `HandleMinimum/nested-right-second`
- `HandleMinimum/clamp-lhs-lhs`
- `HandleMinimum/clamp-lhs-rhs`
- `HandleMinimum/clamp-rhs-lhs`
- `HandleMinimum/clamp-rhs-rhs`
- `HandleMaximum/clamp-lower-lhs`
- `HandleMaximum/clamp-lower-rhs`
- `HandleMaximum/sink-cbrt`
- `HandleMaximum/sink-erf`
- `HandleMaximum/sink-logistic`
- `HandleMaximum/sink-tanh`
- `HandleCompare/unsigned-lt-zero`
- `HandleCompare/unsigned-ge-zero`
- `HandleCompare/unsigned-zero-gt`
- `HandleCompare/unsigned-zero-le`
- `HandleCompare/nonnegative-lt`
- `HandleCompare/nonnegative-gt`
- `HandleCompare/nonnegative-ge`
- `HandleCompare/nonnegative-le`
- `HandleCompare/integral-self-gt`
- `HandleCompare/integral-self-lt`
- `HandleCompare/integral-self-ne`
- `HandleCompare/integral-self-eq`
- `HandleCompare/integral-self-ge`
- `HandleCompare/integral-self-le`
- `HandleCompare/predicate-ne-rhs`
- `HandleCompare/predicate-ne-lhs`
- `HandleCompare/predicate-eq-rhs`
- `HandleCompare/predicate-eq-lhs`
- `HandleCompare/causal-mask`
- `HandleCompare/maximum-first`
- `HandleCompare/maximum-second`
- `HandleCompare/minimum-first`
- `HandleCompare/minimum-second`

### layout-cases.json — 30 open source cases

- `HandleBitcast/unary-sandwich`
- `HandleBitcast/compose-stage`
- `HandleBitcast/compatible-stage`
- `HandleBitcast/recursive-inner`
- `HandleBitcast/chain-delegation`
- `HandleBitcast/broadcast-delegation`
- `HandleBitcastConvert/compose`
- `HandleBitcastConvert/concat-delegation`
- `HandleBitcastConvert/same-physical-shape`
- `HandleBitcastConvert/last-contiguous-axis`
- `HandleBitcastConvert/compatible`
- `HandleCopy/swap-delegation`
- `HandleCopy/compose-identity`
- `HandleCopy/compose-copy`
- `HandleCopy/compatible`
- `HandleCopy/chain-bitcast`
- `HandleCopy/reshape-clone`
- `HandleCopy/reshape-reorder-new-copy-reshape`
- `HandleCopy/reshape-reorder-new-copy-bitcast`
- `HandleCopy/reshape-reorder-omit-copy-reshape`
- `HandleCopy/reshape-reorder-omit-copy-bitcast`
- `SwapCopyBitcastCopy/move-bitcast`
- `SwapCopyBitcastCopy/move-copy`
- `TrySimplifyTautologicalBitcastConvert/concat`
- `HandleConstant/tuple`
- `HandleConstant/uniform`
- `HandleConstant/iota`
- `HandleConstant/strided-iota`
- `HandleOptimizationBarrier/prune-producer`
- `HandleOptimizationBarrier/prune-tuple`

### collective-rotation-cases.json — 17 open source cases

- `HandleAllGather/uniform`
- `HandleAllToAll/uniform`
- `HandleAllReduceOrReduceScatter/min`
- `HandleAllReduceOrReduceScatter/max`
- `HandleAllReduceOrReduceScatter/sum-integral`
- `HandleAllReduceOrReduceScatter/sum-floating`
- `HandleAllReduce/shared-handler`
- `HandleReduceScatter/shared-handler`
- `HandleRemainder/nested`
- `HandleRemainder/power-two-unsigned`
- `HandleRemainder/power-two-signed`
- `HandleRemainder/iota-in-range`
- `HandleRemainder/iota-add-lhs`
- `HandleRemainder/iota-add-rhs`
- `HandleShuffle/rotate-identity`
- `HandleShuffle/rotate-canonical`
- `TryToSinkBroadcastAfterElementwiseOps/eligible-user`

### tensor-index-cases.json — 56 open source cases

- `HandleConcatenate/unary`
- `HandleConcatenate/filter-all-empty`
- `HandleConcatenate/filter-one-nonempty`
- `HandleConcatenate/filter-many-nonempty`
- `HandleConcatenate/flatten`
- `HandleConcatenate/adjacent-slices`
- `HandleConcatenate/pad-low`
- `HandleConcatenate/pad-high`
- `HandleConcatenate/repeat-unit-axis`
- `HandleBroadcast/reshape`
- `HandleBroadcast/transpose`
- `HandleBroadcast/inserted-unit-axes`
- `HandleBroadcast/sink-users-delegation`
- `HandleBroadcast/scalar-user-reshape`
- `HandleBroadcast/scalar-user-reverse`
- `HandleBroadcast/scalar-user-transpose`
- `HandleBroadcast/scalar-user-sort`
- `HandleBroadcast/scalar-user-slice`
- `HandleBroadcast/scalar-user-dynamicslice`
- `HandleBroadcast/iota`
- `HandleBroadcast/compose`
- `HandleBroadcast/drop-unit-axes`
- `HandlePad/empty-input`
- `HandlePad/unit-interior`
- `HandlePad/compatible`
- `HandlePad/broadcast-projection`
- `HandlePad/negative-edges`
- `HandleDynamicSlice/scalar`
- `HandleDynamicSlice/same-shape`
- `HandleDynamicSlice/zero-full-axis-indices`
- `HandleDynamicSlice/broadcast-scalar`
- `HandleDynamicSlice/broadcast-array`
- `HandleDynamicSlice/unit-reshape`
- `HandleDynamicSlice/transpose`
- `HandleDynamicSlice/constant-indices`
- `HandleDynamicSlice/iota-plain-same-type`
- `HandleDynamicSlice/iota-plain-convert`
- `HandleDynamicSlice/iota-scaled-same-type`
- `HandleDynamicSlice/iota-scaled-convert`
- `HandleDynamicSlice/nested`
- `HandleDynamicUpdateSlice/pad-scalar-list`
- `HandleDynamicUpdateSlice/pad-tuple`
- `HandleDynamicUpdateSlice/pad-concatenate`
- `HandleDynamicUpdateSlice/full-update`
- `HandleDynamicUpdateSlice/pad-concat-high`
- `HandleDynamicUpdateSlice/pad-concat-low`
- `HandleDynamicUpdateSlice/zero-full-axis-indices`
- `HandleDynamicUpdateSlice/empty-update`
- `HandleDynamicUpdateSlice/nested`
- `HandleGather/empty-input`
- `HandleGather/effective-scalar-rank-zero`
- `HandleGather/effective-scalar-unit-array`
- `HandleGather/small-select-chain`
- `HandleGather/pad-hoist-passthrough`
- `HandleGather/pad-hoist-batching`
- `HandleGather/reshape-pad-hoist`

### reduction-cases.json — 60 open source cases

- `HandleReduce/empty-delegation`
- `HandleReduce/singleton-tuple`
- `HandleReduce/same-element-count`
- `HandleReduce/negate-sum`
- `HandleReduce/argmin-constant`
- `HandleReduce/argmax-constant`
- `HandleReduce/dot-reorder-delegation`
- `HandleReduce/transpose-sorted`
- `HandleReduce/transpose-permute-result`
- `HandleReduce/merge-delegation`
- `HandleReduce/reshape-reduced-axes`
- `HandleReduce/reshape-output-axes`
- `HandleReduce/concat`
- `HandleReduce/dot-batch-all-batch`
- `HandleReduce/dot-batch-residual-reduce`
- `HandleReduce/reuse-argmax`
- `HandleReduce/reuse-argmin`
- `HandleReduce/scalar-broadcast-maximum`
- `HandleReduce/scalar-broadcast-minimum`
- `HandleReduce/scalar-broadcast-and`
- `HandleReduce/scalar-broadcast-or`
- `HandleReduce/broadcast-base-axes`
- `HandleReduce/broadcast-replicated-axes`
- `BroadcastReduce/tuple`
- `ReplaceReduceWithReshape/tuple`
- `BroadcastReduce/single`
- `ReplaceReduceWithReshape/single`
- `MergeReduces/combined-axes`
- `ReorderReduceDotToDotReduce/profitable`
- `HandleReduceWindow/empty-tuple`
- `HandleReduceWindow/empty-single`
- `HandleReduceWindow/scalar-tuple`
- `HandleReduceWindow/scalar-single`
- `HandleReduceWindow/singleton-tuple`
- `HandleReduceWindow/cumsum-i64-canonicalize-literal`
- `HandleReduceWindow/cumsum-i64-reuse-literal`
- `HandleReduceWindow/cumsum-i32-canonicalize-literal`
- `HandleReduceWindow/cumsum-i32-reuse-literal`
- `HandleReduceWindow/singleton-crop-all-add`
- `HandleReduceWindow/singleton-add-no-pad-no-crop`
- `HandleReduceWindow/singleton-add-no-pad-crop`
- `HandleReduceWindow/singleton-add-pad-no-crop`
- `HandleReduceWindow/singleton-add-pad-crop`
- `HandleReduceWindow/singleton-crop-all-minimum`
- `HandleReduceWindow/singleton-minimum-no-pad-no-crop`
- `HandleReduceWindow/singleton-minimum-no-pad-crop`
- `HandleReduceWindow/singleton-minimum-pad-no-crop`
- `HandleReduceWindow/singleton-minimum-pad-crop`
- `HandleReduceWindow/singleton-crop-all-maximum`
- `HandleReduceWindow/singleton-maximum-no-pad-no-crop`
- `HandleReduceWindow/singleton-maximum-no-pad-crop`
- `HandleReduceWindow/singleton-maximum-pad-no-crop`
- `HandleReduceWindow/singleton-maximum-pad-crop`
- `HandleReduceWindow/full-dimensions`
- `HandleReduceWindow/pad-broadcast-direct-combined`
- `HandleReduceWindow/pad-broadcast-direct-existing`
- `HandleReduceWindow/pad-fold-direct`
- `HandleReduceWindow/pad-broadcast-convert-combined`
- `HandleReduceWindow/pad-broadcast-convert-existing`
- `HandleReduceWindow/pad-fold-convert`

### dot-cases.json — 44 open source cases

- `ReplaceWithBitcast/unary`
- `ReplaceInstructionIfCompatible/single`
- `ReplaceInstructionIfCompatible/span-single`
- `ReplaceInstructionIfCompatible/span-tuple`
- `TryRemoveUpcastAndDowncastSurroundingBinaryOp/add`
- `TryRemoveUpcastAndDowncastSurroundingBinaryOp/subtract`
- `TryRemoveUpcastAndDowncastSurroundingBinaryOp/multiply`
- `TryRemoveUpcastAndDowncastSurroundingBinaryOp/divide`
- `TryRemoveUpcastAndDowncastSurroundingBinaryOp/remainder`
- `RemoveDegenerateDimensionFromDot/direct`
- `RemoveDegenerateDimensionFromDot/reshape-result`
- `RemoveTransposesFromDotOperands/keep-order`
- `RemoveTransposesFromDotOperands/swap`
- `MoveDotParamToRhs/parameter-left`
- `RewriteAsMultiplyDotWithZeroLhsContractingDim/casts-00`
- `RewriteAsMultiplyDotWithZeroLhsContractingDim/casts-01`
- `RewriteAsMultiplyDotWithZeroLhsContractingDim/casts-10`
- `RewriteAsMultiplyDotWithZeroLhsContractingDim/casts-11`
- `AssociativeReorderNestedDot/lhs-transpose`
- `AssociativeReorderNestedDot/lhs-direct`
- `AssociativeReorderNestedDot/rhs-transpose`
- `AssociativeReorderNestedDot/rhs-direct`
- `RewriteBatchPlusContractingAsReduce/no-free-lhs`
- `RewriteBatchPlusContractingAsReduce/no-free-rhs`
- `RewriteBatchPlusContractingAsReduce/no-free-both`
- `HandleDot/empty`
- `HandleDot/outer-product-delegation`
- `HandleDot/nested-delegation`
- `HandleDot/strength-reduce-delegation`
- `HandleDot/degenerate-delegation`
- `HandleDot/transposes-delegation`
- `HandleDot/parameter-swap-delegation`
- `HandleDot/mirror-reverse-lhs-to-rhs`
- `HandleDot/mirror-pad-lhs-to-rhs`
- `HandleDot/mirror-broadcast-lhs-to-rhs`
- `HandleDot/mirror-reverse-rhs-to-lhs`
- `HandleDot/mirror-pad-rhs-to-lhs`
- `HandleDot/mirror-broadcast-rhs-to-lhs`
- `HandleDot/reorder-contracting-lhs`
- `HandleDot/concat-lhs`
- `HandleDot/reorder-contracting-rhs`
- `HandleDot/concat-rhs`
- `HandleDot/dynamic-slice-lhs`
- `HandleDot/dynamic-slice-rhs`

### convolution-cases.json — 31 open source cases

- `ScalarMultiplyReduction/target-lhs`
- `ScalarMultiplyReduction/target-rhs`
- `ScalarMultiplyReduction/target-output`
- `TryToReorderConvAddMultiply/order-lhs-lhs`
- `TryToReorderConvAddMultiply/order-lhs-rhs`
- `TryToReorderConvAddMultiply/order-rhs-lhs`
- `TryToReorderConvAddMultiply/order-rhs-rhs`
- `FoldConvInputPad/compose`
- `FoldConvFilterPad/dilation`
- `PromoteConvolutionToF32IfNotOnednnCompatible/promote-and-continue`
- `SimplifyConvToDot/pointwise-layout`
- `SimplifyConvToMultiply/pointwise-000`
- `SimplifyConvToMultiply/pointwise-001`
- `SimplifyConvToMultiply/pointwise-010`
- `SimplifyConvToMultiply/pointwise-011`
- `SimplifyConvToMultiply/reduce-000`
- `SimplifyConvToMultiply/reduce-001`
- `SimplifyConvToMultiply/reduce-010`
- `SimplifyConvToMultiply/reduce-011`
- `SimplifyConvToMultiply/reduce-100`
- `SimplifyConvToMultiply/reduce-101`
- `SimplifyConvToMultiply/reduce-110`
- `SimplifyConvToMultiply/reduce-111`
- `HandleConvolution/empty`
- `HandleConvolution/scalar-movement-delegation`
- `HandleConvolution/input-pad-delegation`
- `HandleConvolution/filter-pad-delegation`
- `HandleConvolution/operand-swap-delegation`
- `HandleConvolution/onednn-delegation`
- `HandleConvolution/to-dot-delegation`
- `HandleConvolution/to-multiply-delegation`

## Required next evidence before final experimental exit

1. Resolve the packet/test reproduction defects in a new frozen version and
   preserve this review's scope/provenance.
2. Finish independent semantic caller/helper/effect review for the entire
   function/case surface. Derive N/F from actual reviewed obligations, including
   non-replacement mutations and continuing rewrites, rather than syntactic sites.
3. Adopt explicit observation contracts for each numerical/effect/layout family
   and connect source guards/types/attributes/APIs to meaningful Lean statements.
   Reviewed translation is an allowed trust boundary; a fully verified C++
   extractor is not imposed by this review.
4. Extend the diverse reviewed pilot to missing families: complex and advanced
   floating operations/rounding permissions, tuple/variadic reductions and
   windows, dynamic shapes/custom calls, collective participation, random/state
   semantics, backend layout/packing and mutable-IR/frame behavior. For example
   `HandleSqrt:10275–10303` has a complex absolute-value/cast branch that the
   Boolean/word/index proof corpus does not model. Do not mark these families
   out of scope to obtain a whole-file result.
5. Preserve artifact burden in context: 2299 lines is the reproducible current
   development, including semantics/shared support/imports/certificates, not a
   model-independent lower bound on difficulty. Tests/audits and non-Lean source
   review/harness work remain visible separately. Shared code must be charged
   once and attached to every claimed coverage denominator appropriately.

The evidence supports useful automation on the stated logical profiles and
exposes several concrete source/evaluator/graph hazards. It does not yet answer
whether this mixed-agent/Lean workflow sufficiently verifies every rewrite.
A negative result about one rewrite or one strict contract would not establish
that LLMs plus Lean are inherently unable to perform verification; a positive
result requires the missing source and observation closure evidence.
