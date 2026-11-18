# Pinned window utility source supplement

Independent source fetch: [`xla/window_util.cc` at XLA commit `e58e523b11f1fde802a493a776d158007486e1bf`](https://github.com/openxla/xla/blob/e58e523b11f1fde802a493a776d158007486e1bf/xla/window_util.cc#L238-L275), Git blob `e60354b68d2292bf66a0694c79622e0655200d3e`. Fetched once using the GitHub repository-file tool for lines 238–275; no other file was fetched. This fills the missing-helper gap recorded in `REVIEW.md`.

`DilatedBound(0,d)` returns zero explicitly. Otherwise it computes `(bound - 1) * dilation + 1`, with overflow checking. `StridedBound(bound, window_size, stride)` returns zero when the bound is zero or the window exceeds the bound; otherwise it computes `(bound - window_size) / stride + 1`.

Substituting those source formulas into `InferWindowOutputShape` (`shape_inference.cc:188–237`) confirms the frozen profile's result:

- Original axis 0: Pad turns extent 0 into 2; base dilation 2 gives 3; window extent 2 and stride 1 give output 2.
- Emitted axis 0: extent 0 remains 0 after dilation; scaled edge padding gives bound 4; window extent 2 and stride 1 give output 3.
- Axis 1 remains extent 3 with width 2, yielding output 2 in both cases.

Thus the original declared result is `[2,2]`, while inference for the emitted operand/window is `[3,2]`. `ShapeVerifier::HandleReduceWindow` (`hlo_verifier.cc:2039–2052`) compares declared shape with `InferReduceWindowShape`, so a graph containing the direct handler's emitted instruction would fail that shape check. The packet's result is therefore source-formula-supported, not merely a match to `WindowEarly.extent`.

Remaining limit: this does not show that the default simplifier pass actually emits that instruction. `HandlePad` first replaces a Pad whose input is empty with a broadcast (`algebraic_simplifier.cc:6198–6203`); whether this runs before the enclosing ReduceWindow's Pad-fold branch was not tested. No HLO was built, simplified, or passed through the verifier. The result remains a direct-handler/source-shape counterexample, not an observed full-pass defect or runtime outcome. No new mathematical case is counted.

Timing: the GitHub fetch and formula comparison were completed in this short inspection pass; exact start time and connector-call duration were not exposed. Compiler/build time is zero; no native execution or extra downloads.
