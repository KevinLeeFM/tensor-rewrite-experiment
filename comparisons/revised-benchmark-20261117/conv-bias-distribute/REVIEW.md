# Independent review: distribute feature scale across convolution and bias

**Verdict: accepted as a source-grounded counterexample in the frozen one-tap F32 model, under the stated guards.** The counterexample disproves the frozen finite-precision rewrite for each of its four operand-order combinations; it does not refute the exact-semiring theorem.

## Scope and source correspondence

The frozen model fixes a dense one-tap convolution, one input channel, one feature group and one batch group, a constant filter, a compatible bias, and a nonuniform length-`n` constant scale broadcast on the output-feature axis. The convolution and bias are single-use operands of an add, and the broadcast is single-use by the outer multiply; the option `enable_conv_add_multiply_reorder` is enabled. With one spatial term and a positive-zero seed, the reduction-order/parallel-sum issue is absent for the witness.

The source path matches this shape. `HandleMultiply` delegates to `TryToReorderConvAddMultiply` (around `algebraic_simplifier.cc:5412`). The matcher at lines 5138–5158 accepts either order of outer multiply and either order of `Conv + bias`, requires the convolution and bias operands each to have one user, the convolution filter to be constant, and the multiplier to be a broadcast of a rank-one constant. It then checks that the broadcast's sole dimension is `dnums.output_feature_dimension()`. It broadcasts the scale to `dnums.kernel_output_feature_dimension()`, multiplies the filter, clones the convolution, multiplies bias by the output broadcast, clones the add, and replaces the outer multiply (lines 5160–5180). The standard source test `ReorderConvAddMul` at `algebraic_simplifier_test.cc:745` exercises this option and pattern with a constant filter, output-feature broadcast, bias and ordinary single-group convolution; the disabled-option test at line 775 checks the gate.

The packet's specific model instance is representable by that graph: batch/spatial extent 1, input feature extent 1, two output features, all-one constant filter and bias, and a two-element scale `[1,3]`. This satisfies the scale/output-feature and filter/kernel-output-feature extent agreement for group count 1. The source pattern does not itself explicitly guard feature/batch group counts; the packet intentionally claims only one group of each, so do not extend its mapping to grouped convolution. It also does not formalize graph matching, user counts, dimensions or option dispatch in Lean. Those conditions are stated in `FREEZE.md` and corroborated by source/test inspection; no native XLA execution was run.

## Mathematical check

`BiasSpec.lean` defines one-term convolution with a positive-zero seed and applies `r32` at each multiply/add boundary in both original and replacement calculations. The witness is `n=2`, input `2^24`, constant filter `[1,1]`, constant bias `[1,1]`, and nonuniform scale `[1,3]`; the queried output is the feature with scale 3. All operands are nonnegative integers in the frozen bounds, and the largest product remains below `2^33`, far inside binary32's finite exponent range. The model is nearest-even rounding of nonnegative integer values, so no NaN, infinity, signed-zero, or subnormal behavior is claimed.

At feature 1 the old path computes `r32(r32(2^24 + 1) * 3) = 50,331,648`, because the first add is a halfway tie rounded to even. The new path computes `r32(2^24 * 3 + 1 * 3) = 50,331,652`; at that magnitude the integer 50,331,651 rounds to the nearer binary32 multiple of 4. The proof chooses this output and refutes `Goal outer inner` for all four `outer`/`inner` operand-order combinations. Controls independently evaluate the two distinct values, a case at scale 1 where they agree, and the unrounded integer distributivity identity (showing why a real/semiring proof would miss the rounding counterexample). `n=2` makes the quantified output domain nonempty and the scale vector nonuniform.

## Fresh replay and axioms

Fresh command at 2026-11-18 02:10:11 UTC:

```text
LEAN=/workspace/toolchains/lean-4.35.0-linux/bin/lean python3 comparisons/revised-benchmark-20261117/conv-bias-distribute/replay.py
```

Replay process wall time: approximately 1.5 s. Lean target times: `RadixSpec` 0.332 s, `BiasSpec` 0.309 s, `BiasProof` 0.302 s, `BiasControls` 0.303 s; all exit 0. The runner checked all five frozen SHA256 entries, then compiled the four Std-only modules in a fresh temporary directory. `#print axioms` reports only `[propext]`, standard Lean. No `sorry`, `admit`, `native_decide`, or added axiom is present. This replay does not exercise `ConvolutionSeparableProof` or require Mathlib.

## Limitations and overlap

This is an exact counterexample to the stated integer-rounding model of the full biased-convolution scale distribution and maps to one guarded source shape. It does not establish native execution, compiler reachability across later passes, a broad source-record theorem, or behavior for other precisions, negative/nonintegral inputs, NaNs, infinities, subnormals, grouped convolutions, or empty outputs.

`TensorRewrite.Theory.ConvolutionAlgebra.convolve_bias_scale` is a valid exact semiring identity and is algebraically the corresponding unrounded law. It does not model IEEE rounding after convolution, bias addition and multiplication; the packet's finding is therefore not an overlap or contradiction with that theorem. It is also distinct from `conv-select-scale`: here the scale applies to the whole biased result and is distributed to both filter and bias; there it is removed from only one `Select` arm, changing the other arm. The frozen source/test guards distinguish these paths.

## Timing

Source/model inspection was underway by about 02:07 UTC; its exact start was not instrumented. The group ended with the reviews committed at 02:12:57 UTC. From the first timestamped replay (02:10:06) through commit, elapsed wall time was 2m51s; the earlier source-inspection interval is approximate and shared with `conv-select-scale`. The fresh replay took about 1.5 seconds; summed Lean compilation time was 1.246 seconds. No separate active-token measure was available.
