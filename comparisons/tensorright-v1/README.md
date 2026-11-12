# Paper-era comparison: 48 checked cases

This is the first comparison checkpoint, not a full experiment or a fresh proof
search trial. The 118 rows in `cases.json` and `cases.md` correspond to the paper
artifact's executed main-suite rules. `build_cases.py` checks the recovered
inventory against each source file's actual `main` call order, aligns the 118
archived result blocks, and checks printed labels. One label (`reduce/rule03`)
had shell wildcard expansion in the archived output; its position is used and
that exception is explicit in the script. The 115 successes and three failed
solver results are author-provided archive results, not our rerun. The paper
reports the three as timeouts. Every row preserves the exact rule declaration,
source identity/hash, archived result block hash, types and current outcome.

Four Addition, three Subtraction and seven Multiplication rules have checked Lean
proofs over all finite tensor shapes, integers and exact reals. Each specializes
`ArithmeticFamily.rewrite_sound`; some paper operands are constant tensors while
the Lean results permit arbitrary same-shape tensor operands. Three Broadcast
rules and the remaining Multiplication rule use actual bounded Broadcast or
Reverse coordinate maps. One of the three Broadcast rules covers Boolean tensors
as well as the two numeric types. Eight Boolean And/Or rules and two double-negation
rules reuse the Boolean and exact-arithmetic theories. Six self-comparisons, three
order comparisons and three Clamp cases use the exact linear-order theory. Four
Select cases and four Reverse cases use actual tensor functions and coordinates.
Paper numeric input tensors are introduced via `linearMemory` as `nonInf` symbolic
integer/real values; constants in these numeric rules are also finite. Thus these
checks match that input scope, without claiming IEEE floating-point results or
proving correspondence to C++. Later rules can involve special numeric values;
do not extrapolate this observation to all 118 rules.

| Paper case | Lean result | Existing rule constructor |
| --- | --- | --- |
| `add/rule01` | reassociate | `addAssoc false false` |
| `add/rule02` | zero_right | `addZeroRight` |
| `add/rule03` | zero_left | `addZeroLeft` |
| `add/rule04` | commute | `addComm` |
| `sub/rule00–02` | subtract zero; subtract negation; self-subtract | `subZero`, `subNeg`, `subSelf` |
| `mul/rule01–06,08` | unit, zero, regrouping and factoring | `mulOne`, `mulZero`, `fourFactors`, `mulAssoc`, `factor` |
| `mul/rule07` | move a scalar factor through Broadcast | `broadcast_uniform_factor` |
| `broadcast/rule01,02` | Add and Multiply commute with Broadcast | actual Broadcast index projection |
| `broadcast/rule04` | reverse a constant tensor | actual Reverse index map |
| `logical/rule01–08` | Boolean identities with true/false | typed Boolean logical family |
| `not/rule01,02` | Boolean and exact-numeric double negation | Boolean and commutative-ring families |
| `compare/rule01–06` | six self-comparisons | linear-order graph theorem |
| `logical/rule09–11` | comparison with Min/Max | linear-order graph theorem |
| `clamp/rule01–03` | Clamp identities; ordered bounds where required | linear-order graph theorem and `paperClamp_eq` |
| `select/rule01–04` | Select identities | existing pure Select theory |
| `reverse/rule01–04` | unit axes, reversal composition, constant addition | bounded Reverse maps |

Reproduce from the repository root:

```sh
python3 comparisons/tensorright-v1/build_cases.py
lake env lean comparisons/tensorright-v1/Add.lean
lake env lean comparisons/tensorright-v1/ScalarArithmetic.lean
lake env lean comparisons/tensorright-v1/Broadcast.lean
lake env lean comparisons/tensorright-v1/Logical.lean
lake env lean comparisons/tensorright-v1/Comparisons.lean
lake env lean comparisons/tensorright-v1/Select.lean
lake env lean comparisons/tensorright-v1/Reverse.lean
python3 tools/lean_size.py comparisons/tensorright-v1/*.lean
```

All seven Lean commands passed with either no axioms or only the standard
`propext`, `Quot.sound` and `Classical.choice`; outputs are in the seven
`*-check.log` files. The comparison modules have 404 code lines total, including
48 axiom-print commands. They reuse
the existing mathematical development and Mathlib; 404 is not the independent
cost of these proofs. The earlier 12,341 custom Lean lines include unrelated work
and are not attributed wholesale to these cases. A precise shared-dependency cost
remains future measurement. No correspondence proof or new compiler pass investigation
was performed. These results reuse historical proofs and do not measure a fresh
LLM discovery rate. The other 70 rows have not yet been assessed in this comparison.

For `clamp/rule02`, the original strict inequality between bounds implies the
non-strict order needed by the proof; no extra restriction is imposed. The paper
Clamp computes `min upper (max value lower)`, while the existing Lean graph uses
the opposite Min operand order; `paperClamp_eq` proves these equal for exact
linear orders. For `select/rule04`, the original condition is the constant false;
the Lean proof applies to every predicate. For `reverse/rule03`, the three paper
aggregated-axis groups are disjoint; the Lean theorem explicitly takes that
well-formedness condition and proves the output axis mask, rather than assuming
that the masks coincide. These proofs do not apply the exact-order results to IEEE
NaNs, and do not establish implementation correspondence.
