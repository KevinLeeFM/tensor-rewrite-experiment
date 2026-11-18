# Independent review: U64 prefix with an S32-derived count

**Verdict: accept the frozen model counterexample, with source reachability and execution unestablished.** Reviewed the packet at `3062e2197a568c140a89df9f8c9d02bcd62bdf3b` and its frozen statement at that revision. Current checkout is `323651d72646260c569393da25cba367d816e519`; the fresh targeted replay passed at this revision. This is a symbolic Lean model refutation, not evidence of a native compiler/runtime bug.

## Source interpretation and exact scope

The pinned XLA source is commit `e58e523b11f1fde802a493a776d158007486e1bf`. In `algebraic_simplifier.cc:9658–9777`, the handler recognizes a direct constant broadcast through certain wrappers, requires a scalar zero initializer, additive reducer and a one-axis cumsum-like window (window size equals the operand extent, stride one, low padding size minus one, high padding zero, unit dilations and no reversal). It creates an Iota whose element type is S64 only when the underlying literal is S64, otherwise S32; it adds one in that Iota type and converts the count to the literal element type when needed. Thus the frozen direct U64-literal subcase takes the S32 Iota/add path and then emits conversion to U64. The checked-in operation documentation at `sources/xla/docs/operation_semantics.md:1789–1821, 3145–3174` describes element conversion and Iota. That documentation file is not listed in this packet’s SHA-256 manifest; its inspected SHA-256 is `35bce8d2…12c4115`, so the cited source-code freeze independently binds the transformation implementation while the documentation interpretation is supporting context. This review did not independently validate backend/device execution of the enormous shape.

The frozen Lean `Goal` quantifies over every `n > 1`, every `r : Fin n`, and every U64 word. It compares a zero-seeded modular U64 sum of `r+1` copies with multiplication by the U64 interpretation of `(r : BitVec 32) + 1#32`. This is exactly the mixed-width count expression in the source-shaped model. The model leaves out explicit window/index tensor construction; for this 1-D window, the in-bounds terms at coordinate `r` are the first `r+1` values and all other padded terms are zero, which is neutral for the frozen addition. It also leaves out backend reachability and allocation/resource limits. The witness requires no allocation in Lean, but its corresponding materialized tensor would be enormous.

## Counterexample and prior overlap

The theorem uses `n = 2^31`, `r = 2^31 - 1`, and `value = 1`. The original U64 prefix is `0x0000000080000000`. S32 `iota + 1` wraps to `0x80000000`, and interpreting that signed S32 value as U64 yields `0xffffffff80000000`, so the replacement differs. The immediate predecessor, `r=2^31-2`, agrees; the packet also compiles an ordinary value/count control. The symbolic proof establishes a valid witness in the frozen mathematical model. It does not establish that this huge HLO passes every resource/backend restriction or executes natively; do not call it a reproduced implementation bug.

This substantially overlaps existing theory and a known boundary result. `TensorRewrite.Theory.PrefixWindow.word_prefix_product` already proves a same-width modular prefix-count/product identity for arbitrary scan extents; `word_prefix_count` gives the count modulo its width, and `PrefixWindowCounterexamples.signed_width_boundary_refuted` already proves the 32-bit signed threshold failure. The new packet's significance is its source-shaped composition: a U64 prefix is multiplied by a count first formed in S32 and then converted to U64. It adds no new discovery of the signed 32-bit boundary or constant-prefix product law. `PrefixProof.folded` independently reproves a short generic replicate-fold fact rather than importing the existing `word_replicate_fold`; this duplication is harmless to theorem validity but means the measured proof is not full reuse of that helper. The packet itself correctly says it earns no new discovery credit for the historical boundary.

## Replay, axioms, and cost

Ran exactly:

```sh
LEAN=/workspace/toolchains/lean-4.35.0-linux/bin/lean \
  python3 comparisons/revised-benchmark-20261117/prefix-wide-count/replay.py
```

Exit status was 0. Fresh private compilation times were `PrefixSpec` 0.330 s, `PrefixProof` 0.342 s, `PrefixControls` 0.422 s: **1.094 s summed compiler time**, about 1.3 s wrapper wall time. The four entries in `SHA256SUMS` all matched. The negative theorem's axiom report is `[propext]`, within the packet's allowed foundation. The exact control file compiled, including the threshold and predecessor outputs. No `sorry`, `admit`, `native_decide`, or project axiom appears in the reviewed proof.

Author's `author.log` records setup/freeze 95 s, proof/control/replay 21 s, replay module times 0.356/0.333/0.336 s, and a prior failed control replay (the stale `PrefixControls.lean` had an extra tactic after a closed goal). The current fresh replay fixes that state and passes. That failure is retained as validation overhead, not proof-search time. The first timestamped reviewer checkpoint was 01:33:52 UTC and finalization was 01:39:08 UTC (at least 5 min 16 s of this review); source inspection began before the checkpoint, so complete reviewer elapsed/active time and token cost are unknown. No broad build, large allocation or native execution was run.

**Limit:** this is one model counterexample for a source-shaped static branch and the disclosed conversion interpretation. It does not show the XLA pass executed on a realizable input, and does not close the other three lexical cumsum branches, the whole source record, or C++–Lean correspondence.
