# Bounded reduction algebra and the retained reduction workload

The existing recursive axis plan specifies kept and reduced extents, ordered
fibers and an explicit reducer/initializer. The new reduced shape is derived from
that plan. Coordinate projection and merging are inverse in both directions,
including zero extents. No desired fiber correspondence is supplied as a premise.
The actual ordered fiber's sum is proved equal to the sum over those coordinates.

| Result | Required mathematical contract |
| --- | --- |
| Constant and/or | Boolean operation, nonempty fiber, actual initializer |
| Constant min/max | Linear order, nonempty fiber, actual initializer |
| Constant sum | AddMonoid; initializer plus fiber count times the value |
| Sum of negatives | AddCommGroup; zero initializer |
| Concatenate/regroup contiguous blocks | AddMonoid; neutral zero initializers; unchanged block order |
| Reduce all remaining axes after a reduction | AddCommMonoid; zero initializers; derived coordinate decomposition |
| Map through a reduction | Map preserves the operation and initializer; contribution order unchanged |
| Empty/equal-count tuple components | Whole-state pure reducer; actual initializer; left identity for equal-count elimination |

The tuple results allow coupled reducers. They project components after reducing
the whole function-valued state; componentwise independence is not assumed.
The coordinate-sum theorem retains an arbitrary initializer exactly once. The
sum-of-reduction theorem reduces all remaining axes; it is not a theorem about
arbitrary composition of two partial axis plans.

Three separate certificates show why assumptions cannot disappear. An empty
maximum fiber with initializer1 and constant9 returns1. Nested sums with
initializer7 on blocks[[1],[2]] produce24 rather than the flat fold's10. With a
zero initializer but operation(a,b)=2a+b, regrouping[[1,2],[3,4]] produces18
rather than26. These refute strengthened mathematical claims, not compiler code.

Exact additive structures are not instantiated for IEEE addition. Linear-order
min/max do not model floating NaNs or signed-zero policy. The homomorphism result
does not establish that a numerical conversion preserves a reducer operation.
Those observations and finite-width/precision domains remain explicit work.

## Whole-family formulation worksheet

`census/reduction-mathematical-domains-v2.json` retains all60 reduction records in
19 classification groups. Each group records a mathematical target, premises,
reusable evidence and concrete remaining partitions. These19 groups are not a
frozen family denominator, and the worksheet is not a complete formal statement
or proof attempt for every record. Retained source guards are not proof assumptions.

Remaining work includes bounded Broadcast/Concat/Transpose/Reshape adapters,
general partial-plan composition, Dot dimension transformations, coupled argmin/
argmax comparison and tie policy, window geometry and Pad/crop composition,
cumulative sample counts, numerical conversions and observation contracts. In a
unit window, an invalid sample may contribute the initializer; replacing that
with a padded initializer needs an explicit op(initial,initial)=initial law.

## Evidence and measurement

Run the mathematical checks, without native/source-correspondence tools:

```sh
python3 tools/check_theory.py
python3 tools/check_reduction_algebra.py
python3 tools/mathematical_ledger.py
python3 -m unittest discover -s tests -p test_reduction_algebra.py -v
```

There are27 new registered statements:11 support lemmas,13 positive/domain
results and3 counterexample certificates. New Lean is315 lines:
S35/H147/R114/A1/C18. The current custom total is4598, with
S1166/H1664/R1305/A78/C385. Imported Mathlib code is disclosed separately.
The theory/ledger counts become130/390, with four integration theorems separate.

Nine finite profiles produce20 output observations compared with an independent
full-grid/filtering integer oracle. They cover rank zero, no/all reduced axes,
nonadjacent axes, reduced unit axes, empty reduced fibers and empty outputs.
Observed fiber lists and merged coordinates agree, as do sums, negatives,
constant multiplicities and extrema. Lean proofs supply generality; the controls
check model meaning on selected instances. The IO fixture is excluded from the
primary count and reported by physical lines; its interpolated strings are
outside the lexical counter's supported primary-code language.

All38 focused mathematical accounting/integrity tests pass. Source and dependency
pins are in `census/reduction-algebra-v2.json`; results and validation transcripts
are under `reports/reduction-algebra*`. The27 new statements await independent
review, alongside the14 scalar-domain additions. The previous review covered
only the old89-statement foundation. All488 benchmark records remain:
390 unformulated,86 partial,12 carrying the declared logical-value family,
zero whole records closed. Mathematical N/F and the full verdict remain open.
Code correspondence is user-deferred future work.

The preserved v1 worksheet left commutativity implicit for broadcast-axis
reordering. Version2 makes that proposed domain explicit; all27 core Lean
statements and315 lines remain unchanged. The original inputs/results are
archived as a domain-metadata correction, not a false core theorem.
