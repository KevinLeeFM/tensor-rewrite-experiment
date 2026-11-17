## Independent verdict

Accepted the three exact finite-word propositions frozen at fcb7128d9db1086c3b365ebdad92e3149c3477ad and proved at 8d3179c05f6d234e70c5781221ff561e4f26962a. All five freeze hashes matched. Only WordCompareProof.lean changed between those revisions. The 14 lexical IDs in census/arithmetic-cases.json map as follows (common prefix HandleCompare/).

| ID | Matched predicate | Replacement |
|---|---|---|
| unsigned-lt-zero | x < 0 | false |
| unsigned-ge-zero | x ≥ 0 | true |
| unsigned-zero-gt | 0 > x | false |
| unsigned-zero-le | 0 ≤ x | true |
| integral-self-lt | x < x | false |
| integral-self-le | x ≤ x | true |
| integral-self-gt | x > x | false |
| integral-self-ge | x ≥ x | true |
| integral-self-eq | x = x | true |
| integral-self-ne | x ≠ x | false |
| maximum-first | max(a,b) > a | b > a |
| maximum-second | max(a,b) > b | a > b |
| minimum-first | a > min(a,b) | a > b |
| minimum-second | b > min(a,b) | b > a |

I checked the actual predicates and mutations in algebraic_simplifier.cc:5913–5935,5949–5962,6020–6045. The matched pointer determines which operand is shared. Maximum on the left has priority over matching minimum on the right. Reusing a value or a key in the mathematics does not assert source pointer equality, matcher completeness or branch reachability. IsAll at lines 97–122 follows only a limited list of element-selecting operations to a constant and checks its literal. A zero-valued tensor need not be recognized. The same-shape observation is pointwise. Arbitrary widths include mathematical width zero outside XLA integral types. Empty indices give a unique tensor and the threshold iff still holds. Actual integral comparison uses the matching operand element type (hlo_evaluator.cc:1658–1686) and ordinary typed predicates (comparison_util.h:159–216); signed keys use two’s-complement toInt, unsigned keys use toNat, equality tests bits. Extrema are scalar pointwise ordered choices with the identical signedness on both sides. The four untyped source extrema records retain all nonintegral partitions as unresolved by this packet.

UnsignedBoundary proves a **joint** universal iff. Its reverse yields all four zero-threshold laws individually and its forward needs only the first test on the constant-zero input. Each individual law also distinguishes a nonzero threshold mathematically by testing input zero at any violating position, but four individually quantified converse theorems were not compiled. The iff concerns equality of tensor values, never IsAll recognizer success. OrderFamily.Rule.lhs/rhs/Condition and OrderFamilyProof.rewrite_sound already cover these self, zero and extrema orientations in an abstract exact order, with a nonnegative domain for zero comparisons. This packet specializes mathematical coverage to concrete signed/unsigned words and adds a variable-threshold characterization. Fourteen records share the work; they are not fourteen independent discoveries. No graph execution, floating comparison, graph effects or verified source correspondence.

## Fresh review checks and effort

I read the complete three local module sources. The import chain terminates at Std via Pilot.Tensor; OrderFamily is outside it. In a new temporary tree with only those local sources and an empty artifact directory, Lean 4.35.0 eb6cafb recompiled TensorRewrite/Pilot/Tensor, WordCompareSpec and WordCompareProof. The final run took 0.340, 0.369, 0.363 seconds respectively. Exact type annotations checked sameWord : Self, unsignedBoundary : UnsignedBoundary and extrema : Extreme; axiom sets were [propext, Classical.choice, Quot.sound], [propext, Quot.sound], and [propext, Quot.sound]. No placeholders, project axioms or native evaluation. Independent supplementary controls compiled in 0.375 seconds: rank-one extent two with distinct 8-bit values 0 and 128, signed versus unsigned minimum-GT and swapped direction, all four failed zero-threshold conclusions with threshold 128 and input 0, tensor self-NE false, and rejection of this nonconstant threshold. The first run also compiled all three modules (0.330, 0.427, 0.430 seconds); the supplementary harness failed (0.478 seconds) on unannotated Fin numeral instances. Explicit Fin 2 indices and a concrete nonzero contradiction repaired the harness. Reviewed inputs and proofs remained unchanged.

Review started 23:23:45 UTC on 2026-11-17. Successful replay finished 23:24:39. End including report writing recorded below. No native build or dependency installation. Active reasoning time and token cost unmetered.
Review end 2026-11-17T23:25:15Z.
