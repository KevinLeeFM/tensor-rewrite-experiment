# Arbitrary-axis concatenation and selected Slice intervals

The model now proves ordered concatenation and Slice graph laws for arbitrary
finite operand lists, legal selected axes and static shapes. All other axes can
have arbitrary extents, including zero. Operand data can have any type; no
arithmetic, equality or default-value instance is required.

Eight retained records receive typed partial evidence: unary concatenation,
the three empty-filter branches, flattening nested same-axis concatenations,
and exact/single-group/multiple-group Slice intervals. This does not complete
the full Concatenate family or close any whole retained record.

## Coordinates, ordering and output shapes

A frame fixes the non-concatenated dimensions and names the selected axis.
Each operand carries its own selected extent in its tensor type. The output
extent is the actual sum of these extents. Reading an output coordinate tests
successive segment bounds and subtracts each preceding extent until it reaches
the contributing operand. Empty segments require no fabricated default data.

The proofs derive the selected coordinate and non-axis coordinate inverses,
the left/right append reads and full grouped-flattening read. Flattening changes
the operand grouping while retaining every value and its order. Unary
concatenation and zero-axis-extent filtering retain the derived output shape.
No desired index-map equality is a premise.

## Actual emptiness requires a distinct guard

Zero elements and zero extent on the selected axis are different predicates.
For example, concatenating shapes `(2,0)` and `(3,0)` on axis zero gives `(5,0)`.
Both operands are empty, but replacing the output by the first operand gives
shape `(2,0)`, and filtering both gives selected extent zero. Those are different
shapes despite the absence of data values.

One actually nonempty operand provides a bounded coordinate on every other axis.
The model derives from that witness that actual tensor emptiness is equivalent
to a zero selected extent. A nonempty filtered operand list therefore supplies
its own guard: filtering derives both equal output extents and equal tensor
values. The single-kept-operand branch returns the operand itself.

For the all-empty branch, `concatenate_all_empty_first_iff` proves a necessary
and sufficient condition: replacement by the first operand preserves shape and
values exactly when the complete output shape equals that operand's shape.
`shape_eq_iff` derives that this is exactly equality between the summed selected
extent and the first extent. All-empty values are unique at the original output
shape, but emptiness alone does not imply this shape condition. The two shape
refutations above are diagnostics of the independently reconstructed mathematical
profile; they do not establish that the external compiler admits either mutation.

## Legal Slice graphs

An actual bounded unit-stride Slice reads a contiguous interval on the selected
axis and retains every other dimension. A selected operand group is cropped
after removing the exact summed leading extent. Its Slice start/length and
output bounds are derived, including empty intervals and operands. Specializing
the selected group to one operand gives the contained-piece Slice; selecting
that whole interval gives the original operand.

These proofs do not yet merge adjacent Slice operands, derive the Pad graphs,
connect repeated unit-axis operands to ordinary Reshape/Broadcast, handle
non-unit strides, or crop the other dimensions. Those partitions remain open.

## Controls, size and replay

Forty-eight statements add 535 custom Lean lines: S69/H287/R147/A1/C31. Four are
refutations: the two empty-shape mutations, operand reordering and a missing
Slice prefix adjustment. Core totals are 651 theory statements, 911 ledger
declarations and 11,228 custom Lean lines. Complete declared family-profile units
remain 388; this extension is a partial model, not a new complete family.

Actual Lean and independent materialized Python arrays agree on 11,742 rows:
1512 profile headers, 5328 concatenation value rows, 4896 Slice rows and six
binary32 stored-encoding rows. Every axis at ranks one through three is exercised,
with empty dimensions, nullary and larger operand lists, zero segments, integer
and actual word8 data, and exceptional floating encodings. Four witnessed invalid
propositions are rejected normally. Generality comes from the quantified proofs;
these finite controls are development evidence rather than a held-out audit.

The new proofs reuse Std finite-index/List/Boolean/arithmetic support. Existing
OrderedCoordinates and FloatLib are used for development controls. There is no
new dependency, imported rewrite proof or controlled library-ablation result.
Operational fixture physical lines and non-Lean source are disclosed separately
from the primary Lean subtotal.

The [snapshot](../census/concatenation-v1.json) is finalized at its first Git commit
after development, rather than preregistered proof discovery. The
[domain worksheet](../census/concatenation-domains-v1.json) retains the mathematical
premises and remaining partitions; the
[checkpoint evidence](../reports/concatenation-milestone-v1.json) records validation.
Replay:

```sh
python3 tools/check_theory.py
python3 tools/check_concatenation.py
python3 tools/mathematical_ledger.py
python3 tools/workload_formulation_audit.py
```

All 488 IDs remain in scope, with 217 proposal-only worksheets. Whole-record
closure is zero and N/F is unfrozen. Remaining formulations/attempts, independent
statement review, residual interventions, matched comparisons and the final audit
remain required. Dynamic shape, finite machine attributes/overflow, physical
layout and execution observations need their own models. Code correspondence
remains future work.
