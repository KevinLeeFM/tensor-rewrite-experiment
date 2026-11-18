# Independent review: full-window F32 fold versus fast Reduce

**Verdict: accepted as a bounded strict-equality counterexample for the pinned XLA HloEvaluator profile.** The theorem and witness correctly distinguish the source evaluator's F32 accumulator from its fast Reduce binary64 chunk accumulator in the frozen one-chunk domain. This is not evidence of a native/backend compiler bug or a universal IEEE/backend result.

## Source guard and scope

The packet freeze and its manifest refer to `HandleReduceWindow/full-dimensions` at `algebraic_simplifier.cc:9871–9913`. Earlier handler branches precede it: empty input/output at 9590–9600; scalar input at 9601–9623; variadic handling at 9624–9648; then other rewrites. The packet's rank-one nonempty input with `N>=2`, simple scalar add, and a size-`N` window avoids those branches and the trivial size-one-window branch. With stride, padding, and dilation all one/zero as frozen, the static output count is `N-N+1=1` by `InferWindowOutputShape` (`shape_inference.cc:188–237`). The full-dimension path sees a nonempty reduction-dimension list `[0]`, deletes it to make a scalar Reduce, and reshapes that result to `[1]`.

The simplifier's `enable_window_reduce_to_reduce_replacement` option is checked at 9871 and defaults true (`algebraic_simplifier_options.proto:53–55`). The selected full-dimension branch itself checks absence of stride, dilation and padding, and accepts each axis when the window size is 1 or the output extent is 1. It does not check `window_reversal` there; the packet explicitly freezes no reversal, so it does not depend on the evaluator's separate behavior for that flag. The single-output F32 `add(param0,param1)` and +0 initializer satisfy the evaluator's simple binary reducer path. All N entries are within a rank-one, contiguous logical input; the packet makes no layout or device claim beyond that evaluator profile.

## Arithmetic distinction and counterexample

For the original ReduceWindow, `HloEvaluator::HandleReduceWindow` selects `EvaluateSimpleReduceWindowTyped` for a simple scalar binary reducer (`hlo_evaluator.cc:5068–5120`). F32 uses `ReturnT=float` and `ElementwiseT=float` (`:5040–5063`); `ApplyBinaryOp` returns the rounded elementwise result after each addition (`:4971–4979`). `IterateThroughWindow` advances the one-dimensional coordinate from low to high (`:4047–4132`). Thus the frozen original is a sequential F32 fold from +0.

For the replacement Reduce, `GenerateReduceOutputElement` uses its fast floating-add path only when the evaluator fast flag is on, the reduction is floating, the reducer is simple scalar addition, and the output is not tuple (`:4760–4774`). That path collects linear indices in chunks of 512, sums each chunk with `LiteralBase::GetSumAsDouble` and stores once with `SetFromDouble` (`:4786–4818`; `literal.cc:1514–1534,1579–1592`). The Reduce fast flag defaults to true but can be disabled (`hlo_evaluator.h:248–252,838–842`); the review therefore accepts only the explicitly frozen enabled profile. For `2<=N<=512`, this is one chunk (N=512 flushes exactly once). Each nonnegative integer input is exactly representable in F32 through `2^24`; the total is at most `512*2^24 = 2^33`, exactly representable in binary64. The fast model therefore computes the exact integer sum before one RNE F32 conversion. Reshape to `[1]` is value-preserving.

The submitted witness `[16,777,216,1,1]` is valid and nonvacuous. In the original fold each addition of 1 at `2^24` is a halfway tie rounded to the even value `16,777,216`, yielding `16,777,216`. The one-chunk fast sum is `16,777,218`, exactly representable in F32, and remains so after the final narrowing. These differ by one F32 ULP at that scale. The proof refutes the full quantified `Goal`, not merely one coordinate of a larger output. Controls confirm this witness, an equal result for `[1,1,16,777,216]` where the two increments accumulate before reaching the tie, and the exact small-sum case `[4,2,1]`.

`RadixSpec.r32` is an integer-domain RNE model. The restrictions keep every input and accumulated sum nonnegative, finite, and within the exact integer range stated above; no subnormal, overflow, cancellation, NaN, signed-zero, or conversion ambiguity is exercised. The known common-fold theorem is not contradicted: the original and replacement here intentionally use different intermediate precision.

## Backend and IEEE boundary

This establishes a strict result difference between two pinned evaluator paths under `use_fast_path_reduce=true`. It does not establish which result any compiled backend must produce. A backend may use sequential F32 accumulation, a reassociated/tree reduction, or another permitted schedule; reduction order and intermediate precision are separate from this evaluator's implementation. The packet correctly disclaims native XLA execution, C++–Lean correspondence, all-backend equality, and speed claims. Its conclusion should remain an evaluator-profile counterexample, not a claim that the optimizer necessarily causes a user-visible compiled-program difference.

## Fresh replay and axioms

Fresh command at 2026-11-18 02:27:03 UTC:

```text
LEAN=/workspace/toolchains/lean-4.35.0-linux/bin/lean python3 comparisons/revised-benchmark-20261117/window-full-f32/replay.py
```

The runner verified all eight listed files (statement, RadixSpec, toolchain and pinned XLA source inputs) and compiled four modules in a fresh temporary directory. `RadixSpec` 0.410 s, `FullFastSpec` 0.322 s, `FullFastProof` 0.399 s, `FullFastControls` 0.334 s; all exited 0. Replay process elapsed about 1.7 s; summed Lean target time was 1.465 s. `#print axioms` reports `[propext, Quot.sound]`, standard Lean axioms. No `sorry`, `admit`, `native_decide`, or added axiom is present. The manifest does not hash `FullFastProof.lean` or `FullFastControls.lean`; this review is tied to the submitted Git packet, and the runner enforces the statement/source hashes rather than separate proof/control hashes.

## Timing

Review began 2026-11-18 02:25:47 UTC and evidence/report preparation ended 02:27:34 UTC (1m47s before the commit operation). Source inspection and the replay were included; no native test, broad build, or child worker was used. No separate active-token measurement is available.
