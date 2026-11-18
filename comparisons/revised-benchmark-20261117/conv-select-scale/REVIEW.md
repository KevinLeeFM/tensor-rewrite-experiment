# Independent review: scale moved from one Select arm

**Verdict: accepted as a source-grounded counterexample in the frozen one-tap F32 model, with the documented scope.** The refutation is not a whole-convolution rewrite proof; it disproves the proposed branch-local scale movement for both size orientations in this packet.

## Scope and source correspondence

The frozen scope fixes a one-tap, one-input-channel convolution with stride one and no padding/dilation, one result per `Fin n`, `n > 1`, and exactly two operand-size orientations: input has one element while filter/output have `n`, or filter has one element while input/output have `n`. A single scalar F32 multiply-by-2 occurs only in the `Select` true arm of the larger operand, and the false arm is unscaled. These are concrete, nonempty, non-tied size cases for the source's strict size comparisons.

The source linkage is real. `HandleConvolution` calls `ScalarMultiplyReduction` when `enable_scalar_multiply_reduction` is enabled (`algebraic_simplifier.cc:11224–11228`). Its DFS permits `kSelect` (`IsOpCodeMultiplyCommutative`, lines 638–647), descends through that node's operands, finds the true-arm `Multiply(a, Broadcast(c))` at lines 732–753, removes it, and accumulates `c`. For the one-element target, the output has `n` elements and the other operand has `n`, so `target` is the small operand; the branch multiplier is applied there after traversal. The freeze's `no other eligible multiplies or users` restriction prevents additional constants from changing the chosen scalar or introducing an unrelated consumer-side rewrite. This is specifically different from moving one multiplier that encloses the whole `Select`.

The graph and layout conditions in `FREEZE.md` are assumptions of this bounded model. The Lean packet does not encode an HLO parser, graph users, convolution dimensions, or a path-execution theorem. Source/test reading supports the mapping, but there is no native XLA execution in this review.

## Mathematical check

`ScaleSpec.lean` models a positive one-term MAC and rounds every multiply/add through the packet's integer `r32`. All packet operands are in `[0,15]`, so every intermediate is an exactly representable F32 integer (maximum product 225); the model's rounding therefore agrees with ordinary F32 arithmetic on the selected instances. With `x=2`, `c=2`, true-arm `a=3`, false-arm `b=5`, and predicate true at output 0, the true-arm output agrees at 12. At output 1 the false arm gives 10 before the rewrite and 20 after it. The proof evaluates that second output and refutes `Case true` and `Case false`; the controls also verify both arms explicitly. Controls check two fixed-point cases (`c=1` and `b=0`) where the two programs agree.

This is a genuine counterexample to the exact quantified packet statement, not evidence that every source invocation is unsafe. The `Fin n` output functions and `n > 1` make the witness well-typed and nonvacuous. The two orientations are both discharged by the `side : Bool` case split.

## Fresh replay and axioms

Fresh command at 2026-11-18 02:10:06 UTC:

```text
LEAN=/workspace/toolchains/lean-4.35.0-linux/bin/lean python3 comparisons/revised-benchmark-20261117/conv-select-scale/replay.py
```

Replay process wall time: approximately 1.7 s. Lean target times: `RadixSpec` 0.435 s, `ScaleSpec` 0.365 s, `ScaleProof` 0.278 s, `ScaleControls` 0.347 s; all exit 0. The runner verified all five SHA256 entries before copying the files to a fresh temporary directory. `#print axioms` reports only `[propext]`, a standard Lean axiom. The packet imports `Std`/`RadixSpec`, not the project's Mathlib closure; no `sorry`, `admit`, `native_decide`, or added axiom is present.

## Limitations and overlap

The result covers only a scalar multiply found in one `Select` branch, the stated source option, size orientations and single-use restrictions. It excludes non-F32/BF16, multiple scalar factors, additional eligible users, and later simplifier/optimization behavior. The counterexample is an abstract HLO-shaped model witness supported by source inspection, not a runnable native bug report.

This is distinct from whole-convolution scalar movement, from the two-arm scale cases already captured by `SelectContraction`, and from the biased-convolution distribution packet. It is not covered by the exact semiring identities in `ConvolutionAlgebra`; it exposes the fact that leaving the false branch unscaled changes that branch. No blanket claim about the larger `ScalarMultiplyReduction` case family follows.

## Timing

Source/model review and replay were performed 2026-11-18 02:07–02:11 UTC (about 4 minutes wall time shared with the adjacent convolution packet review). The fresh replay itself took about 1.7 seconds; the summed Lean compilation time was 1.425 seconds. No separate active-token measure was available.
