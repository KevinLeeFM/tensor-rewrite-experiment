# Independent review: nested DUS with U64 starts

**Verdict: revision required for source-faithful acceptance.** The packet's formal counterexample is valid for its declared `Case`, and the same U64 witness appears to refute the actual emitted rewrite under the frozen evaluator profile. However, the formal RHS uses the wrong outer clamp bound and predicts a different full result from the source. Keep the proof as a counterexample to its frozen model; do not label that model the exact emitted expression until corrected and replayed.

## Source guard, clamp bounds and operand order

The source snapshot hash was checked by the fresh runner. `HandleDynamicUpdateSlice` matches `DUS(a, DUS(DynamicSlice(a, outer), patch, inner), outer)` when the outer/inner starts match and both shape differences fit the respective integral index types (`algebraic_simplifier.cc:8673–8697`). For widths `10 -> 6 -> 2`, the checks are `6-2 = 4` for the inner index and `10-2 = 8` for the outer index. Both fit U64.

The emitted expression after replacing the outer update with the patch is:

```text
outer' = Clamp_U64(0, outer, 10 - 2 = 8)
inner' = Clamp_U64(0, inner,  6 - 2 = 4)
combined = outer' + inner'       -- source operand order is outer then inner
DUS(base, patch, combined)        -- evaluator clamps this final start again to 10 - 2 = 8
```

This follows directly from the upper bounds at lines 8703–8708 and 8710–8724. The packet's `Case` instead uses `typedStart 4 outer + typedStart 4 inner`. Its outer bound is the original *slice* limit `10-6=4`, whereas the emitted single-update expression clamps outer by `10-2=8`. Thus the packet's control puts the patch at positions 5–6, while the actual source expression for the same witness puts it at 8–9. The `install` on the model RHS correctly represents the final DUS clamp; it cannot repair the earlier outer-bound mismatch.

## U64 evaluator interpretation and witness

`HloEvaluator::GetS64Indices` converts each integral native value with `static_cast<int64_t>` (`hlo_evaluator.cc:1263–1276`). Both DynamicSlice and DynamicUpdateSlice call it (`:3732–3739`, `:3788–3797`) and then clamp to their legal window. On the frozen two's-complement evaluator profile, U64 `0x8000...0000` decodes as a negative signed value and clamps to zero in the original slice/read/write operations. This is an evaluator/compiler-profile assumption, not a proof of C++-to-Lean correspondence or a native reproduction.

For the packet witness (`n=10`, slice length 6, patch length 2, outer U64 sign-bit value, inner start 1, zero base and patch values 7,8), the source's original nested result is `[0,7,8,0,0,0,0,0,0,0]`. Its actual emitted replacement clamps outer to 8, inner to 1, sums to 9, and the final width-2 DUS clamps to 8, yielding `[0,0,0,0,0,0,0,0,7,8]`. These whole arrays differ, so the candidate's substantive counterexample survives the corrected source arithmetic. The packet's proved `Case` is nevertheless a different formula and its advertised RHS array `[0,0,0,0,0,7,8,0,0,0]` is not the emitted result.

A source-faithful repair should use distinct `typedStart 8 outer` and `typedStart 4 inner`, preserve outer-plus-inner addition order, and let the final `install` clamp the sum to 8. The same witness then still refutes equality. No statement or packet files were changed in this review.

The condition is guarded by the shape/index checks above; this review covers only the rank-one 10/6/2 instance and U64 profile. It does not establish the optimizer behavior on all ranks, widths, or index primitive types. It is distinct from the earlier read-only nested DynamicSlice candidate: this target observes the entire nested write and the complete final array.

## Fresh replay and proof status

At 2026-11-18 02:16:53 UTC, ran:

```text
LEAN=/workspace/toolchains/lean-4.35.0-linux/bin/lean python3 comparisons/revised-benchmark-20261117/nested-update-word/replay.py
```

The runner checked its five manifest entries, including the exact source files and `TensorRewrite/Pilot/NestedUnsigned64.lean`, then compiled in a fresh temporary directory. `WordSpec` 0.496 s, `WordProof` 0.409 s, `WordControls` 0.371 s; each exited 0; process elapsed about 1.5 s. Axiom output is `[propext, Quot.sound]`, standard Lean axioms. The earlier `failed-decide.log` and `failed-reduction.log` show failed elaborations and `sorryAx` in their failed diagnostic invocations; they are historical failures, not the final replayed proof. The final proof file contains no `sorry`, `admit`, `native_decide`, or project axiom.

The SHA manifest freezes the spec, scope and source inputs, but omits `WordProof.lean` and `WordControls.lean`; the review is tied to the submitted Git snapshot, not a manifest-enforced proof/control hash. The replay proves the submitted model theorem, not the corrected source-faithful formula described above.

## Timing

Review interval: 2026-11-18 02:14:23–02:19:10 UTC, 4m47s wall time through report preparation; source-reading subinterval was not separately instrumented. The replay began at 02:16:53 UTC, lasted about 1.5 s, with 1.276 s summed Lean target time. Source reading and model/source comparison were not separately instrumented. No native test, broader build, or worker was used.
