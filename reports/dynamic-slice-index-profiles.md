# DynamicSlice bounds and distinct index interpretations

Source pin: XLA e58e523b11f1fde802a493a776d158007486e1bf.
Contract: census/dynamic-index-contract.json. Complete source acceptance remains0.

## Mathematical map and proof scope

DynamicIndexValue.lean decodes signed words through BitVec.toInt and unsigned
words through BitVec.toNat. clampStart computes min(max(0,start),extent-width)
over mathematical integers. DynamicIndexBounds.lean proves its bounds whenever
width≤extent, then proves that adding any valid output coordinate stays inside
the input extent. DynamicIndex.lean uses those proofs to construct an arbitrary-
rank bounded DynamicSlice map and a concrete recognized constant-guard view.
No caller supplies the desired coordinate bound or an arbitrary reindexing map.

Six new support theorems include the coordinate formula, constant-view result,
full-extent clamping to zero for every start, and agreement of same-width signed
and unsigned decoding when the sign bit is clear. That last theorem does not
describe widening u32 to s64: the native conversion retains every u32 value.
Zero output widths are allowed by the bounded model; they have no output index.
The construction covers static bounded extents, including runtime start values;
it does not cover unbounded dynamic dimensions or physical memory addressing.

## Why the native oracle needs a profile

The pinned evaluator's GetS64Indices (hlo_evaluator.cc:1263–1289) converts each
integral index with static_cast<int64_t>. HandleDynamicSlice (:3712–3768) then
clamps that signed result before adding output coordinates. Shape inference
(shape_inference.cc:3500–3622) admits integral index types and checks slice sizes
against bounded extents, with a separate unbounded-dimension case. Hashes and
exact inspected ranges are preserved in the contract and source manifest.

On the observed native host, u64 values with the high bit set become negative
through this conversion. Thus the evaluator's indexing and a signedness-
preserving logical interpretation need separate profiles. This is an observed
evaluator boundary, not a demonstrated algebraic-simplifier rewrite failure or
a conclusion about every production backend. The C++ conversion correspondence
has not been proved in Lean.

The current [StableHLO DynamicSlice specification](https://openxla.org/stablehlo/spec#dynamic_slice)
also describes clamping integer start values and permits zero slice sizes.
It is a comparison reference checked on10 November2026, not an adopted normative
specification for the pinned XLA revision. The older pinned operation-semantics
prose and the implementation's admitted inputs need explicit reconciliation
before selecting a source/backend contract.

## Differential evidence and diagnostic certificates

The native fixture verifies and evaluates20 HLO inputs with nonuniform operand
labels0–4 and output width2. Cases cover negative, ordinary and extreme s32/s64
starts and ordinary/extreme u32/u64 starts. Eighteen cases agree with logical
clamping. Two u64 cases disagree:

| Start | Logical first coordinate | Native first coordinate |
| --- | ---: | ---: |
| 2^63 | 3 | 0 |
| 2^64−1 | 3 | 0 |

Each native output also checks its second label. Archive
reports/dynamic-index-evaluator-v1 preserves the exact fixture, BUILD, uncached
Bazel test command, events, logs, XML, source pin and binary hash. This is one
native test with20 input cases. It executes the operator evaluator, with no
simplifier handler or full pass. Reproduce using tools/run_dynamic_index_evaluator.py
and an unused dynamic-index-evaluator-vN archive name.

UnsignedIndexBoundary.lean contains three kernel-checked certificates: the two
concrete interpretation disagreements and refutation of universal equality of
those interpretations. Their axiom dependencies are empty. They are counted
as diagnostic certificates, separately from the existing17 rewrite-related
refutation theorems. They do not prove native execution or establish a new
source-rewrite counterexample.

tools/check_dynamic_index_evidence.py compares native labels with actual Lean
probe output for all five profiles. Controls reject erasing the disagreements,
substituting signed decoding for logical u64, a false full-pass claim, and source
acceptance promotion. A false Lean equality for the high-bit case must fail.
The integrated checkpoint refreshes the Lean report before evidence comparisons.
All36 Python/tool tests and the integrated checkpoint pass. Earlier theorem
axiom sets are preserved.

## Code burden and remaining obligations

| Lean category | Previous | Current | Added |
| --- | ---: | ---: | ---: |
| S semantics | 302 | 333 | 31 |
| H support | 232 | 277 | 45 |
| R rule proofs | 276 | 276 | 0 |
| A imports/checking | 15 | 17 | 2 |
| C certificates | 133 | 156 | 23 |
| Total | 958 | 1059 | 101 |

The total includes shared definitions/proofs and all certificates; audit/test
sources are reported separately in reports/pilot-values.json. There are now30
support theorems,41 value identities,12 overlapping graph-context rules and one
guard bridge. None is a disjoint whole-source coverage numerator.

snapshots/dynamic-index-pilot-v1.zip preserves the complete Lean development.
reports/dynamic-index-clean-replay.json records its fresh-directory replay
without cached builds, with matching size, axiom dependencies and index probes.
This is same-agent Lean replay, not independent review or a new native build.

Keep logical unsigned semantics and the evaluator conversion distinct while
reviewing source/backend contracts. Remaining obligations include finite C++
conversion and arithmetic, attribute extraction, storage/layout, graph/API/frame
observations and independent semantic/source review. Accepted source rewrites
remain0; the semantic census, diverse reviewed pilot, whole-file campaign and
final research verdict remain open.
