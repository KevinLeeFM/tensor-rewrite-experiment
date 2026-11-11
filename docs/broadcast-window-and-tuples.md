# Covered singleton windows and singleton tuple values

This mathematical milestone adds 36 checked statements in 636 custom Lean lines
(S160/H324/R119/A2/C31). It reuses the pinned Mathlib/FloatLib dependencies and
existing ordered window, finite-index, logical Reshape and Broadcast definitions.
No dependency or toolchain revision changes. The previous prefix packet and
window worksheets remain byte-for-byte preserved.

## The actual broadcast sequence

`BroadcastWindow.Plan` retains pointwise input axes and expands singleton input
axes. For an expansion with kernel extent K, stride S, low padding L and derived
output extent O, `Expansion.Covers` requires either O=0 or
`0 ≤ L ∧ L < K ∧ (O-1)*S ≤ L`. Kernel dilation is one; positive stride and base
dilation, signed padding and reversal remain explicit. The first/last inequalities
imply every output window includes the singleton input exactly once. Arbitrary
nonunit input axes must be pointwise; this model does not repeat blocks of
nonunit input data.

The proof derives the live kernel coordinate and its position in the original
ordered fold. All remaining contributions equal the actual padding value.
`reduce_sequence` proves equality with an independently constructed logical
Reshape followed by `IndexMaps.broadcastIndex` with signed axes. It derives the
compact shape, element count, valid ordered axis array and bounded coordinate
map; graph/sample equivalence is not a premise.

The reducer must satisfy both `op(initial,x)=x` and `op(x,initial)=x`, and implicit
padding must equal that initializer. Exactly one live contribution means no
associativity assumption is needed. Empty output tensors are included. The scalar
plan has one tensor element and one kernel contribution. A retained zero axis
makes the output empty. `reduce_converted_sequence` moves a pure input conversion
after the reshape/Broadcast using the result reducer's identity laws; it assumes
no general conversion/fold commutation.

For example, input `[5]`, kernel extent 2, low/high padding 1, base dilation 3,
unit stride and reversed kernel gives two output windows. Their ordered traces
are `[5,0]` and `[0,5]`. A reducer with zero as both identities returns `[5,5]`,
equal to reshape-to-scalar then Broadcast. A nonassociative unital reducer is
sufficient. Changing initializer/padding to 1 under addition gives 7 instead of
5, as a checked certificate demonstrates. A separate certificate shows a window
that misses the singleton input. Geometry and identity conditions matter.

## A closed singleton-tuple value family

`WindowTransport` proves state mapping across a reducer homomorphism with the
actual initializer and padding mapped too. An equivalence conjugates any pure
reducer; the singleton equivalence wraps a value as `Fin 1 → α` and unpacks
component zero. It does not discard another component of a coupled reducer.

`WindowTupleFamily` declares one typed rule. The source returns an outer singleton
tuple of component tensors from a whole-state ordered window reduction. The target
wraps a scalar reduction with the actual untupled reducer, initializer, padding and
input. `rewrite_sound` proves their equality at arbitrary modeled static ranks,
extents and window geometries, for every pure scalar type and reducer. It requires
no identity, associativity, nonempty-input or nonempty-output condition. The exact
rule enumeration has kernel-checked completeness and no-duplicate proofs.

This establishes **one complete declared pure-value profile**, alongside the
previous 20 predicate/word profiles. It does not establish the external tuple IR,
cloning API or effect/flag/layout semantics. A coupled two-component projection
counterexample guards against extending the singleton theorem by dropping state.
Independent statement review remains pending.

`WindowTupleFloat` instantiates actual FloatLib binary32 addition and proves stored
bit equality. It preserves fold order, initializer and padding even when they
are nonneutral. This universal theorem includes exceptional encodings. It does
not permit reassociation or observe exception flags. The terminal broadcast theorem
has separate identity premises; the tuple theorem supplies no unrestricted IEEE
identity law for it.

## Evidence and remaining claims

Run `python3 tools/check_theory.py`, then
`python3 tools/check_broadcast_window.py` and `python3 tools/mathematical_ledger.py`.
The focused suites and exact command logs are archived under
`reports/broadcast-window-validation-v1/`. The frozen inputs are
`census/broadcast-window-v1.json` and `census/window-tuple-family-v1.json`.

An independent occupied-coordinate oracle checks 3,780 raw axis configurations;
1,268 satisfy coverage. Nine mixed/scalar/empty profiles give 1,277 tensor profiles
and 440 outputs. The oracle filters coordinates rather than copying the first/last
inequalities, and builds a separate flatten/reshape/Broadcast target. Integer
controls use a nonassociative unital reducer; predicate controls use XOR.
Five tuple profiles give ten outputs, including empty kernels, empty outputs,
nontrivial initializer/padding and a nonidentity state equivalence `x ↦ x+1`.
Eight finite binary32 outputs agree with an exact rational rounding oracle and
exercise order, negative zero, subnormals, half-ulp rounding and empty initialization.
These finite controls are not an independent exceptional-input floating oracle.
The interpolated IO fixture's 147 physical lines are disclosed separately from
primary lexical source accounting.

Worksheet v4 retains the same 31 window records; 29 have core evidence. The direct
and converted **existing-operand** branches gain terminal broadcast associations.
The two **combined Pad/broadcast** branches remain without core associations:
Pad fusion still must imply the broadcast plan's coverage/pointwise conditions,
and actual graph composition and converted fills must be proved. Neither existing
fusion nor this terminal theorem silently supplies that composition.

Current totals are 300 theory statements, 560 ledger declarations and four separately
audited integration results; 7,065 custom Lean lines. Of 488 retained records,
361 need formulation/domain partition, 114 have partial evidence and 13 carry a
complete declared value family. Those are statuses, not proof-count coverage.
Whole-record closure remains zero; mathematical N/F and the workflow verdict remain
open. The original review inspected 89 statements; the later 211 still need review.
The full mathematical formulation, all-case attempts, residual interventions and
independent replay remain required. Code correspondence is future work.


The later [raw Pad/broadcast composition milestone](pad-broadcast-composition.md)
derives sufficient admission conditions and proves both combined direct/converted
value graphs. Worksheet v5 gives all31 window records core associations, while
numerical/domain/observation partitions and whole-record closure remain open.
This successor does not modify the narrower frozen evidence described above.
