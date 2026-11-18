# Independent review of exceptional convolution pad folding

Accepted two kernel-certified model counterexamples. I checked the unchanged freeze at `f823a3d` and the two negated universal statements at `8581cd7`. Both have nonempty operands and an observed nonempty output. Each specializes a different transformation.

| Transformation | Explicit convolution | Folded convolution |
|---|---|---|
| Input, one low-edge zero and no high pad | [0,∞] against [∞,∞] yields [NaN] | The first input position lies outside [∞] and its tap is skipped. The remaining product yields [∞]. |
| Filter, one interior zero | [∞,∞,∞] against [∞,0,∞] yields [NaN] | Dilation two visits input positions 0 and 2 with the two original weights and yields [∞]. |

I checked the three bit representatives and the complete two-operation tables. On positive zero, positive infinity and a single NaN observation the operations stay inside the domain. The inherited `MulCompatible` is only a necessary exceptional condition. Correctness of the remaining table entries here was also assessed by inspection. Lean checks the stated tables and outcomes, without a refinement proof to all binary32 operations. The controls distinguish skipping from evaluating zero times infinity, check regular all-zero agreement, and include singleton and gap-zero behavior.

The pinned simplifier checks the pad-fold option and zero pad value, rejects batch/feature padding for input and feature/edge padding for filter, and updates window edge amounts or filter dilation and size respectively (10749–10883). Both witnesses meet these geometric guards and escape the zero-element branch (11223–11246). The evaluator fills and writes a padded literal at 6968–7058, skips an out-of-range input coordinate at 6002–6029, and multiplies only visited taps at 6063–6065. Materializing zero on an implicit out-of-range tap would remove the input witness. Runtime selection, backend mode, NaN payloads and production miscompilation remain outside the result.

The earlier paper `PadConvolution.convolve_fusion` assumes a semiring. `Theory.ConvolutionFloat` verifies pointwise-dot and ordered-arithmetic properties, and the predicate-multiply result concerns one scalar multiplication. None gives the two frozen convolution refutations. The exact integer filter-pad case concerns the same filter transformation under different arithmetic and should retain that relationship in any count.

Fresh pinned Lean 4.35.0 replay from a temporary directory passed all seven hashes and five modules, with both target axiom closures exactly [propext]. Module times in runner order were 0.357, 0.381, 0.492, 0.410 and 0.367 seconds (2.042 seconds command wall). I inspected the Std-only custom imports, runner, targets and controls. No proof bypass or custom axiom was used. Review timing is shared with the adjacent exact filter review.

Shared independent review window for the two convolution packets: 2026-11-18 00:48:51–00:50:49 UTC, 119 seconds wall including source inspection, replay and writing both reports. This is one shared interval. Active reasoning time and tokens were unmeasured.
