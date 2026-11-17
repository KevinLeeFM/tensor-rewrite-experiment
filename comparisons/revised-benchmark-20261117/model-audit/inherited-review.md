# Independent review of inherited word and predicate rewrites

**Verdict.** Accepted 18 named mathematical rewrites across 30 retained source IDs in the declared-value-complete stratum. Six logical cases group all eligible Bool and word forms. Twelve arithmetic cases use fixed-width words. Each row in `inherited.json` gives the original and replacement calculations, common shape, value type, conditions and source IDs. Operand orientations do not add cases. Direct and broadcast representations of subtraction of a constant share one case, with a distinct theorem for the broadcast replacement. This is inherited proof reuse. These 18 must not be added to the historical paper totals as distinct discoveries.

**Reviewed baseline.** Working revision `5733c54e666f4ac5bb74279407ea3df9143be7ce`. The November 12 plan in `docs/experiment-plan.md` is byte-identical to revision `86cef93e98518f5b46f0ecde01efddf320ff88e5`. Inspected `sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc` at pinned XLA `e58e523b11f1fde802a493a776d158007486e1bf`, lines 930–939 and 999–1011 (Add), 1503–1546 (And), 2454–2526 (Subtract), 5183–5223 (Multiply), 5415–5424 (Negate) and 5436–5505 (Or/Xor). Matched source IDs against `outcome-ledger.json` in the parent directory and their theorem mappings in `census/pilot-value-proofs.json` and `census/modular-arithmetic-contract.json`.

**Interpretation.** The tensor shape is in the type of both sides. Extents, ranks and word widths are arbitrary natural numbers, including rank zero, empty extents and mathematical width zero. The word arithmetic is modulo 2^w for both signed and unsigned bit patterns. A matched literal is modeled by its tensor values. Repeated inputs denote the same mathematical value. In the XOR equal-input arm, source pointer identity or the source's side-effect-free Identical check motivate that value assumption. The proof does not decide graph equivalence. And/Or with true require predicates; integer one is not all bits set. The subtraction broadcast uses the same typed coordinate map to pull back the original constant and its negation. Source branches that require integral inputs or fast math use the integral arm here. Source matching, SSA identity, layout/sharding, backend effects, FP and success of replacement APIs are outside these declared models. Source association is interpretive. The two ordered operand mutations in Multiply/negated-operands are represented by the final product only.

**Deduplication and exclusions.** Source-ID sets in this packet are disjoint from structural.json, value.json and new.json. Double Not was already counted in value.json and was explicitly excluded from this packet. Only the source IDs listed in inherited.json were assessed. Factoring, reassociation, further constant handling, numerical types beyond the specified domains and remaining inherited families receive no new credit here. No claim of non-overlap with paper-era case identities without an explicit crosswalk.

**Custom import closure and replay.** Tensor imports Std, Indexing imports Tensor, Boolean and Bitwise import Tensor, and Subtract and ModularArithmetic import Indexing. I inspected the definitions and statements in those sources. Tensor is a bounded-index function, constants are uniform and map/map₂ operate pointwise. Indexing defines reindex by applying its argument map; it contains no subtraction or Boolean identity. Proofs use function extensionality and ordinary Bool/BitVec operations and laws. No proof edits. Serial compilation used `LEAN_PATH=<fresh-empty-output-root>` and `lean -o <root>/TensorRewrite/Pilot/<M>.olean TensorRewrite/Pilot/<M>.lean` from the checkout, in the order below. The only external artifacts used were installed Lean/Std 4.35.0 commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. No downloads, repository oleans, Mathlib, or native evaluation.

| Custom module | SHA-256 | Compile wall seconds |
|---|---|---:|
| TensorRewrite/Pilot/Tensor.lean | `c1b41d38bee3d55c4a63df7333c7f0d23ea5917e4260062e2efad97edbeab122` | 0.320 |
| TensorRewrite/Pilot/Indexing.lean | `73632c28e066f7651378c107bb7b9331b874138d6813d1571ed7386aaaa54c9c` | 0.271 |
| TensorRewrite/Pilot/Boolean.lean | `86676823db277fcf439e35f82c5ec14be68c187a1bfb7df9b8d3aba7a721f597` | 0.334 |
| TensorRewrite/Pilot/Bitwise.lean | `a67194ffaddce51a198ece69211cea307405f3f4a523c793eea394b238e7214f` | 0.348 |
| TensorRewrite/Pilot/Subtract.lean | `0e9dfef1b5a31220cba8f7a002c722cf7bf71caeae440e10af2e96090592aaf6` | 0.361 |
| TensorRewrite/Pilot/ModularArithmetic.lean | `9bcb99af74d03d7d4e877b9f319270e641e8fccf98c62816ccaea5a8835c2dd7` | 0.347 |

A separate fresh import checked four concrete propositions with kernel `decide` and printed all the axioms (0.338 s). A rank-one length-two tensor supplied the concrete 8-bit values 255 and 3. The checks included wraparound 255+1=0, 3−(3+1)=255, bitwise 3 AND 1 differs from 3 and true XOR true is false. Replacing the subtraction result with positive 1 was rejected (0.281 s), as was forwarding the whole word for 3 AND 1 (0.378 s). Both negative invocations exited 1 with an explicit proof that the well-typed proposition is false. All target declarations listed below depended exactly on `propext` and `Quot.sound`. The audit printed overlapping registry entries twice for nine modular declarations. The table lists each declaration once. The recorded cost includes those duplicate print commands in the single axiom harness.

| Case ID | Replayed declarations, under TensorRewrite.Pilot |
|---|---|
| and.zero | `Boolean.and_rhs_false`, `Boolean.and_lhs_false`, `Bitwise.and_rhs_zero`, `Bitwise.and_lhs_zero` |
| and.true | `Boolean.and_rhs_true`, `Boolean.and_lhs_true` |
| or.zero | `Boolean.or_rhs_false`, `Boolean.or_lhs_false`, `Bitwise.or_rhs_zero`, `Bitwise.or_lhs_zero` |
| or.true | `Boolean.or_rhs_true`, `Boolean.or_lhs_true` |
| xor.zero | `Boolean.xor_rhs_zero`, `Boolean.xor_lhs_zero`, `Bitwise.xor_rhs_zero`, `Bitwise.xor_lhs_zero` |
| xor.self | `Boolean.xor_self`, `Bitwise.xor_self` |
| word.add-zero | `ModularArithmetic.add_rhs_zero`, `ModularArithmetic.add_lhs_zero` |
| word.add-sub-cancel | `ModularArithmetic.add_sub_cancel_right`, `ModularArithmetic.add_sub_cancel_left` |
| word.mul-one | `ModularArithmetic.mul_rhs_one`, `ModularArithmetic.mul_lhs_one` |
| word.mul-zero | `ModularArithmetic.mul_rhs_zero`, `ModularArithmetic.mul_lhs_zero` |
| word.mul-neg-neg | `ModularArithmetic.mul_neg_neg` |
| word.negate-involution | `Subtract.neg_neg` |
| word.sub-self | `Subtract.sub_self` |
| word.sub-zero | `Subtract.sub_zero` |
| word.sub-constant | `Subtract.sub_eq_add_neg`, `Subtract.sub_broadcast_eq_add_neg` |
| word.sub-sub-self | `Subtract.sub_sub_self` |
| word.sub-add-self | `Subtract.sub_add_self_left`, `Subtract.sub_add_self_right` |
| word.add-sub-self | `Subtract.add_sub_self_left`, `Subtract.add_sub_self_right` |

**Effort.** Independent inspection and documentation window from 2026-11-17 23:50:37 UTC through 23:53:24 UTC, 167 s wall. Compiler/check commands totaled 2.978 s inside that window. Historical discovery, active reasoning and token usage per case are unknown. This reviewed inherited proof packet has zero new proof-source lines.
