# Concrete static Broadcast and Slice index maps

Source pin: XLA e58e523b11f1fde802a493a776d158007486e1bf.
Scope: bounded static shapes and mathematical signed attributes/arithmetic.
Data: census/concrete-index-contract.json; complete source acceptance remains0.

## Source contracts selected

ShapeVerifier::HandleBroadcast in hlo_verifier.cc:1741–1762 checks an array axis
per operand dimension, signed axis range, equal element type and exact matching
input/output extents at those axes. InstructionVerifier additionally checks
dimension ordering when its option requests it. HLO Broadcast is not the
client-level broadcasting helper: ShapeInference::InferBroadcastShape also has
a size-one expansion rule that is not this HLO verifier contract. The model uses
the HLO exact-extent condition and does not infer an expansion permission from
the client helper.

ShapeInference::InferSliceShape in shape_inference.cc:3424–3497 checks matching
attribute lengths/rank, nonnegative start, ordered start/limit, positive stride
and a limit bounded by each static input extent. It computes the output count as
(limit-start+stride-1)/stride. The source explicitly relaxes the limit check for
unbounded dynamic dimensions. This work covers the static contract; it must not
be promoted to that dynamic case.

The source ranges/hashes are recorded in the contract file and backed by the
already pinned indexing manifests. No compiler implementation is changed.

## General proofs and constructed maps

SliceIndexBounds.lean proves that for every legal static axis, every nonnegative
index below the declared output extent gives a coordinate start+stride*index
between zero and the input extent. It derives the result from IsWellFormed and
the truncating-division count; it does not accept the desired coordinate bound
as an extra premise. The proof works for arbitrary positive stride. When the
declared extent is zero, there is no output coordinate requiring an address.

IndexMaps.lean implements a signed Broadcast axis array with its length and range
validated before Int.toNat decoding. broadcastIndex projects each selected
output coordinate using the exact extent equality; introduced output axes are
ignored. It does not silently turn a negative attribute into axis zero.
Additional source ordering/legality requirements remain part of source validation,
not claims proved merely by bounded projection.

sliceIndex computes the signed start/stride formula on every axis, invokes the
general bound theorem and only then converts the result into a bounded natural
coordinate. Input/output rank and every axis's shape/count validity are explicit.
The function accepts no caller-supplied output-to-input map. broadcastView and
sliceView build the earlier recognized constant-guard views using these concrete
maps rather than arbitrary supplied functions.

IndexMapLemmas.lean proves exact projected Broadcast coordinates, exact signed
Slice coordinates, and constant-tensor conclusions for both concrete views.
These conclusions reuse the guard proof for arbitrary finite rank/extents.
The maps are logical; no physical storage layout or backend memory calculation
has been verified by constructing them.

## Why nonuniform differential evidence matters

The earlier true-literal native tests could not detect an incorrect index map:
every in-bounds coordinate would return true. New tests evaluate nonuniform
coordinate labels in the pinned XLA evaluator and compare them with evaluated
Lean map probes. The model examples additionally have kernel-checked equalities;
the probes are diagnostics, not unchecked proof evaluation.

| Case | Independent native observation | Lean observation |
| --- | --- | --- |
| Broadcast [2,3] to [2,4,3], axes0,2 | All24 output values checked; selected label5 | Selected label5 |
| Slice [6,7] with [1:6:2],[2:7:3] | All6 labels9,12,23,26,37,40 | Same six labels |
| Empty Slice [1:1:2] of [4] | Zero elements | Declared count0 |
| Stride larger than interval [1:3:5] | Selected label1 | Selected label1 |

The Broadcast native test checks every output coordinate of its concrete shape;
the Lean general coordinate theorem covers arbitrary shapes. The six Slice
labels expose stride and offset mistakes. Empty Slice evaluation remains valid
here because no simplifier rewrite is run; the earlier empty-slice pass failures
are distinct evidence about transformations of that legal input.

Native archive: reports/index-map-evaluator-v1/result.json. It contains verified
HLO evaluation through HloEvaluator and explicitly records no simplifier handler
and no full pass execution. The archive preserves fixture, BUILD, uncached Bazel
command/events/logs/XML, binary hash and source pin. Reproduce with
tools/run_index_map_evaluator.py and an unused index-map-evaluator-vN archive.
The offline checker tools/check_index_map_evidence.py compares the archived
native labels with actual Lean probe output in reports/pilot-values.json.
The integrated checkpoint refreshes that output before evidence comparisons.

## Boundaries and remaining evidence

The concrete maps remove two previously supplied-map interfaces. They do not
verify C++ parsing/attribute extraction, signed-int64 operations, physical layout,
literal addressing or arbitrary dynamic extents. In particular the source's
count numerator uses finite signed arithmetic; the mathematical proof does not
establish absence of overflow in its C++ computation on every source input.
Other wrapper maps and source matcher/replacement API/frame contracts remain open.

Lean controls include negative Broadcast axes, wrong empty output count, zero
stride, large stride and the nonuniform coordinates. An invalid proof that drops
the stride factor must fail with exactly its expected rfl error. Evidence controls
reject altered model coordinates, a false full-pass claim and promotion of the
static mathematical profile to all dynamic/machine arithmetic.

All35 tool/evidence tests and the integrated checkpoint pass. All prior axiom
sets are preserved. Five new support theorems bring the support total to24; value
rules remain41, graph-context rules12 and guard bridges1. They overlap source
cases and are not a disjoint source-coverage numerator.

| Lean category | Previous | Current | Added |
| --- | ---: | ---: | ---: |
| S semantics | 265 | 302 | 37 |
| H support | 175 | 232 | 57 |
| R rule proofs | 276 | 276 | 0 |
| A imports/checking | 14 | 15 | 1 |
| C certificates | 133 | 133 | 0 |
| Total | 863 | 958 | 95 |

snapshots/static-index-maps-pilot-v1.zip preserves the complete Lean pilot.
reports/static-index-maps-clean-replay.json records a fresh-directory build
without .lake and matching size, axiom and evaluated coordinate outputs. This
is same-agent Lean replay, not independent review or native rebuild.

Complete source acceptance remains0. The diverse reviewed pilot and the complete
census/campaign/final audit are unfinished. Continue concrete typed semantics and
source correspondence across remaining indexing, layout, reduction, numerical
and effectful cases before drawing the requested whole-workload verdict.
