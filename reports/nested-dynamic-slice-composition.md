# Nested DynamicSlice: logical proof and evaluator-relative value changes

Source: XLA e58e523b11f1fde802a493a776d158007486e1bf,
algebraic_simplifier.cc:8379–8433. Case: HandleDynamicSlice/nested.
Contract and source-body hash: census/nested-slice-contract.json.

## Source obligation

The handler transforms DS(DS(x,inner),outer) into a DS of x at the sum of
independently clamped inner and outer starts. It skips async computations and
reaches this branch after earlier returns. Before mutation it checks that each
input-minus-intermediate extent fits the inner index type and each
input-minus-output extent fits the outer index type. It then changes the data
operand, constructs typed HLO Clamp operations, converts the inner clamped start
if the index types differ, adds in the outer type and replaces each index.
The source map retains both data and per-index mutation sites.

The outer sum is bounded by input-minus-output extent mathematically. That
explains the second representability guard: it bounds the converted nonnegative
inner value and the final sum. A Lean integer proof alone does not establish
the source's finite-word conversion, comparison and addition correspondence.

## General logical proof

DynamicSliceTensor.lean defines tensor values using the already checked concrete
DynamicSlice coordinate map. combinedStart adds the two independently clamped
starts. DynamicSliceCompositionLemmas.lean proves that this sum lies between zero
and input-minus-output extent, so reclamping it has no effect. It then proves
equality of nested and combined coordinate maps for arbitrary finite rank,
bounded static extents and mathematical decoded starts.

DynamicSliceComposition.lean lifts the map equality to equality of tensor values
for arbitrary element type. Extent-zero cases are retained: no output coordinate
exists on an empty axis. Scalar rank is also unrestricted. The intermediate
extent fits the input, and the output fits the intermediate; these are visible
conditions, not supplied conclusions about the resulting map.

This proves one mathematical-track rule with three shared support theorems.
It does not prove graph mutation, metadata/frame observations, dynamic shape
legality, layout admission or C++ finite-word correspondence. Those conditions
remain visible in the source-review ledger; accepted source proof is still null.

## Native evaluator-preservation experiment

Following the preceding unsigned-index oracle diagnostic, a new exact-source
full-pass replay uses a nonuniform s32[10] input, an inner slice of size6 and an
outer slice of size2. Both starts are parameters, so constant-index conversion
cannot intercept the nested branch. Neither slice has a full-extent axis.
Layout sensitivity is enabled, the pass runs once, and the evaluator fast path
is disabled explicitly. Rewritten roots must be DynamicSlice of the input
parameter with an Add index. All original and rewritten modules verify.

| Input profile | First coordinate before | After the pass |
| --- | ---: | ---: |
| u64 inner=2^63, outer=1 | 1 | 5 |
| u64 inner=1, outer=2^63 | 1 | 5 |
| both u64 starts=2^63 | 0 | 8 |
| both u64 starts=2^63−1 | 8 | 8 |
| s32 inner=−99, outer=99 | 4 | 4 |
| inner u64=2^63, outer s32=1 | 1 | 5 |
| inner s32=−99, outer u64=2^63 | 0 | 4 |
| both u32 starts=2^32−1 | 8 | 8 |

Every case also checks the second selected coordinate. Eight no-pass controls
preserve the original HLO and values. Thus five of eight rewritten inputs show
a value change under the observed evaluator; three rewritten controls agree.
This is one native test with16 executions, not16 source obligations.

The evaluator decodes original DynamicSlice u64 starts through signed conversion.
The inserted HLO Clamp compares u64 values as unsigned. Its bounded outputs
and their sum then fit signed64, so the rewritten DynamicSlice no longer sees
the original negative conversion result. The mathematical signedness-preserving
unsigned composition would select the upper coordinates both before and after.

This is a reproducible failure of preservation under the observed evaluator
profile. It is not sufficient evidence that the rewrite violates an independently
adopted unsigned backend contract: that contract is still open. A theorem about
logical unsigned composition and an evaluator-relative refutation can therefore
coexist without contradiction. Do not turn this observation into either a
whole-source correctness claim or a production backend bug claim.

Archive: reports/nested-slice-replay-v2/result.json, including source pin,
fixture, BUILD, uncached Bazel command/events/logs/XML and binary hash.
The earlier v1 archive preserves a failed build: the fixture initially requested
the protobuf source target instead of the C++ target. That infrastructure issue
was repaired before any native evidence was accepted. Reproduce with
tools/run_nested_slice_replay.py and an unused nested-slice-replay-vN name.

## Evaluator-relative Lean certificates and integrity controls

NestedUnsigned64.lean models the concrete10→6→2 profile separately from the
general tensor semantics. The original profile uses the observed signed
conversion; the rewritten profile uses unsigned clamps, word addition via
BitVec.ofInt and final signed decoding/clamping. Four certificates establish
the first three native differences and refute universal preservation in this
explicit profile. They depend on standard propext through BitVec.ofInt's bound
proof, with no added axioms. Earlier empty-axiom certificates retain their gate.
The mixed-type examples currently have native evidence only.

These four certificates have their own evaluator-relative count, separate from
the existing rewrite-related refutation and pure index-interpretation counts.
The logical composition theorem also has a separate count, so value-rule totals
are not silently reinterpreted as source coverage.

The checker validates exact source/profile identities, all pass/no-pass outcomes,
archive hashes, successful native test events and agreement of actual Lean
probes with the three u64 witnesses. Controls reject source-acceptance promotion,
an all-backends interpretation, missing no-pass cases and altered Lean outputs.
An invalid proof dropping inner clamping must fail. The integrated checkpoint
and37 tool/evidence tests pass; earlier theorem axiom sets are unchanged.

| Lean category | Previous | Current | Added |
| --- | ---: | ---: | ---: |
| S semantics | 333 | 358 | 25 |
| H support | 277 | 323 | 46 |
| R rule proofs | 276 | 292 | 16 |
| A imports/checking | 17 | 19 | 2 |
| C certificates | 156 | 177 | 21 |
| Total | 1059 | 1169 | 110 |

Audit/test source is reported separately in reports/pilot-values.json. A complete
snapshot is preserved in snapshots/nested-slice-pilot-v1.zip; fresh replay in
reports/nested-slice-clean-replay.json checks size, axiom dependencies and index
probes without a Lean build cache. This is same-agent Lean replay, not independent
source review or native rebuilding. The diverse reviewed pilot, semantic census,
whole-file campaign and final verdict remain unfinished.
