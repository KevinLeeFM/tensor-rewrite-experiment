# Independent review: empty Pad fold shape packet

**Verdict: accept the frozen-model shape refutation, but not a source-validated or full-pass defect claim.** The Lean target proves `[2,2] ≠ [3,2]` under the frozen `WindowEarly.extent` definition for the direct and converted profiles. The source shape-inference call path is present, but the key out-of-line window helper bodies are absent from this snapshot, and an earlier empty-input `HandlePad` branch may remove the pattern before `HandleReduceWindow` sees it.

## Identity, hashes, and direct replay

Reviewed against packet freeze `baf957d` and candidate `fb433f9` at source commit `e58e523b11f1fde802a493a776d158007486e1bf`. The packet `SHA256SUMS` passed for `EmptyFoldSpec.lean`, `FREEZE.md`, reused `EarlySpec.lean`, `window_util.h`, `shape_inference.cc`, `hlo_verifier.cc`, `hlo_instructions.h`, and `algebraic_simplifier.cc`.

Fresh direct command: `LEAN=/workspace/toolchains/lean-4.35.0-linux/bin/lean python3 comparisons/revised-benchmark-20261117/window-empty-pad-shape/replay.py`, 2026-11-18 04:26:20–04:26:21 UTC (shell elapsed 1 s). All four Std-only invocations returned 0: `EarlySpec` 0.530 s, `EmptyFoldSpec` 0.347 s, `EmptyFoldProof` 0.329 s, and `EmptyFoldControls` 0.320 s (sum 1.526 s). `witness` and `refuted` were both axiom-free. No native run, HLO verifier, full pass, Lake, or download was performed. Review-reading time was not instrumented; compiler time is separately recorded here.

## Arithmetic result

For the frozen geometry with `n=0`, first-axis base dilation 2, one edge Pad cell on each side, and width-2 window, `EarlySpec` yields old padded extent 2, old dilated span 3, and old output extent 2. The emitted profile has base extent 0 and scaled edge pads 2+2; under `EarlySpec`'s empty-span rule the fused output extent is 3. The unchanged second axis has extent 3 and output 2, so declared `[2,2]` and modeled inferred `[3,2]` differ. The proof's `refuted` theorem negates only the frozen `Goal`; it uses `decide`, has no assumptions beyond that definition, and is not a Lean theorem about C++.

The model uses the same standard output equation visible in source: `InferWindowOutputShape` at `shape_inference.cc:188–237` obtains dilated base, adds low/high edges, obtains dilated window, then calls `window_util::StridedBound`. `InferPadShape` at `:742–800` gives the Pad result `[2,3]`. `ShapeVerifier::HandleReduceWindow` at `hlo_verifier.cc:2039–2052` compares the declared shape to inferred shape. However, only declarations/comments for `DilatedBound` and `StridedBound` are present in `window_util.h`; `window_util.cc` is not present in the pinned source tree. In particular, I cannot independently verify from available source that the helper returns zero for a zero bound with dilation 2, which is the decisive assumption in this example. The packet author explicitly records that limitation. Thus the type mismatch is conditional on `WindowEarly.extent` matching those helper results at empty bound, not a verified source failure.

## Direct handler versus pass reachability

The Pad-fold block at `algebraic_simplifier.cc:9917–10112` directly accepts a `Pad` operand or `Convert(Pad)`, rejects negative Pad and simultaneous interior Pad/base dilation, matches Pad value and init (or converted constant literals), scales edge pads, avoids the broadcast alternatives for the stated two-active-axis case, then constructs a ReduceWindow with the *old* result shape annotation at `:10106–10112`. The packet checks the converted-only padding-ratio guard is inapplicable with two nontrivial window dimensions. On a direct invocation with the frozen input, the outer ReduceWindow's operand is the nonempty padded shape `[2,3]`, and its output `[2,2]` is nonempty, so the earlier empty ReduceWindow/output dispatch does not intercept it.

The source also has an operand-first alternative at `HandlePad` `:6198–6203`: if Pad's original operand has zero elements, it replaces Pad by a broadcast of its fill. The packet is specifically a direct-handler profile and does not run the visitor/pass ordering. Consequently it does not establish that the default pass reaches the Pad-fold branch, that the generated graph is accepted/rejected by an actual verifier run, or that any backend observes a defect. The source snapshot includes the ReduceWindow constructor call retaining the old annotation but not an actual handler invocation.

The prior `PadWindow.empty_high_formula_refuted` is genuine overlap on the empty-edge high formula. This packet adds a two-axis frozen shape adapter, not a new geometric root cause. The stored case row currently says `disproved`; read that as the frozen-model outcome only. Source-record and full-pass verdicts remain unestablished.

## Timing

Fresh replay wall interval: 1 s; summed compiler time 1.526 s; no failures. Review/source-reading start was not captured, so total review effort is unknown. No proof or experiment beyond the direct replay was performed.
