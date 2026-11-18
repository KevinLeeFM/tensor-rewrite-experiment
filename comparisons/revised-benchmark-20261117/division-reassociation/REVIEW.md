**Accept four strict-model counterexamples**, one per distinct expression pair. I checked the frozen specification blob from 5315340 (SHA-256 36a60af0…39527), all proofs and controls at 9e0b868, and the source. Positive finite powers of two are representable from exponents −149 to 127 including subnormals. Their exact products/quotients are powers of two; at exponent −150 the halfway case rounds to even zero, and exponents at least 128 overflow to infinity under RNE. The zero, infinity and NaN cases in DivSpec implement all combinations needed here. None of the failures depends on distinguishing NaN payloads or the sign of zero.

| Expression | Finite inputs | Original | Replacement |
|---|---|---|---|
| Reciprocal multiplication | a=b=2⁻¹⁴⁹ | 1 | +∞ |
| Fraction over fraction | a=b=c=d=2¹²⁷ | 1 | NaN from +∞/+∞ |
| Nested numerator | a=b=c=2¹²⁷ | 2⁻¹²⁷ | +0 |
| Nested denominator | a=b=c=2¹²⁷ | 2¹²⁷ | +∞ |

The three 2¹²⁷ examples can assign equal values to distinct same-shaped parameter nodes; equality of runtime values does not require sharing the operands or exposing constant subexpressions. The reciprocal instance can use an F32 parameter divided by the smallest positive subnormal literal. For the direct/literal-broadcast matcher, InvertConstant computes the element-typed reciprocal, then the replacement multiplies by it. The separate one-use broadcast-input rewrite checks CPU, sink-broadcast and fast-math and even documents strict discrepancies. Its allowed fast-math behavior is a different observation question. The three nested rewrites have no local fast-math tests; division by integral types returns earlier. These are source readings of algebraic_simplifier.cc:2529–2533, 2592–2620 and 2680–2769. No compiled graph, native target, flush-to-zero behavior or pipeline reachability was tested. Accounting should group the equivalent scalar reciprocal formula across matching source exits.

Historical NumericalField and paper divmod/rule00–03 use exact field/real arithmetic. NumericalCounterexamples' negative-input power-denominator and complex reciprocal-sqrt cases involve different operations and guards. The earlier large-handler review (reviews/results/census-pilot-v1-large-handlers-codex-reviewer.md:285–303) already distinguished the fast-math guards, anticipated reciprocal rounding and proposed an unexecuted 7/3 probe. This packet verifies finite witnesses on its pinned submodel; it does not discover the broad fact that floating reciprocal rounding can differ.

Fresh private offline Lean 4.35 replay validated the four hashes, all four exact negations, threshold and equality controls. Each refutation depends only on propext. DivSpec/DivProof/DivControls took 0.462/0.314/0.356 s (1.132 s compiler). Independent review began 01:37:36 UTC 2026-11-18, interleaved with the Clamp review; the two fresh replay processes overlapped. Individual active reasoning time unavailable.
2026-11-18T01:39:02Z division review completed.
