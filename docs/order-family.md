# Exact order graphs across four scalar tracks

The order family checks 44 value/predicate rule, direction and operand-order
instances over exact integers, exact reals, unsigned words and signed words.
The two word tracks quantify every width, including zero. These are 176 complete
declared mathematical profile units, not 176 theorem bodies or a global workload
denominator. Forty-eight retained candidate records carry this family; their
remaining numerical, runtime, effect and physical partitions stay open.

The actual expression trees contain input sharing, Min/Max operand order, Clamp,
all six comparisons and Boolean conjunction. Whole-tensor result tags distinguish
value graphs from predicate graphs. The evaluator assumes no algebraic laws.
The proof interpretation supplies an actual linear order and a distinguished zero;
it does not assume that zero is the least value. Every tensor rank/extent is
arbitrary, with scalar and empty tensors admitted. Pure result contexts preserve
the checked equality; they do not supply effect or schedule observations.

## Explicit mathematical domains

| Rule group | Pointwise condition |
| --- | --- |
| Self/nested Min/Max, self comparisons, extrema comparisons, tautological bounds | None |
| Max with an extreme operand | The removed operand is at most the retained value |
| Min with an extreme operand | The retained value is at most the removed operand |
| Max(Min(...)) to Clamp; Max with lower Clamp bound | Lower bound is at most upper bound |
| Min(Max(...)) to Clamp; Clamp idempotence | None under the selected Clamp definition |
| Zero comparisons | Input is nonnegative |
| Clamp elimination for a value interval | Zero is at most input and input is at most upper bound |

Clamp is explicitly `min(max(value,lower),upper)`, including reversed bounds.
The alternative graph `max(lower,min(value,upper))` needs ordered bounds: at
lower=2, value=0, upper=1 the two graphs return two and one. That missing-premise
mutation has a kernel counterexample. Conditions are independently stated value
properties, not assumed consequences of retained source labels or optimizer guards.
`condition_admitted` proves the executable scalar admission test equivalent to
the declared tensor premise; the runtime controls therefore exercise the real domain.

Signed/unsigned wrappers hold actual BitVec bits. Injective lifts of `toInt` and
`toNat` supply distinct orders, and whole-word equality is preserved. Unsigned
nonnegativity is separately proved, so all four zero comparisons apply to every
unsigned tensor without a value-range premise. Concrete extreme-literal analysis
and finite runtime-ID/participant encodings are not derived here; Clamp interval
elimination uses its explicit mathematical range condition.

## Exceptional observations and controls

Four certificates expose reversed bounds, signedness (the same byte 255 orders
above zero unsigned and below it signed), actual binary32 quiet-NaN self Eq/Le/Ge,
and numerical equality of differently encoded signed zeros. The latter two use
FloatLib's actual configured comparison operations. There is no IEEE linear-order
assumption, selected floating Min/Max policy, NaN-domain closure or fast-math claim.
The checker also requires rejection of a default `LinearOrder Binary32` instance.

An independent Python tree/domain evaluator agrees with all 44 emitted expression
pairs and 13,332 integer/word value/admission rows. Of those, 11,603 satisfy the
mathematical domain and 1,729 are explicitly excluded. Every rule has an admitted
integer witness, and every nontrivial domain has an excluded integer witness.
Word widths zero through two exhaust all input triples; widths four/eight include
sign boundaries. The 176 profile rows and actual IEEE observation row are checked.
These are development controls, not independent held-out review. The two control
fixtures have 77 and 4 physical lines, outside primary LOC.

## Replay and burden

Run `python3 tools/check_theory.py`, `python3 tools/check_order_family.py`,
`python3 tools/mathematical_ledger.py` and `python3 tools/workload_formulation_audit.py`.
The immutable model, worksheet, controls, oracle and checker are pinned by
`census/order-values-family-v1.json`. Original failed finite-type derivation sources
and the build log are preserved in `snapshots/order-family-derive-failure-v1.zip`
and `reports/order-development-v1/`. The generated route failed with enum typing
errors and an IR compiler error in this dependency closure. Explicit constructor
coverage and computable stable keys remove that route without changing the
mathematical target or toolchain. It is a repaired infrastructure problem, not a
negative mathematical/workflow result. No controlled library ablation was performed.

Eighteen checked statements add 326 custom Lean lines: S207/H0/R95/A1/C23. Totals
are 534 theory statements, 794 ledger declarations and 10,098 custom Lean lines
(S2391/H3645/R3094/A97/C871), with four integration results separate. Mathlib order
reasoning, BitVec decoding and FloatLib comparison are reused at the existing pins;
all new expression semantics, wrappers and proofs enter the line count.

The four declared families now have 369 complete profile units. Catalog V6 retains
all 488 benchmark IDs, with 261 still only proposal worksheets. Record states are
269 needing formulation/domain work, 125 partial and 94 carrying value families.
Whole-record closure remains zero, N/F is unfrozen and the final workflow verdict
is unresolved. The 445 statements after the original reviewed 89 still await
independent review. Remaining monotone/transcendental, representation, effect and
physical partitions, full attempts/comparisons and final audit remain required.
Code correspondence stays deferred future work.
