# Shape/indexing extraction and graph-replacement dependencies

Revision: e58e523b11f1fde802a493a776d158007486e1bf.
The 27 schemas in census/shape-cases.json are an inspected partial batch. Their
branch anchors and handler-body hashes are validated against preserved source.
The whole-file census remains open; no Lean proof has been accepted.

## Semantic obligations exposed

- Reshape-to-empty needs the literal/default-layout path as well as empty-domain
  value equality. Reshape composition needs arbitrary-rank linearization. The
  RNG reshape case mutates the producer shape and depends on state/distribution
  behavior; a pure tensor-function proof cannot cover that case alone.
- Nested reverse composes by symmetric difference and sorts axis lists in place.
  Its outer layout-insensitive guard is material. Reverse through a binary
  operation excludes compare, fusion and side effects and requires a scalar
  broadcast. Reverse through inserted unit axes needs an explicit rank-changing
  index map, not a fixed-rank enumeration.
- Slice/pad includes distinct padding-only, undo-pad and inside-pad outcomes.
  The early-break path must be respected. Output-shape assignments are explicit
  graph mutations. The no-op slice case relies on slice legality in addition
  to matching shapes; the source does not separately assert zero starts.
- A sorted legal transpose permutation is identity. Nested transpose preserves
  the exact ComposePermutations order. Earlier scatter-folding behavior remains
  a separate source path, not covered by the two extracted transpose schemas.

## Implementation-level replacement trace

Additional immutable sources: hlo_computation.cc, hlo_instruction.cc and
shape_util.cc; see sources/dependency-supplement.json for URLs/hashes.
This extends evidence preservation, not the complete transitive build closure.

In xla/hlo/ir/hlo_computation.cc:2039–2170:

- ReplaceWithNewInstruction first adds the new instruction and delegates.
- ReplaceInstruction checks ShapeUtil::Compatible and delegates to
  ReplaceInstructionWithDifferentShape. Shape mismatch is an error, not a proof
  that the requested rewrite was mathematically invalid.
- Preserving sharding can cause a false/no-change outcome when both instructions
  carry incompatible sharding. Control dependencies are copied/dropped when
  relay is enabled; otherwise their presence can prevent replacement.
- Metadata propagation is conditional. Frontend attributes are copied only when
  requested, the destination has none, and the destination is not an existing
  operand of the replaced instruction. The Boolean compatibility helper's
  preserve flag does not imply unconditional attribute equality.

The remaining implementation calls (control-dependency copying, use replacement,
dead-operand removal, identity comparison and shape utility implementations)
still require semantic review. These observations describe source behavior;
they are not correctness theorems for graph mutation.

## Remaining reshape branches and shared layout helpers

The expanded batch now includes copy/reshape reordering, broadcast dimension
remapping, mixed-radix iota expansion, unit-axis movement through dynamic updates
and the final bitcast-chain selection. Copy reordering carries hardware-bitcast,
host-memory exclusion, alignment and allocation-size heuristics; those heuristics
must not be silently erased from a source-faithful statement. The iota case
requires checking CommonFactors boundaries and finite-width multiplier products.

Reshape's delegated transpose-chain paths are linked to records for three helper
outcomes: exact shape/layout equality forwarding, layout-preserving bitcast, and
shape equality ignoring layout. The implementation at :6707–6862 has explicit
layout-sensitive handling, despite the introductory comment saying layout is
ignored. Use the code's branches. Its unit-axis bounds apply explicitly to
reshape/bitcast validators; do not infer an untested universal restriction on
all transpose nodes from the comment.

The hoisting helper at :6867–6908 constructs new dimensions and a permutation
from sorted chunks. FindContiguousChunks, bitcast layout predicates and the
arithmetic helper invariants remain unresolved dependencies. The census still
needs precise site-to-case maps and independent reconciliation; helper records
do not turn delegated placeholders into closed verification obligations.
