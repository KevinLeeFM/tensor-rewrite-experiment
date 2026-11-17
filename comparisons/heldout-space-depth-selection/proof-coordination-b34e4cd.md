# Frozen rewrite proof coordination

Starting checkout: `b34e4cd8022ae7d1fdae50e2bb3a4df6f744eddc`; start 2026-11-17 06:08:20 UTC. Both existing freezes, `GoalCandidate.Goal`, model assumptions and semantics remain immutable. The outer-rank condition is a model restriction; no C++ correspondence or speedup is claimed.

## Exact residual and ownership

For arbitrary `rank`, `outerRank`, `shape`, `inner`, `outer`, `plan : Conditions shape inner outer`, element type `α`, `input : Tensor shape α`, and `out : Index outer`, prove:

```
Heldout.IndexTransportAttempt.originalIndex plan out =
  Heldout.IndexTransportAttempt.replacementIndex plan input out
```

Both sides are actual `Index shape`; `tail-index-failed.lean.txt` and `tail-index-failure.log` show the residual after extensionality and unfolding. The existing `original_read`, `replacement_read`, and `read_equal_of_index_equal` reduce the exact goal to this equality; they do not supply it. `TailHeadConnection` establishes the first tail extents and replacement quotient/remainder, while `outer_packed_parts_equal` establishes equal outer packed values. What remains is the arbitrary-prefix and remaining-tail coordinate relation: establish actual derived prefix/suffix shapes and index equality, align count/moved coordinate factors under the actual permutation and split reshape, and transport all other coordinates through the actual frame casts. Zero domains are handled without inventing indices.

One fresh Luna proof worker owns new files with prefix `WorkerIndex` and any explicitly named `worker-index-*` logs/receipts under this comparison directory. It may use existing proved facts but must not edit existing files, either freeze, general library modules, or the frozen goal. It must preserve compiler failures, check local helper axioms, name the exact residual, and report wall/active effort and meaningful progress. The coordinator owns this plan, integration, independent review and replay; no second worker is active unless a separable obligation is identified. No recursion, downloads, broad builds, or unreviewed terminal theorem acceptance.

## Disjoint suffix worker

At the proof worker's request, a second Luna worker owns new files prefixed `WorkerSuffix` and `worker-suffix-*`: prove only the actual extents after the first two axes of the original cut tail equal the extents after the first axis of the replacement cut tail, for every valid suffix axis and arbitrary `Conditions`. These are source-specific facts outside the generic library, with no assumed target equality. The main worker will not duplicate this obligation. The suffix worker must preserve failures, compile offline, report axioms and edge coverage, and send its exact interface; it does not integrate the main theorem or spawn agents.
