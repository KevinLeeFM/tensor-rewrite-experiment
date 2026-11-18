# Independent review: partial update addition and signed zero

**Verdict: accepted for the declared zero-only binary32 model.** The exact iff and counterexample are correct in that scope and map to both `HandleAdd` operand-order cases. The packet does not state an iff over arbitrary F32 values; the source transformation accepts arbitrary values, so keep this result explicitly as a signed-zero model partition.

## Source mapping and index semantics

At `algebraic_simplifier.cc:1031–1037`, `HandleAdd` matches either Add operand order with a DynamicUpdateSlice whose base is `Broadcast(ConstantEffectiveScalar(0))`. It takes the update shape, slices the other Add operand at the raw DUS indices, constructs `Add(sliced_lhs, update)` in that order (lines 1038–1045), and writes it back to the original full-shape lhs with the same index operands (1047–1051). Thus the source emits the packet's `replacement` addition order for either `first` setting. For binary32 signed zeros, swapping the two addition operands preserves the zero-sign result under round-to-nearest-even, as modeled by `Bool.and_comm`.

The packet models a rank-one dense logical array and a window `origin = min(n-m, start.toNat)`. In XLA's evaluator, both the DynamicSlice and the replacement DynamicUpdateSlice consume the same unchanged index operands and both call `GetS64Indices` followed by the appropriate legal-window clamp. A U64 high-bit index follows the evaluator's signed narrowing behavior noted in the sibling packet, then clamps as a negative start; the same raw index goes to both operations here. This candidate does not add typed arithmetic to the index and therefore has no outer-plus-inner clamp mismatch. The Lean `Int` start model describes an already signed evaluator value; it is not a complete primitive-index encoding theorem.

## Exact model theorem and counterexample

`ZeroSpec` represents only `+0` and `-0` by their sign bits and defines round-to-nearest-even addition on those two encodings: negative zero results exactly when both operands are negative zero. `PartialSpec` represents every array/update element by one of those two zero signs. Under that restricted domain, `agree_iff` correctly says that original whole-array addition and the partial replacement agree iff each base element outside the update window is `+0`.

For a concrete whole-array witness, let `n=3`, `m=1`, start 1, base `[-0,-0,-0]`, patch `[+0]`. The original adds the DUS result `[+0,+0,+0]` to the base, producing `[+0,+0,+0]`; the replacement changes only the middle element to `(-0)+(+0)=+0`, retaining the exterior `-0`s, so it produces `[-0,+0,-0]`. The arrays differ at both outside positions. `refuted` derives a contradiction from `agree_iff` at one such position for either Add operand order. The stated iff is exact over zero-sign arrays, including full-width (`m=n`) where the outside condition is vacuous; it is not an iff for general F32 arrays, since nonzero finite values outside the window also satisfy `x + +0 = x` bitwise. NaN and exception/payload behavior is outside the model.

The controls check negative and high positive starts clamp to window boundaries, inside-window signed-zero addition, an outside sign difference, and the all-`+0` exterior agreement case. The edge-start controls directly check `locate`; they do not enumerate full output arrays for those two edge starts. The general theorem covers arbitrary signed starts, but the packet has no native execution test.

## Fresh replay, axioms and reuse

At 2026-11-18 02:16:58 UTC, ran:

```text
LEAN=/workspace/toolchains/lean-4.35.0-linux/bin/lean python3 comparisons/revised-benchmark-20261117/partial-add-zero/replay.py
```

The runner checked four listed hashes, including `PartialSpec`, `FREEZE`, `ZeroSpec`, and the source, then compiled four modules in a fresh temporary directory. `ZeroSpec` 0.351 s, `PartialSpec` 0.391 s, `PartialProof` 0.377 s, `PartialControls` 0.351 s; all exited 0; process elapsed about 1.8 s. `#print axioms` reports `[propext, Quot.sound]`, standard Lean axioms. No `sorry`, `admit`, `native_decide`, or added project axiom is present. The hash list does not include `PartialProof.lean` or `PartialControls.lean`; this review is tied to the submitted Git snapshot, not a runner-enforced proof/control hash.

Existing zero-add algebraic identities are relevant historical mathematical reuse but do not by themselves capture this full-array signed-zero observation. The packet correctly keeps that reuse distinct from its new iff. The result is a counterexample for one source-accepted signed-zero input, not a native bug report or a full binary32 source theorem.

## Timing

Review interval: 2026-11-18 02:14:23–02:19:10 UTC, 4m47s wall time through report preparation; source-reading subinterval was not separately instrumented. The fresh replay began at 02:16:58 UTC and lasted about 1.8 s, with 1.470 s summed Lean target time. Source reading and model analysis were not separately instrumented. No native test, broader build, or worker was used.
