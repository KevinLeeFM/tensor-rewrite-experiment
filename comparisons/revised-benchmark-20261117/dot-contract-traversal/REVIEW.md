# Independent review: contracting-transpose traversal

**Verdict: accept the frozen strict ordered-F32 model counterexample for both constant-side orientations. Do not report it as a backend-independent HLO source disproof.** The source helper's layout and operand guards match the frozen transpose/reshape configuration, but the helper assumes contraction accumulation is associative and this candidate's sequential F32 RNE observation is order-sensitive. Source/backend accumulation freedom is not modeled by the Lean theorem or by this packet's controls.

## Identity and fresh replay

Reviewed at current tip after freeze `07cc520` and proof/control commit `c995fa9`. `SHA256SUMS` passed for `TraversalSpec.lean`, `FREEZE.md`, reused `RadixSpec.lean`, and pinned `algebraic_simplifier.cc`.

Fresh direct command: `LEAN=/workspace/toolchains/lean-4.35.0-linux/bin/lean python3 comparisons/revised-benchmark-20261117/dot-contract-traversal/replay.py`, 2026-11-18 04:27:45–04:27:47 UTC (shell elapsed 2 s). All four Std-only commands returned 0: `RadixSpec` 0.376 s, `TraversalSpec` 0.402 s, `TraversalProof` 0.322 s, `TraversalControls` 0.348 s (reported compiler sum 1.448 s). The theorem printed is `refuted : ∀ side, ¬Goal side`; axioms are `[propext, Quot.sound]`. The final compiled closure contains no `sorryAx`, `native_decide`, or project axiom. The earlier `failed-explicit-types.log` is preserved failed-draft evidence and is not in the successful replay. No C++ build or native execution was performed. Review source-reading time was not instrumented; replay/compiler times are separate.

## Traversal and operand orientation

At `algebraic_simplifier.cc:3410–3616`, `OptimizeDotOfReorderContractingDims` requires layout-insensitive mode, one contracting dimension, `Dot(reshape(transpose(input)), constant)`, and a reshape that squishes the transposed axes into the contracting dimension. It checks the unsquished contracting axes are consecutive and that the transpose permutes only those axes. It then reorders the LHS contracting axes, reshapes the nonconstant LHS without the transpose, unsquishes the constant's single contracting axis, applies the inverse transpose, and reshapes it back. At `:3418–3428`, a constant on the original left is locally swapped to the canonical right side; at `:3608–3612`, the new dot operands are swapped back, preserving the original operand roles.

For the frozen rank-two `[2,2]` transpose `{1,0}` followed by flattening, the row-major contracting order changes by `flip(k) = (k % 2) * 2 + k / 2`, giving `[0,2,1,3]`; this transpose is self-inverse. The packet's `old` formula pairs `x[flip k]` with `w[k]`, while the transformed dot pairs `x[k]` with `w[flip k]`. This correctly expresses the same exact products under a contracting-index relabeling, in either source operand orientation. The bounded controls verify the flip order and a small integer equality case.

The helper's own comment at `:3406–3409` explicitly motivates the rewrite by assuming associative accumulation and synchronously permuting contracting terms. The call at `HandleDot :4461–4470` has no precision-config/associativity guard around this helper. Earlier transformations can still take precedence: the frozen profile must ensure strength reduction, associative reorder options, and other eligible dot rewrites do not intercept first. This is a modeled direct source path; no actual pass run or option-config verification was performed here.

## Numerical witness and source-scope limitation

The frozen natural-number data and weights are nonnegative; `x ≤ 2^24`, `w ≤ 2`. Every input and product (including the maximum product `2^25`) is exactly representable in binary32, and the finite sum stays well below overflow. Thus the mismatch is not a product-rounding artifact. In the ascending `k=0..3` RNE fold, the old products are `[1, 16777216, 1, 0]` and produce `16777216`; the transformed products are `[1, 1, 16777216, 0]` and produce `16777218`. The same values hold when multiplication operands are reversed, since these finite products are exact. `TraversalProof.refuted` proves the counterexample for both booleans, and controls assert both outputs.

This is a counterexample to **strict left-to-right F32 rounding after each accumulated term**. The HLO Dot documentation describes the sum of products and precision settings; it notes preferred accumulation type is a recommendation, not guaranteed. The simplifier comment itself relies on associativity. No backend was run to establish which accumulation orders are actually selected or permitted for this exact graph. Therefore the theorem does not disprove the broader source rewrite under a backend contract that allows reassociation or another accumulator schedule. It identifies a real exact-model distinction and an unresolved source observation/schedule boundary.

## Timing and limits

Fresh replay wall interval was 2 s; summed Lean compiler time was 1.448 s. Review active time was not measured. No native execution, source correspondence, or performance claim is made.
