# Independent coordinate bridge review

Reviewed checkpoint: `408866f07dece14eb4abd2dd95a21d280284857e`. Reviewer: fresh gpt-6-luna, no further agents; approximately 3 minutes including replay. Assessment: **accept as a generic prerequisite**, subject to the limitations below; no tensor rewrite has been proved or accepted.

The reviewer inspected the exact statements, candidate imports and frozen goal and found the bridge generic over its declared frame, axis, sizes, element type and input. All 28 frozen input hashes matched. A fresh offline Lean 4.35.0 build compiled the full 25-module dependency closure, including the three candidate modules, into a new temporary directory. Candidate axiom reports were limited to `propext`, `Classical.choice`, and `Quot.sound`; no `sorryAx` appeared. The reviewer also reran the frozen goal replay, including both recorded expected-failure controls. Its generated `goal-replay.json` was restored after replay. No review-time file changes remained.

The candidate demonstrates coordinate decomposition and reassembly and connects a valid concatenation position to its enumerated source slice. The tests cover first/last positions, a block boundary, one block, both zero factors and a wrong quotient/remainder result. Zero-factor domains have no valid positions. The arithmetic tests do not exercise full tensor indices with unrelated zero extents; the frozen goal controls cover those examples. The bridge does not prove equality of the original and replacement input indices.

The smallest remaining obligation is to show, for each admitted output index, that the input index read through outer reshape, transpose and inner reshape equals the input index selected by the replacement's chunk and local coordinates. It requires dependent transport across intermediate and output frames; existing linearize/delinearize inverses may help. No proof attempt of that obligation was made in this review.

`outerRankAtLeast` remains an explicit model restriction, not an established source invariant. C++–Lean correspondence is an assumption; no speedup claim follows.
