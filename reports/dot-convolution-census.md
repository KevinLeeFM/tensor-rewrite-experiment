# Dot, convolution and completion of lexical replacement mapping

Source pin: e58e523b11f1fde802a493a776d158007486e1bf.
Target: xla/hlo/transforms/simplifiers/algebraic_simplifier.cc.
Data: census/dot-cases.json and census/convolution-cases.json.
Extractors: tools/extract_dot_cases.py and tools/extract_convolution_cases.py.

## Coverage and limits

The dot/shared-primitive batch adds 44 provisional schemas in ten methods,
binding 18 previously unmapped executable replacement-related sites. It includes
both ReplaceInstructionIfCompatible overloads and the unary bitcast primitive,
integer upcast/binary/downcast removal, HandleDot and its replacing helpers.
Fifteen local helper behavior contracts preserve graph-building dependencies,
dimension maps and base virtual implementations.

The convolution batch adds 31 provisional schemas in eight methods, binding the
remaining twelve sites. Four local helper behavior contracts and the exact pinned
external convolution operand swapper are retained. The external source/header
are archived with hashes in sources/convolution-contract-manifest.json.

The complete map now contains 487 schema bindings over 339 distinct executable
replacement-related sites, zero unmapped lexical replacement candidates, and
five syntax-confirmed function-declaration exclusions. These partition the 344
lexical replacement candidates. Caller, helper, branch and datatype schemas
overlap: neither 487 nor 339 is the semantic obligation denominator N.

This completes lexical replacement-site mapping only. The 959 candidate calls
and 436 assignment expressions remain pending semantic review; the inventory is
not an exhaustive typed C++ mutation analysis. Aliases, effects, implicit writes,
helper calls, guard/dataflow partitions, backend overrides, numerical permissions,
source-to-statement correspondence and independent reconciliation remain open.
Every handler still needs an accountable reviewed disposition. There is no full
source proof acceptance and no whole-file positive or negative verdict.

## Dot graph and scalar obligations

Dot empty handling precedes outer-product conversion; the outer-product branch
precedes the unreduced-sharding veto. Nested reassociation can return a distinct
stop-rewriting result when an outer contraction consumes an inner batch axis,
so a failed attempted reassociation is not always permission to run later paths.
The remaining helpers are attempted in source order and stop on success.

Unit-axis removal renumbers batch/contracting lists and may reshape the result;
the fallback replacement disables sharding preservation and relays control
dependencies. Removing input transposes can swap operands and operand precision
before adding an output transpose. Parameter movement follows any unary chain to
a Parameter, swaps dimension lists and precision entries, and explicitly changes
frontend/fusion-attribute handling. None of these classifications proves values.

Outer-product lowering normalizes batch/free/contracting order, casts operands to
the output type and broadcasts before plain Multiply. Strength reduction uses
an algorithm-specific virtual multiply hook, then accumulation in F32 for floating
outputs except F64, followed by the output conversion. The base precision gate
accepts ALG_UNSET and ALG_DOT_F32_F32_F32. The base CPU profitability hook requires
both operands to have only batch/contracting dimensions; other platforms accept
the one-sided structural check. Derived visitors require their own hook contracts.

Nested reassociation constructs both new dots with the OUTER dot's precision
configuration and result element type. The original inner configuration/type
therefore cannot be assumed preserved. Output-dimension maps and a corrective
transpose are part of the obligation; finite flop arithmetic determines the
profitability branch. No counterexample is asserted from this inspection alone.

Mirror-operation movement prioritizes an eligible lhs over rhs. Reverse moves
contracting axes while retaining other reversals. Zero Pad can become a Slice
on the other input while retaining residual padding. Broadcast-introduced
contracting axes can become an Add reduction. Cost checks may reject after
constructing auxiliary graph nodes. Zero/nonfinite arithmetic and reassociation
need independently grounded, case-specific numerical permissions.

Contracting-axis reorder moves a reshape/transpose chain onto a Constant using
inverse axis/shape maps and changes contraction order. Concat-dot distributes
over exact Constant slices and creates a left-associated sum of partial dots.
The helper named OptimizeDotOfGather actually matches DynamicSlice(Constant),
preserving the full contracting extent and selecting one free-axis element;
its replacement uses a full constant Dot and remapped original slice indices.
Dynamic index clamping and every precision/type field remain correspondence work.

The cast-removal helper distinguishes unsigned Divide/Remainder from the
Add/Subtract/Multiply cases; it requires same signedness, non-subbyte integral
types and value-preserving widening. The two compatibility overloads need distinct
source bounds even though their method names coincide. The generic validator now
keys owners by name AND bounds and rejects a site borrowed from another overload.

## Convolution paths and external effects

ScalarMultiplyReduction is called from HandleConvolution, despite its parameter
being named dot. It can remove multiple operand/user multiplications in DFS
loops before one final target write. The first two sites execute zero or more
times; the source-site group is not a fixed three-write execution trace. Constants
are extracted through double, collected/combined as native float and cast to the
BF16/F32 target. Shared nodes, repeated traversal and user rewrites need invariants.

The traversal whitelist includes Select and traverses its operand edges. It does
not locally require equal scalar multipliers on both branches. This suggests a
candidate failure investigation using branch-specific multipliers, but no native
replay or formal refutation for that candidate has yet been performed. Keep this
as a hypothesis; do not add an equal-multiplier premise to the source guard.

Subsequent result: reports/scalar-select-refutation.md records a passing isolated
exact-source replay with both predicate values and disabled-option controls, plus
the mathematical Lean refutation. The paragraph above records the hypothesis at
this census checkpoint; it is no longer untested.

Conv/Add/Multiply reordering has commutative matcher variants, a rank-one feature
multiplier and a Constant filter. It scales filter and bias separately before
cloning the Add. Input-pad folding composes nonnegative edges and allowed interior
padding into the window. Filter-pad folding permits interior dilation only, with
feature/edge exclusions. Numerical zeros, reversal and finite geometry matter.

CPU BF16 promotion is a continuing stage: an ineligible convolution becomes an
outer BF16 Convert around an F32 convolution, the caller pointer is rebound to
that F32 node, and the helper returns FALSE. Later simplifications then use the
new node. TRUE denotes local oneDNN compatibility and stops without promotion.
Treating the Boolean as a conventional changed flag would reverse these paths.

Convolution-to-Dot requires layout-sensitive mode, unit spatial kernel axes,
physical layout constraints, no stride/padding/base dilation and no grouping.
It uses bitcasts, so logical reshape equality alone cannot justify it. The
Multiply lowering instead requires layout-insensitive mode, restrictive feature/
spatial geometry and no rhs sparsity. It optionally reverses kernel axes,
converts inputs, broadcasts, multiplies and reduces at the OUTPUT type. It has
no local enable_conv_simplification check and no separate batch-group-one check;
these must not be silently added. Original precision configuration is not passed
to its plain Multiply/Reduce constructors.

SwapConvOperands delegates outside the target file. The inspected swapper rejects
grouping greater than one, sparsity and block scaling; exchanges roles/dilations,
recomputes padding, may reverse kernel axes and applies a profitability check.
It constructs a fresh PrecisionConfig containing swapped operand precision
entries, so other precision fields require review. A virtual lowerability veto
removes the constructed convolution; final replacement preserves sharding and
frontend attributes, relays control dependencies and removes unused operands.
That behavior belongs to the caller's source obligation despite the file boundary.

## Validation and next dependency

All 28 tool/evidence tests pass, as does the integrated checkpoint, including
Lean rebuild/axiom checks and archived native-evidence integrity checks. New
controls reject cross-overload site binding, lost virtual scope, missing loop
effects, lost promotion rebinding and missing/stale external delegation evidence.
The canonical C++ pass is unchanged. No new native XLA run is claimed here.

No Lean code was added: S148/H66/R172/A9/C106, total501. The 41 positive value
identities, nine support lemmas and separately accounted refutation certificates
remain evidence about their stated models; accepted complete source rewrites=0.

Next reconcile all handler and non-replacement effects, split the necessary type/
layout/precision/option contracts, review source correspondence and assemble the
diverse pilot before the scored complete campaign. Validate the Select/scalar
candidate with exact-source replay before treating it as a finding. The existing
nonfinite and empty-slice evidence does not replace those whole-workload gates.
