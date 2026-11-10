# Collective participation and finite-width indexing census

Source pin: e58e523b11f1fde802a493a776d158007486e1bf.
Data: census/collective-rotation-cases.json.
Extractor: tools/extract_collective_rotation_cases.py.

## Coverage and construction roles

The batch has 17 schemas across eight visitor handlers/helpers. It binds every
one of their 15 lexical replacement candidates, including both wrapper-only
collective handlers. Four of the candidates are nested calls to
CreateUniformCollectiveReplacement. That function constructs the argument for
ReplaceWithNewInstruction; its name is not evidence of another graph rewrite.
It can add a scalar node or assign a layout during construction, so this role
also does not assert that the factory is pure.

Each collective schema records graph_replacement versus
replacement_argument_construction roles. Source-coordinate order places the
containing replacement call before its nested factory text; it is not an
execution-order trace. The checker verifies exact call names, roles and byte
containment in the parsed syntax. Source-site bindings and review packets retain
those roles. A control that relabels the factory as a second graph replacement
is rejected, as is a detached factory range.

## Collective contracts that scalar identities miss

MatchUniformCollectiveOperand (:1340–1367) requires an array result, one operand,
no control dependencies, no async computation, no transitive Conditional caller
and no layout-sensitive host output. It matches a direct scalar constant,
broadcast scalar constant or nonempty literal whose values pass IsAllFirst.
The input matching forms are not assumed reachable for every legal collective
opcode/shape; final obligation splitting must reconcile reachability.

The conditional guard is motivated by distributed participation/deadlock, as
documented in IsInConditionalBranch (:1316–1338). A proof about constant output
values alone cannot justify removing a communication operation executed on only
some devices. Async, channels, device groups, communication/effect traces and
metadata remain part of the unreviewed observation boundary.

AllGather and AllToAll use the matched uniform value. The shared AllReduce/
ReduceScatter handler accepts MIN, MAX and SUM branches; the two concrete visitor
wrappers are recorded as delegations, not omitted because they have no local
replacement call. MIN/MAX reducer matching also includes PRED And/Or in the
external helper, and actual exceptional-value behavior remains to be specified.

SUM obtains a common participant count, then evaluates
`value * static_cast<T>(group_size)` in the selected native integral/floating
type and builds a new scalar literal. This is not automatically identical to
an arbitrarily associated distributed addition: group casts, signed C++
overflow, finite-width wrapping and floating rounding need separate review.
The source rejects unsupported/uninitialized literal results.

The replacement factory emits a scalar constant for eligible rank-zero/default-
memory results; otherwise it broadcasts a suitable reusable or newly constructed
scalar. Layout validity, scalar memory space and output shape are retained as
dependencies rather than erased by a uniform-tensor abstraction.

## Pinned external helper behavior

sources/collective-contract-manifest.json hashes the original implementations
from the same Git commit, checked against the existing isolated checkout:

- collective_ops_utils.cc:99–111 matches an effective-scalar root using exactly
  parameters0/1 in either order and classifies its reduction opcode/type;
- :483–552 computes participant counts from group modes, replica/partition counts
  and explicit or implicit groups;
- :555–578 returns iota device-list dimensions directly, otherwise requires all
  participant counts equal before returning the group count and size;
- shuffle.cc:33–36 normalizes a shift using signed remainders, adding dimension
  size before the second remainder, with a separate zero-size result.

These are source-behavior observations, not independently reviewed mathematical
contracts. Nonempty count-vector assumptions, configuration legality and finite
integer operations remain obligations.

## Remainder, rotation and broadcast users

Remainder extraction includes nested identical divisors, signed/unsigned
power-of-two masking, in-range Iota elimination and both Add operand orders of
the Iota-plus-divisor pattern. The Iota rules retain positive divisors,
FitsInIntegralType and OverflowSafeAdd conditions. The latter explicitly guards
overflow rather than assuming an unbounded-integer cancellation law. The
power-of-two helper retains modular negation of minimum signed values.

Rotate schemas accumulate shifts across a full Rotate chain, sort dimensions,
drop degenerate/splat/zero-shift axes and either remove or rebuild the operation.
The accumulation occurs in int64 before normalization; a mathematical modulo
identity alone does not prove absence of overflow or the correct rotation index
direction.

The broadcast-user helper can rewrite several eligible elementwise users in one
call. It clones each at a smaller shape, recreates the broadcast and replaces all
uses of that user. It does not replace the visited Broadcast node directly.
Caller option/layout conditions and graph-user coverage remain to be reconciled.

## Validation and limits

All 24 tool/evidence tests and the integrated checkpoint pass, including complete
selected-owner lexical coverage, helper hashes, nested-site role controls and all
previous Lean/native archives. No fresh native replay or Lean theorem is claimed
by this update. The source profiles, distributed semantics, full path census,
independent correspondence and whole-file campaign remain open. Lean size stays
501 lines, with zero accepted full-source rewrites.
