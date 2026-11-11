# Select, heterogeneous Map and exact Conditional dispatch

Nineteen declared mathematical profiles now have complete kernel-checked proofs:
four Select identities over arbitrary data, ten Boolean Select identities,
four scalar-body Map graphs and one exact branch-dispatch conversion. These refine
nineteen retained proposal worksheets. They do not close whole retained records.

The proofs quantify over arbitrary finite ranks and extents, including scalars
and empty axes. Select requires no arithmetic, equality or order instance on its
data type. Consequently the same theorem applies to integers, arbitrary-width
words, complex values and stored floating encodings. Its comparison cases operate
on Boolean data only, with false encoded as zero and true as one. They do not
identify IEEE comparisons with a linear order.

## The actual graphs

`select_not` proves

```text
Select(Not(p), x, y) = Select(p, y, x).
```

The data tensors can have any element type. Boolean true/false and false/true
branches recover the predicate or its negation. Broadcast versions retain the
actual decoded dimension array and matching extents. They include the empty
dimension array for a rank-zero predicate. The value laws are stronger than
the increasing/injective-axis restriction: every bounded decoded projection
satisfies them, including that legal subset. No arbitrary desired map equality
is assumed.

The Map evaluator takes a dependent family of operand types and applies a pure
scalar body at each output coordinate. A parameter-root body returns its selected
tensor. Constant roots become a scalar constant or the actual rank-zero Broadcast.
An elementwise root becomes an ordinary elementwise operation with its original
ordered parameter selection. Finite arities can be zero, and parameters can be
unused or repeated. No commutativity, associativity or common operand type is
assumed.

Conditional has separate indexed and predicate dispatch definitions. Boolean
conversion sends false to branch zero and true to branch one. The proof preserves
the exact selected branch function and its own typed argument. Its result type
is arbitrary, so it also applies when a branch returns a state-to-observation
function. This is more information than a pointwise Select equation. External
branch conventions, exceptional/out-of-range admission, divergence and ambient
graph execution still require their own contracts.

## Observation boundaries and controls

Six refutations distinguish the proof domains from tempting mutations:

- Replacing greater-than Boolean selection by conjunction is false.
- Reordering operands of an ordinary subtraction body changes the value.
- Dropping a false Select branch can discard an eager execution event.
- Swapping Select branches can reorder their eager events.
- Removing operands of a constant-root Map can discard an event.
- Keeping the wrong Conditional branch order changes its trace even when both
  branches return seven.

The event examples use an explicit small eager expression model, not a claim
about the external compiler's admitted scheduling. They establish why pure-value
identities alone cannot authorize those execution transformations.

Development controls compare 137 actual Lean rows with an independent Python
oracle. They cover both axes of a rectangular Broadcast, scalar broadcasting,
noncommutative Map bodies with repeated selected parameters, heterogeneous
integer/Boolean inputs, both Conditional branches at multiple states, and actual
binary32 stored encodings for signed zeros, NaN payloads and infinities. One
empty-coordinate enumeration is also checked. The generality comes from the
proofs, not from those finite examples. Four witnessed invalid propositions fail
Lean's `decide` normally; parser errors are not accepted as false-goal rejection.
These are development controls rather than a held-out independent audit.

## Measurement and replay

The extension has 28 statements: 22 positive/support statements and six refutations.
It adds 196 custom Lean lines: S49/R115/A1/C31. Core totals are 603 theory
statements, 863 ledger declarations and 10,693 custom Lean lines. The nineteen
new universal graph profiles bring complete declared family-profile units to
388 across five families. Profile units are not whole benchmark cases, and their
generality differs from the separately enumerated dtype profiles in other families.

Existing project Broadcast indexing and Std Boolean/Fin/function-equality support
are reused. FloatLib supplies the stored-bit control values; the new arbitrary-data
Select proofs import no floating arithmetic laws. There is no new dependency,
imported rewrite solution or controlled library-ablation result. Test/control
fixture source is disclosed separately from the primary Lean subtotal.

The [snapshot](../census/control-values-family-v1.json) is the post-development
accepted artifact at its first Git commit, not a preregistered proof-discovery
trial. The [domain worksheet](../census/control-values-domains-v1.json) retains
every observation gap. The [checkpoint evidence](../reports/control-values-milestone-v1.json)
records validation and provenance. Replay from a pinned checkout:

```sh
python3 tools/check_theory.py
python3 tools/check_control_values.py
python3 tools/mathematical_ledger.py
python3 tools/workload_formulation_audit.py
```

All 488 retained IDs remain in the workload, with 225 still having only proposal
worksheets. Whole-record closure is zero, N/F is unfrozen, and independent review
of these statements is pending. Full formulation/attempts, residual diagnosis,
matched comparisons and the final independent audit remain open. Code
correspondence stays future work.
