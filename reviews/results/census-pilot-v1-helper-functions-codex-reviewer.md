# Independent frozen-v1 helper-function census reconciliation

Reviewer: human-authorized separate Codex task `census_pilot_review`; model and
reasoning identifiers remain unknown. Date: 10 November 2026. All four prior
review reports are preserved unchanged. This report writes no source/evidence/
acceptance field and freezes no semantic N/F.

**Scope completed:** actual body reading now covers all 103 non-Handle definition
IDs in the frozen source, including overloads. Forty bodies were newly read or completed
in this turn; sixty-three had been read in the preceding reviews,
with some reread here. Combined with 58 Handle-prefixed bodies, this accounts for
all 161 top-level function-definition records in the source inventory. This is
body-reading coverage and source reconciliation, **not semantic proof closure**.
Every row below retains concrete open type/shape/alias/frame/option obligations.

## Authenticated input and method

Frozen archive SHA256:
`f119335b261a0930a5a2497f5ba3339570d34c5ee6e4baf4a26345cf12b55ce3`;
manifest SHA256:
`da6899931075f018df5d7189c10e8bb87ee4e2560433b2d96e3c1d85f1bdaca4`.
XLA commit `e58e523b11f1fde802a493a776d158007486e1bf`; canonical pass SHA256
`1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f`.
Only extracted `/tmp/census-review-8uw99atq` inputs were inspected. All frozen
source-file hashes were rechecked. All103 helper byte intervals independently
match their full-call inventory body SHA256 values. Later parent-reported native
runs/certificates were not inspected or adopted as evidence in this report.

The table uses the exact IDs/lines in `census/full-call-inventory.json`, plus all
80 selected direct local call edges whose caller is one of these 103 IDs from
`census/typed-call-inventory.json`. Dependency cells deduplicate declarations and
show name@line to distinguish overloads; exact source-call IDs and multiplicities
remain in that frozen edge list. “None selected” does not mean no external,
header, implicit, macro or virtual calls. `replacement-api-paths.json` retains
the broader unmatched/external boundaries; this table is not a closed call graph.

Read status **new** means body reading completed in this turn (including completing
an earlier partial inspection);
**prior** means full body read in earlier frozen-v1 review (possibly reread).
All rows are semantically OPEN. No unread body remains in this103-definition
surface; all 103 remain on the semantic-closure remainder list. The first report's
body-depth remainder is therefore superseded by the cumulative reading record,
while its acceptance-blocking gaps and later explicit corrections remain.

No new Lean/XLA run is claimed. The first review's independent 2299-line/71-law
proof replay and each supplement's source-only witness calculations retain their
own scope. Nonexecuted candidates below are not confirmed compiler defects.

## Priority source facts and remaining hazards

### P1 unexecuted candidate: deleting Broadcast contraction axes assumes an order

In AssociativeReorderDotOperator, Broadcast movement iterates contracting pairs
at3798–3807 and calls
`new_broadcast_shape.DeleteDimension(from_index - deleted_dims)` for each
introduced contracting axis. The arithmetic assumes earlier deletions were of
lower-numbered axes. The inspected Dot legality validator
`shape_inference.cc:820–866` checks range and uniqueness, not increasing order;
paired extent/count checks follow. `shape.h:253–257` explicitly requires valid
DeleteDimension indices. No local sortedness/remapping check was found here.

Concrete source-path candidate: lhs=Broadcast(s32 scalar)->s32[2,3], rhs=s32[2,3],
Dot with both contracting lists={1,0}, no batch/free axes, associative reordering
enabled. The first removal requests axis1; the next requests axis-1. This occurs
before the final flop-cost threshold, so a rejected final profitability guard
cannot justify the index operation. The preceding nested-Dot helper returns
kNoRewrite when neither input is Dot; the no-contract branch does not apply.
Legal pipeline/source profiles and an actual verifier/pass run still need checking.

Relevant provisional IDs are HandleDot/mirror-broadcast-lhs-to-rhs and
HandleDot/mirror-broadcast-rhs-to-lhs. Their generic finite arithmetic dependency
does not establish this ordered-deletion invariant. Preserve actual source
behavior; add contraction-list order/remap partitions and a bounded legal-HLO
native diagnostic with ascending-list controls before any defect verdict.
A sorted client-level Broadcast mapping does not imply sorted Dot contraction
lists; do not conflate the two after the earlier Broadcast advisory correction.

### P2 unexecuted role hazard: equal map values do not identify their origin

AssociativeReorderNestedDot iterates `{map_inner_lhs, map_inner_rhs}` at3992,
then chooses target dimension-number objects using `map == map_inner_lhs` at
4000/4003. That is vector VALUE equality. If the two maps coincide (for example,
a batch-only inner Dot), the second iteration is classified as the lhs map too.
A body/source proof must either show this cannot reach the branch under the
complete caller gates, prove the duplicate classification irrelevant, or expose
it as an additional case. No such invariant was found in the local code.

This is a source-inspected ambiguity requiring a concrete native witness, not a
confirmed invalid graph or value change. Candidate construction must control
no-contract/strength-reduction rewrites, options, dimensions and the cost gate;
no failing example was executed here. Record origin roles explicitly in any
source-to-model adapter rather than replacing this test by pointer identity.

### Continuing mutation and flag/status meanings are function-specific

- PromoteConvolutionToF32IfNotOnednnCompatible returns TRUE without rewriting for
  a supported CPU BF16 case. For an incompatible one, it constructs F32 inputs/
  Conv/back-convert, replaces the old Conv, writes the new F32 Conv through the
  caller pointer, and returns FALSE (:10903–10979). HandleConvolution continues
  on that new pointer. False is not a “no effect” outcome here.
- Run (:615–621) resets state then CHECK_OKs computation.Accept; it does not
  return visitor errors as Status. Its options/simplifier parameters are unused;
  constructor-owned members still govern behavior. RunImpl reuses that visitor
  across module computations and has a changed-driven cap, not a convergence proof.
- The header-defined GetOrCreateScalarAddComputation (:424–442) caches by type
  and adds an embedded computation to the current module on a miss. ResetState
  does not clear that cache. Within RunImpl the parent module is shared; broader
  public visitor reuse must establish cache/module lifetime compatibility.
- Pointer-returning OptimizeDot helpers usually return constructed candidates,
  leaving replacement to HandleDot. Null can follow prefix allocation in cost-
  rejected paths. ReorderReduceDotToDotReduce's optional Status is tested only for
  engagement by its caller, as already documented in frozen v1. A single generic
  “true=rewrite / false=no mutation / OK=unchanged” summary would be false.
- Opcode classifiers such as IsOpCodeMultiplyCommutative and
  IsNondecreasingSublinear supply source policy, not proven algebra/range lemmas.
  In particular Select classification does not prove branch scale multiplication
  valid, and shape traversal alone does not prove comparator or RNG effects pure.

### Numerical/representation and shape/index contracts remain independent

No-contract Dot normalization converts both operands to the result type before
Multiply and propagates derived metadata. Contracting strength reduction may
promote products to F32/F64 before AddReduce, then narrow. The base
MakeMultiplyForPrecisionAlgorithm body simply invokes Multiply; precision policy
accepts two algorithm tags and ignores has_contracting_dim. These facts must be
matched to the adopted accumulator/finish/rounding semantics, not a blanket
real-number or evaluator-only equality.

TryRemoveUpcastAndDowncastSurroundingBinaryOp has concrete same-signedness,
non-subbyte integral and value-preserving-cast gates and excludes signed
Divide/Remainder. TryDivideToShift/TryRemainderToAnd need modular signed-minimum
reasoning. InvertConstant uses host native reciprocal arithmetic. Bitcast,
convolution conversion, collective scalar arithmetic and static count/flop
products likewise need actual widths, conversion and source-domain contracts.

Physical layout/packing/memory spaces, callbacks/backend overrides, collective
participation, conditional callers, scalar-add module caches, original-value
metadata, sharding and partial allocations are observable only according to an
explicit adopted contract. Pure tensor laws or successful scalar replays do not
by themselves discharge these remaining frames.

## Exact per-function inventory and semantic remainder

All line ranges below refer to the pinned algebraic_simplifier.cc. Every row is
OPEN semantically. Dependencies are selected static local declarations, not
proved execution paths. The remaining-obligation cell records concrete local
facts/preconditions and the missing correspondence, including API/alias/frame
issues where applicable.

| Function ID / name | Lines | Actual reading | Role | Direct selected local dependencies | Concrete remaining semantic/source obligations |
| --- | ---: | --- | --- | --- | --- |
| `function-3205-3691` / `UnwrapToConstant` | 99–117 | prior; open | matcher/query | None selected | Seven recognized operand0 wrappers; legal bounded value maps, termination and literal/storage correspondence remain. |
| `function-3693-3870` / `IsAll` | 119–122 | prior; open | literal matcher | `UnwrapToConstant@99` | Unwrap and literal.IsAll; overload value type, empty storage, wrapper attributes and source literal semantics remain. |
| `function-3872-4058` / `IsAllFloat` | 124–127 | prior; open | literal matcher | `UnwrapToConstant@99` | Float-valued recognition; host float comparison/rounding, wrappers and exceptional values remain. |
| `function-4060-4293` / `IsAll` | 129–133 | prior; open | literal matcher | `UnwrapToConstant@99` | Scalar-literal overload CHECKs rank0 then unwrap/literal.IsAll; source scalar type, empty/wrapper/storage and API caller domain remain. |
| `function-4295-4493` / `IsAnyOperandComplex` | 135–142 | prior; open | type query | None selected | Checks operands, not a generic numeric semantic guarantee; legal opcode/type contracts remain. |
| `function-4495-5782` / `IsPositive` | 144–184 | prior; open | value-range policy | `IsAnyOperandComplex@135`, `IsPositive@144` | Recursive roles and batchnorm custom-call/GTE target contract; exclude NaN/domain counterexamples per caller. |
| `function-5784-5946` / `IsScalarConstant` | 186–189 | prior; open | literal matcher | None selected | Constant opcode plus effective scalar; distinguish rank0, all-unit and empty shapes. |
| `function-5948-6861` / `GetConstantValue` | 191–211 | prior; open | literal decoding | `IsScalarConstant@186` | Floating native-to-double or integral native-to-int64-to-double; exactness, unsigned high bits and reachable callers remain. |
| `function-6863-7406` / `IsScalarConstantZero` | 213–227 | new; open | literal matcher | `IsScalarConstant@186` | Native typed equality to0 after effective-scalar test; signed-zero/NaN/type profiles remain. |
| `function-7408-8266` / `IsScalarConstantNegInf` | 229–250 | new; open | literal matcher | `IsScalarConstant@186` | Infinity or finite lowest for types lacking infinity; decoder/type/reducer-domain correspondence remains. |
| `function-8268-9119` / `IsScalarConstantInf` | 252–273 | prior; open | literal matcher | `IsScalarConstant@186` | Infinity or finite max for types lacking infinity; decoder/type/reducer-domain correspondence remains. |
| `function-9367-10019` / `IsAllFpConstantPowerOf2` | 279–298 | prior; open | value-range matcher | `GetConstantValue@191` | Constant/broadcast effective scalar and frexp mantissa ±0.5; native decoding and floating permissions remain. |
| `function-10021-10294` / `HasMatchDimensionTile` | 300–310 | prior; open | layout analysis | None selected | Any tile contains MatchDimension sentinel; adopted tiling representation/invariants remain. |
| `function-10440-11125` / `TransposeIsBitcast` | 314–329 | prior; open | layout analysis | `HasMatchDimensionTile@300` | External bitcast predicate plus selected tile/ArraySize equation; storage/packing/memory and overflow profiles remain. |
| `function-11202-11810` / `IsConvertPairNoOp` | 332–346 | new; open | type matcher | None selected | Source=destination and CastPreservesValues through intermediate; full primitive cast semantics remain. |
| `function-11812-12064` / `SwapOperandsInDotPrecisionConfig` | 348–353 | prior; open | metadata construction | None selected | CHECK exactly2 operand-precision entries before swap; legal config and algorithm semantics remain. |
| `function-12185-15454` / `ValidateTilingOfBitcast` | 357–435 | prior; open | layout analysis | None selected | Empty tile list shortcut, first-tile split/combine tests; all-tile coverage, divisors, map bounds and layout semantics remain. |
| `function-15833-17263` / `ConstructToDotMaps` | 442–475 | prior; open | index analysis | None selected | Batch prefix then lhs/rhs free axes; legal unique paired axis lists and total inverse-map proof remain. |
| `function-17642-18531` / `ConstructFromDotMaps` | 482–507 | prior; open | index analysis | `ConstructToDotMaps@442` | Invert selected maps with -1 sentinels; coverage, indices, batch overlap and role invariants remain. |
| `function-18533-18907` / `DotHasOnlyBatchAndContractingOnOneOperand` | 509–517 | prior; open | shape predicate | None selected | Compares listed-axis counts with supplied ranks; caller TrueNumDimensions versus actual rank must be preserved. |
| `function-18960-19298` / `GetReduceFlops` | 520–527 | new; open | cost arithmetic | None selected | Product of reduced extents and output-count*(product-1); finite bounds, empty domains and cost-only effects remain. |
| `function-19381-19714` / `HasNegativePadding` | 530–536 | prior; open | attribute predicate | None selected | Checks negative low/high edges only; interior and runtime padding semantics remain separate. |
| `function-19733-22243` / `IsNonNegative` | 540–607 | prior; open | value-range policy | `IsAnyOperandComplex@135`, `IsPositive@144`, `GetConstantValue@191`, `IsNonNegative@540` | Constructor recognition may include NaN; caller-required ordered comparison/domain postconditions remain, as prior supplement. |
| `function-22245-22394` / `ResetState` | 609–613 | new; open | visitor driver | None selected | Resets visitation, changed flag and computation pointer; persistent scalar-add cache is not cleared here. |
| `function-22396-22701` / `Run` | 615–621 | new; open | visitor driver | `ResetState@609` | Uses constructor-owned state, resets and CHECK_OKs Accept; unused passed options/simplifier are not new configuration, abort/visit contracts remain. |
| `function-22703-22900` / `SameShape` | 623–626 | prior; open | shape analysis | `SameShape@628` | Instruction overload delegates to shape overload; exact type/dynamic/layout profile and caller object lifetime remain. |
| `function-22902-23158` / `SameShape` | 628–634 | prior; open | shape analysis | None selected | Instruction overload delegates; shape overload chooses Equal versus Compatible by layout mode, including dtype/dynamic/storage details. |
| `function-23173-23425` / `IsOpCodeMultiplyCommutative` | 638–648 | new; open | opcode policy | None selected | Labels Multiply/Transpose/Reshape/Select; this is not a proof scalar hoisting across branches/shared uses is sound. |
| `function-23427-24521` / `MakeScalarInstruction` | 650–669 | new; open | literal construction | None selected | Casts host float into dispatched native type, fatal unsupported type; reachable target BF16/F32 and exception/rounding domain remain. |
| `function-24540-29163` / `ScalarMultiplyReduction` | 673–822 | prior; open | delegated rewrite | `GetConstantValue@191`, `IsOpCodeMultiplyCommutative@638`, `MakeScalarInstruction@650` | Mutates multiple operand/user edges, aggregates float scales and inserts at selected target; branch/shared-use/path-count and status frames remain. |
| `function-29165-29922` / `BitcastingOperandOfReshapeOrCopyChain` | 824–842 | prior; open | layout/query | None selected | Walk chain until virtual bitcast relation; termination, storage equivalence, layouts and returned-node lifetime remain. |
| `function-29924-30488` / `ReplaceWithBitcast` | 844–856 | prior; open | replacement API | None selected | ByteSize CHECK, optional default operand, allocate Bitcast then CHECK_OK replacement; allocation/control/metadata/error outcomes remain. |
| `function-30649-31473` / `ReplaceInstructionIfCompatible` | 861–880 | prior; open | replacement API | `SameShape@623` | Reject control predecessors and require shapes, then sharding-preserving relay; span overload tuple construction/count/types also need closure. |
| `function-31475-32786` / `ReplaceInstructionIfCompatible` | 882–914 | prior; open | replacement API | `SameShape@628`, `ReplaceInstructionIfCompatible@861` | Span overload: reject predecessors, singleton delegate or matched tuple shapes, then MaybeMakeTuple before relay replacement; allocation, typing, coupled outputs and status/frame remain. |
| `function-48207-50023` / `TrySimplifyTautologicalCompare` | 1264–1306 | new; open | delegated rewrite | None selected | Effective-scalar S32 LT/GT bounds on identical variable, min bound; ordering, typed constants and new-node API frame remain. |
| `function-50613-51263` / `IsInConditionalBranch` | 1321–1338 | new; open | caller-context analysis | None selected | Visited worklist follows all callers to Conditional; complete caller graph, recursion and collective participation contract remain. |
| `function-51265-52515` / `MatchUniformCollectiveOperand` | 1340–1367 | new; open | collective matcher | `IsInConditionalBranch@1321` | Single array/control-free/nonasync/nonconditional, host guard, uniform literal forms; replica participation and literal/layout profiles remain. |
| `function-52734-54196` / `CreateUniformCollectiveReplacement` | 1372–1402 | new; open | construction | None selected | Scalar default-memory constant versus reused/new scalar Broadcast; layout callback and allocation-before-replacement frame remain. |
| `function-63891-67333` / `ComputeBitcastDimMap` | 1650–1724 | prior; open | layout/index analysis | None selected | Physical dimension-product matching; finite products, zero/one extents, map bounds and unsupported repartition outcomes remain. |
| `function-67335-70985` / `ReshapeLayoutDimensions` | 1726–1805 | prior; open | layout construction | None selected | Build local minor-order layout, reject bad grouping; completeness, contiguity, sentinel/degenerate and index invariants remain. |
| `function-70987-71684` / `InvertBitcastDimMap` | 1807–1823 | prior; open | layout/index analysis | None selected | Invert groups while walking physical order; grouped-axis legality, duplicates and index bounds remain. |
| `function-71686-74667` / `SwapCopyBitcastCopy` | 1825–1897 | prior; open | delegated rewrite | `ValidateTilingOfBitcast@357`, `ComputeBitcastDimMap@1650`, `ReshapeLayoutDimensions@1726`, `InvertBitcastDimMap@1807` | Host exclusions, two ordered tiling/layout branches and inner allocations before CHECK replacement; backend/frame semantics remain. |
| `function-90277-91349` / `TrySimplifyTautologicalBitcastConvert` | 2285–2312 | new; open | delegated rewrite | None selected | Strip matching inner casts around Concat; rank/axis/bit-width preservation and creation/status/frame proof remain. |
| `function-91351-94795` / `TryRemoveUpcastAndDowncastSurroundingBinaryOp` | 2314–2389 | new; open | delegated rewrite | None selected | Same signedness non-subbyte integral narrowing; unsigned-only divide/remainder, value-preserving upcast and one-user guards need word/source proof. |
| `function-94797-95536` / `BuildTupleConstant` | 2391–2405 | new; open | recursive construction | `BuildTupleConstant@2391` | Recursive tuple/literal-node allocation; nested token/storage/shape/layout and partial-allocation observations remain. |
| `function-100332-100544` / `InvertConstant` | 2529–2533 | prior; open | literal construction | None selected | Populate host NativeT reciprocal at every literal cell; rounding/nonfinite/complex semantics and status remain. |
| `function-100568-102869` / `TryDivideToShift` | 2536–2589 | prior; open | replacement construction | None selected | Integral caller dispatch, positive signed power2 or unsigned single bit; modular minimum-value behavior and intermediate allocations remain. |
| `function-112206-115229` / `RemoveDegenerateDimensionFromDot` | 2791–2871 | new; open | delegated rewrite | None selected | Drop extent1 operand axes, remap dnums, direct replacement or explicit-relay reshape; shape/cast/precision/API proof remains. |
| `function-115681-118537` / `SimplifyTransposeOfBroadcast` | 2884–2949 | prior; open | delegated rewrite | None selected | Sorted old/remapped dims and optional extracted layout order; true operation/verifier profile and user/API semantics remain. |
| `function-118539-121686` / `RemoveTransposesFromDotOperands` | 2951–3024 | new; open | delegated rewrite | `SwapOperandsInDotPrecisionConfig@348` | Matched equal permutations, canonical axes, optional operand/precision swap, new Dot+Transpose; map and numerical/frame proofs remain. |
| `function-121834-122076` / `IsParameterLike` | 3029–3039 | prior; open | policy classifier | None selected | Follows any one-operand chain to Parameter; no inherent purity/trivial-op guarantee, cycles/context policy remain. |
| `function-122094-124543` / `MoveDotParamToRhs` | 3042–3092 | new; open | delegated rewrite | `IsParameterLike@3029` | Policy swap, dnums/precision update, free-block transpose and derived metadata; numeric/config/list bounds and API frame remain. |
| `function-124545-125495` / `NormalizeDotOperandToBatchMajorAndContractingMinor` | 3094–3113 | new; open | index construction | None selected | Batch/free/contract permutation, sorted shortcut; legal disjoint complete lists, shape/dynamic and transpose creation remain. |
| `function-125497-126112` / `AddReduce` | 3115–3125 | new; open | module/reduction construction | None selected | Zero+cached scalar-add computation and Reduce insertion; correct accumulation type, cache/module lifetime, identity and frame remain. |
| `function-126114-127143` / `OptimizeDotOfConcat` | 3127–3151 | new; open | candidate construction | `OptimizeDotOfConcatHelper@3153` | 2D/no-batch/one-contract gate, lhs-first helper then swapped rhs; source role/cost/typing/API integration remain. |
| `function-127145-131866` / `OptimizeDotOfConcatHelper` | 3153–3269 | new; open | candidate construction | None selected | Slice constant by cumulative sub-K, Dot pieces and ordered Add chain; count/range/zero operands, contraction and finite/reassociation proof remain. |
| `function-131868-137422` / `OptimizeDotOfGather` | 3271–3399 | new; open | candidate construction | None selected | Actually DynamicSlice(Constant), not general Gather; paired full contracting extent, memoized Dot and start remap need clamp/type/geometry proof. |
| `function-137886-146452` / `OptimizeDotOfReorderContractingDims` | 3410–3617 | new; open | candidate construction | None selected | Virtual lhs/rhs swap then contracting-only transpose/reshape motion; saved original dnums, map intervals, casts/numerics and allocation frames remain. |
| `function-146558-157582` / `AssociativeReorderDotOperator` | 3621–3881 | new; open | candidate construction | `IsScalarConstantZero@213` | Lhs-first Reverse/Pad/Broadcast mirroring; contraction-list deletion order candidate, full axis remap, cost allocations and numeric permissions remain. |
| `function-157584-159757` / `RewriteAsMultiplyDotWithZeroLhsContractingDim` | 3883–3927 | new; open | delegated rewrite | `NormalizeDotOperandToBatchMajorAndContractingMinor@3094` | Normalize, convert inputs to result type, broadcast, Multiply and derived metadata; initialized accumulation/finish identity, precision and API proof remain. |
| `function-159759-173534` / `AssociativeReorderNestedDot` | 3929–4280 | new; open | delegated rewrite | `ConstructToDotMaps@442`, `ConstructFromDotMaps@482` | NoRewrite/StopRewrites/Rewritten, recovered pairwise maps and cost gate; equal-map origin role hazard, type/precision/reassociation/permutation/frame remain. |
| `function-173536-177681` / `RewriteBatchPlusContractingAsReduce` | 4282–4363 | new; open | delegated rewrite | `NormalizeDotOperandToBatchMajorAndContractingMinor@3094`, `AddReduce@3115`, `MakeMultiplyForPrecisionAlgorithm@4372` | Normalize/cast/broadcast/product then promoted AddReduce/narrow; geometry, zero/accumulator/precision/rounding and cache/API remain. |
| `function-177683-178009` / `SupportedDotPrecisionConfig` | 4365–4370 | new; open | precision policy | None selected | Accepts ALG_UNSET or ALG_DOT_F32_F32_F32; has_contracting_dim unused, so do not invent a branch-specific algorithm check. |
| `function-178011-178228` / `MakeMultiplyForPrecisionAlgorithm` | 4372–4376 | new; open | construction hook | None selected | Base body ignores Dot argument and calls MakeBinaryHlo Multiply; no complete algorithm-emulation claim, override/type/frame contracts remain. |
| `function-183554-184045` / `GetPaddedDims` | 4513–4524 | prior; open | attribute analysis | None selected | Collect low/high/interior nonzero axes; negative/dynamic/runtime padding and rank/list invariants remain. |
| `function-184961-188599` / `CheckPaddedDimsForGatherOfPad` | 4547–4630 | prior; open | matcher/map construction | `GetPaddedDims@4513` | Pass-through or matched batching pad, then extend maps; external mapping contract and legal config/index bounds remain. |
| `function-199933-202060` / `MinMaxToClamp` | 4861–4905 | new; open | candidate construction | None selected | Scalarize bounds, evaluate temporary lower<upper, return Clamp/null; evaluator/NaN/type/status correspondence and graph frame remain. |
| `function-202078-202365` / `IsNondecreasingSublinear` | 4908–4919 | new; open | opcode policy | None selected | Classifies Cbrt/Erf/Logistic/Tanh only; actual finite/NaN/rounding monotonic/sublinear postcondition remains unproved. |
| `function-210984-213156` / `TryToReorderConvAddMultiply` | 5138–5181 | prior; open | delegated rewrite | None selected | Move feature scale to constant filter and bias with one-user and axis checks; geometry/grouping/numeric/source-frame remain. |
| `function-231754-232073` / `ReshapeLeavesDimensionsUnmodified` | 5654–5659 | prior; open | shape analysis | None selected | External shape-map query after Reshape CHECK; legal dimension arrays and mapping proof remain. |
| `function-232231-232687` / `OutputIsPermutationOfOperandElements` | 5664–5677 | prior; open | opcode policy | None selected | Reshape/Reverse/Transpose/single-output Sort classifier; source typing, values, effects and dynamic observations remain. |
| `function-232837-233398` / `OutputIsSubsetOfOperandElements` | 5681–5698 | prior; open | opcode policy | None selected | Require one occurrence of operand and data position0 for Slice/DS; legal bounds/empty/dynamic and effect contracts remain. |
| `function-233564-233923` / `IsContiguousChunk` | 5703–5712 | prior; open | index predicate | None selected | Consecutive transpose entries in selected interval; checked bounds and permutation legality remain. |
| `function-234533-235735` / `FindContiguousChunks` | 5731–5766 | prior; open | shape/index analysis | `IsContiguousChunk@5703` | CommonFactors plus collapsible contiguous chunks; factor partition, zero/one extents, sorted chunk roles and bounds remain. |
| `function-264669-268206` / `TryToSinkBroadcastAfterElementwiseOps` | 6464–6548 | prior; open | delegated rewrite | None selected | Multiple qualifying users, reduced operands/new user/Broadcast and ReplaceAllUsesWith; prefix-error/state and effect/frame contracts remain. |
| `function-268242-270870` / `TryRemainderToAnd` | 6552–6611 | new; open | replacement construction | None selected | Integral power2 denominator, signed modular sign/mask/restoration or unsigned mask; minimum values and intermediate/API frame remain. |
| `function-275085-281838` / `TryRemovingBitcastOrReshapeTransposeChain` | 6706–6864 | prior; open | delegated rewrite | None selected | At-most-one unit-axis effective permutations; layout-sensitive direct/bitcast versus insensitive forwarding, relay and index/range proof remain. |
| `function-281909-283438` / `TryHoistTransposeOfReshape` | 6867–6909 | prior; open | delegated rewrite | `FindContiguousChunks@5731` | Chunk factorization/sort, new inner Reshape+Transpose; interval/permutation proof, arithmetic and allocation/API frame remain. |
| `function-295759-296164` / `CountElementsLessThan` | 7200–7215 | new; open | index query | None selected | Binary search assumes sorted list; empty-span signed/unsigned size conversion, count bounds and caller ordering remain. |
| `function-303808-305840` / `TrySimplifyScalarSlice` | 7403–7453 | prior; open | delegated rewrite | `ReplaceInstructionIfCompatible@861` | Effective-scalar rank1 Concat selection then compatible forwarding or new Slice; prefix/range/status and fallback/API proof remain. |
| `function-305842-310573` / `TryToReorderSliceAndReshape` | 7455–7568 | prior; open | delegated rewrite | None selected | Aligned dimension0 decomposition; per-loop nonzero divisor candidate, counts/offsets and normal-pass reachability remain. |
| `function-310672-312995` / `TryToReorderSliceAndReverse` | 7572–7614 | prior; open | delegated rewrite | None selected | Update reversed Slice bounds using truncating division; empty witness, finite signed arithmetic, shape and API remain. |
| `function-312997-314271` / `RemoveRedundantStride` | 7616–7653 | prior; open | delegated rewrite | None selected | Select redundant-stride axes and change limit/stride; empty-shape refutation/correspondence and nonempty/range/API profiles remain. |
| `function-361064-362125` / `MatchArgMinMax` | 8734–8757 | prior; open | reducer matcher | None selected | Four explicit parameter roles, compare/NaN/tie pattern; comparison order, index semantics and coupled tuple domain remain. |
| `function-362711-363161` / `MatchArgMin` | 8775–8785 | prior; open | reducer matcher | `IsScalarConstantZero@213`, `IsScalarConstantInf@252`, `MatchArgMinMax@8734` | Reduce4 operands, tuple, Iota, +Inf/zero then shared pattern; dtype/index range/domain and users remain. |
| `function-363747-364200` / `MatchArgMax` | 8803–8813 | prior; open | reducer matcher | `IsScalarConstantZero@213`, `IsScalarConstantNegInf@229`, `MatchArgMinMax@8734` | Reduce4 operands, tuple, Iota, -Inf/zero then shared pattern; dtype/index range/domain and users remain. |
| `function-364202-365331` / `ReductionComputationsEquivalent` | 8815–8848 | prior; open | reducer matcher | None selected | Same computation or two-parameter Add/Mul/And/Or role roots; typed reducer meaning, allowed reassociation and identity remain. |
| `function-365400-365649` / `ShouldBroadcastReduce` | 8851–8855 | prior; open | shape predicate | None selected | Input or representative result zero count; coupled-output shape assumptions and initializer-domain bridge remain. |
| `function-365651-366573` / `BroadcastReduce` | 8857–8878 | prior; open | replacement construction | None selected | Per-output initializer Broadcast, tuple or single API; typed shape/layout, identity/empty interpretation and frames remain. |
| `function-366575-367482` / `ReplaceReduceWithReshape` | 8880–8901 | prior; open | replacement construction | None selected | Per-input Reshape, tuple or single API, ignoring reducer locally; actual identity/count and layout/frame proof remain. |
| `function-367484-372131` / `ReorderReduceDotToDotReduce` | 8903–9012 | prior; open | candidate/replacement | `IsScalarConstantZero@213`, `ConstructFromDotMaps@482`, `GetReduceFlops@520` | Construct reductions/Dot before cost gate; optional Status engagement discards contained error at caller, numeric/range/frame remain. |
| `function-372133-373384` / `MergeReduces` | 9014–9042 | prior; open | delegated rewrite | None selected | Sort local dimension copies, lift outer axes and merge; equivalent reducer/init, count/order/reassociation and API proof remain. |
| `function-428590-429023` / `OnlyPermutesDegenerateDims` | 10305–10317 | prior; open | permutation predicate | None selected | Drop extent1 output slots then sorted-sequence test; legal bijection/shape and zero/dynamic interpretation remain. |
| `function-429025-429279` / `IsPermutationOfIota` | 10319–10328 | prior; open | permutation predicate | None selected | Sort a copy and require entries0..n-1; span bounds and caller axis role contract remain. |
| `function-429298-432453` / `TryFoldTransposeIntoScatter` | 10332–10405 | prior; open | delegated rewrite | None selected | Simplified single Scatter/no batching/write-run guard; base/update transpose and inverse dims, external classifier and effect/API remain. |
| `function-445989-448555` / `FoldConvInputPad` | 10749–10816 | prior; open | delegated rewrite | `HasNegativePadding@530` | Option/zero scalar/batch-feature and nonnegative padding guards; dilation/edge arithmetic, Conv geometry/numerics and API remain. |
| `function-448557-450936` / `FoldConvFilterPad` | 10818–10885 | new; open | delegated rewrite | `IsAll@119` | Zero fill, feature no-pad, spatial interior-only and no repeated dilation; window size/reversal/type/geometry/API remain. |
| `function-450938-451426` / `SwapConvOperands` | 10887–10901 | new; open | delegated callback rewrite | None selected | Option+layout guard, external beneficial-swap callback with ConvIsLowerable; actual effects, backend and changed/status contract remain. |
| `function-451428-454317` / `PromoteConvolutionToF32IfNotOnednnCompatible` | 10903–10979 | new; open | continuing pointer rewrite | None selected | True can mean no rewrite; incompatible CPU BF16 rewrites and updates caller pointer then false; continuing numeric/frame proof remains. |
| `function-454319-459640` / `SimplifyConvToDot` | 10981–11100 | new; open | delegated rewrite | None selected | Enable option AND layout-sensitive gate despite comment, strict layouts/1x1/no groups; bitcasts/storage/precision/overflow/API remain. |
| `function-459642-464665` / `SimplifyConvToMultiply` | 11102–11221 | new; open | delegated rewrite | None selected | Layout-insensitive+nonsparse, not gated by enable_conv_simplification; reversal/casts/BroadcastSequence/optional Reduce and geometry/numerics remain. |
| `function-468053-469109` / `RunImpl` | 11315–11341 | prior; open | pass driver | `Run@615` | One visitor across module computations, changed-driven rerun cap50; all pass outcomes, cache scope, visitation, termination and warnings remain. |
| `function-470176-471091` / `ShouldStrengthReduceDotToReduce` | 11369–11393 | new; open | backend policy | None selected | CPU requires BOTH operands only batch/contract; nonCPU returns true, caller guards and backend/type contracts remain. |

## Exit interpretation and next evidence

The full 161-definition source body-reading milestone is complete. It does not
establish a semantic denominator or complete source correspondence. In addition
to the two helper hazards above, retain the earlier source-only findings and
subsequently verified evidence in their own independently authenticated versions.
Do not retroactively label the frozen-v1 review as having executed later probes.

Resolve/reproduce concrete candidates, compose caller/guard/type/option paths,
review every nonreplacement effect and external/virtual/header contract, adopt
numerical/layout/effect observations and connect them to the actual Lean
statements. Final source acceptance still needs accountable reviewed translation
or checked correspondence under the agreed experiment; a verified whole-C++
extractor is not added as a new requirement here. The present report supplies
an exact helper work surface and source facts, not positive or negative final
feasibility evidence for the entire LLM/Lean workflow.
