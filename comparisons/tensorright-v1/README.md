# Paper-era comparison: first four cases

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

Four Addition rules have a checked mathematical Lean proof over all finite tensor
shapes, integers and exact reals. Each is a direct specialization of the existing
`ArithmeticFamily.rewrite_sound` theorem; the paper restricts some operands to
constant tensors, while our result permits arbitrary tensors of the same shape.
Paper numeric input tensors are introduced via `linearMemory` as `nonInf` symbolic
integer/real values; constants in these four rules are also finite. Thus these
checks match that input scope, without claiming IEEE floating-point results or
proving correspondence to C++. Later rules can involve special numeric values;
do not extrapolate this observation to all 118 rules.

| Paper case | Lean result | Existing rule constructor |
| --- | --- | --- |
| `add/rule01` | reassociate | `addAssoc false false` |
| `add/rule02` | zero_right | `addZeroRight` |
| `add/rule03` | zero_left | `addZeroLeft` |
| `add/rule04` | commute | `addComm` |

Reproduce from the repository root:

```sh
python3 comparisons/tensorright-v1/build_cases.py
lake env lean comparisons/tensorright-v1/Add.lean
python3 tools/lean_size.py comparisons/tensorright-v1/Add.lean
```

The Lean command passed with only `propext` and `Quot.sound` dependencies; its
output is in `add-check.log`. The comparison module has 33 code lines, including
four axiom-print commands. It reuses the existing mathematical development and
Mathlib rather than rebuilding their cost; 33 is not an independent proof's total
burden. The previous 12,341 custom Lean lines include unrelated work and are not
attributed wholesale to these four cases. A precise shared-dependency cost remains
future measurement. No correspondence proof or new compiler pass investigation
was performed. These results reuse historical proofs and do not measure a fresh
LLM discovery rate. The other 114 rows have not yet been assessed in this comparison.
