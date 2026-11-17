# Actual merged-head attempt

Bounded attempt from base `ba77199f41fc6d12a238deac4245c23f219323be` to instantiate
`merged_head_of_tail_packing` on actual plan tails. Focused effort was about 5 minutes,
including two targeted fresh offline closure runs (each approximately 10 seconds elapsed
before the final dependent modules). No source outside `ActualMergedHead.lean` and
`actual-merged-*` replay/log files was edited. No theorem was proved or accepted.

The first attempt showed that the direct `preIndex` application cannot consume
`tailIndex (cutIndex ...)`: its type is `Index (tailShape (cutShape ...))`, while
the generic theorem needs an index of a separately rank-cast shape `Shape (k+2)`.
The ranks `k+2 = rank+1-m` and `k+1 = rank-m` are propositionally equal, not
definitionally equal. The candidate therefore began explicitly defining those
casted shapes and indices. That is the right bridge direction, but the attempt did
not establish all dependent transports.

The remaining obligation is concrete: prove the casted tail index is well typed in
the casted tail shape, identify the head and suffix extents of their generic
`preShape`/`tailShape` with the actual tails, and carry
`actual_tail_packed_values_equal` across those same casts. Only then can
`tail_extents_merge` and `WorkerSuffix.suffix_extents` discharge the conditional
helper's count premises. This pass did not get a compiled actual-plan equation or
run the requested equation-specific nonempty, one-chunk, zero-extent and empty
controls. The existing generic helper and its prior controls remain independently
reviewed; this attempted instantiation is not.

`actual-merged-head-first-failure.log` records the final exact compiler failure.
An earlier run also exposed routine namespace and rank-arithmetic omissions, which
were locally addressed but are not evidence of theorem completion. The initial
attempted source and temporary replay script are retained for diagnosis. No rewrite,
source-correspondence, or performance claim is made.

## Coordinator assessment

The direct gate did not pass. A defensible continuation needs at least (1) a typed rank-cast of each actual shape and its dependent index, with packed-value preservation, (2) identification of the two casted heads and suffixes with the plan-specific extents, and (3) instantiation, nonempty/empty controls, fresh replay and independent review. These are concrete tasks, not evidence that a broader framework is necessary or that the proof is impossible. Their completion time is unknown: the failed draft did not establish the cast bridge, so a reliable cost estimate cannot be inferred from this five-minute attempt. Under the bounded-detour instruction, stop here rather than grow additional abstractions speculatively. Both original-goal (28 files) and separate-closure (45 files) hashes were checked with no mismatch after the attempt. The prior independent helper review was pushed as `e0130280b07513f2dc7c46555ea14e42de016263`.
