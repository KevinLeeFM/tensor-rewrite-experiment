# From Boolean value laws to graph-context preservation

Baseline: Lean4.35.0, Std only. Source association: XLA
e58e523b11f1fde802a493a776d158007486e1bf, HandleAnd/Or/Xor/Not.
This is pure PRED dataflow evidence, not complete source acceptance.

## Model and actual transformation

TensorRewrite/Pilot/Dag.lean defines a finite acyclic graph in topological binding
order. A node is an external parameter or an opcode with a list of references to
already available values. Fin scope carries each reference bound, preventing a
forward reference or cycle in this syntax. A graph suffix ends at a root reference.
Repeated references share a previously computed value; they do not duplicate its
computation. Graph size and the available prefix are arbitrary finite naturals.

Operators have a pure partial interpretation Op -> List Value -> Option Value.
Missing parameters and invalid operator operand lists return none. There is no
default value that could make an invalid graph look successfully evaluated.
The generic theorem does not require any particular scalar or tensor model.

Program.mapInputs rewrites every free-prefix reference in a suffix, including
the root and operands of every later node. Its reference map is lifted through
each new binding, keeping that newly introduced zero reference unchanged while
remapping earlier references. dropRef maps the deleted node's zero reference
to the chosen existing operand and shifts the remaining prefix indices back.
This performs actual syntactic use redirection and node removal; it does not
just add an alias and assume that arbitrary contexts preserve equality.

DagLemmas.lean proves operand-renaming compatibility, environment/reference
lifting compatibility and evaluation preservation under arbitrary input maps.
Program.eval_delete_equal then proves: if a node successfully evaluates to the
value of an existing prefix reference, deleting that binding and redirecting all
its uses preserves the entire suffix's Option result. Program.eval_replace_equal
handles replacing an operation with another operation of the same partial value,
while retaining the result slot and every later reference.

The premise about a node's value is discharged by operation semantics and the
earlier tensor laws in each terminal Boolean theorem. It is not declared as an
axiom or inserted into the definition of correctness. Pure contexts may fail
for unrelated invalid operations; the equality preserves those failures as well.
Metadata, control edges, effects and nondeterministic relations are not encoded.

## Twelve operation-specific theorems

BooleanDag.lean gives explicit semantics for nullary Boolean constants, unary
Not and binary And/Or/Xor over arbitrary-rank, same-shape PRED tensors. Every
other arity is rejected. BooleanDagRules.lean connects the previously checked
tensor laws to structural graph transformations:

| Rule group | Model cases | Transformation |
| --- | ---: | --- |
| And with true/false at either input | 4 | Delete and redirect to the appropriate existing input |
| Or with true/false at either input | 4 | Delete and redirect to the appropriate existing input |
| Xor with false at either input | 2 | Delete and redirect to the other input |
| Xor with the same input reference twice | 1 | Replace operation by an explicit false-constant node |
| Not of an already negated value | 1 | Delete outer Not and redirect to the earlier original value |

The theorems quantify over arbitrary finite graph suffixes, prefix environments,
external input maps, rank and extents, including zero extents. Their source-case
associations are in census/pilot-value-proofs.json under graph_context; source
review packets retain each theorem's partition and pending status. They overlap
the existing twelve Boolean value cases, so they must NOT be added to the source
coverage numerator as twelve new independent rewrites.

The Xor self case covers a repeated reference. The source also has an Identical
instruction-equivalence branch with side-effect/layout/sharding checks. That
branch is not established by this theorem. Integer bitwise variants of the
same handlers likewise are not PRED graph results.

The Not theorem's prefix-value premise represents the earlier negation result;
typed graph extraction must establish it from the matched inner node. Similarly,
the constant-input premises need a source-to-meaning argument for IsAll and its
constant/broadcast/unwrapping behavior. None of these bridges is silently assumed
proved. The source replacement helper's shape/control/sharding/frontend-attribute
conditions and all metadata/effect observations remain separate obligations.

## Controls and trust boundary

DagControls.lean checks a graph with shared uses of a newly created Not result,
correct and deliberately wrong replacement targets, deletion of the root itself,
an unaffected earlier root, reference lifting across new bindings, wrong arity,
missing parameters, scalar tensors and a valid empty-tensor instantiation.
InvalidDag.lean attempts to justify redirecting And(true,false) to the true input;
the proof must fail with the expected rfl error and no unrelated fixture errors.

These controls supplement general proofs rather than replace them. They would
not justify universal redirection alone. The theorem dependency audit checks all
five new shared lemmas and twelve graph rules. Dependencies are only standard
propext/Quot.sound; no axiom about graphs, source matching or rewrite correctness
has been added. Every earlier theorem retains its previous axiom set.

The earlier Tensor and Boolean files were converted to the module system so the
new library modules can import them. Existing definitions, statements and value
behavior were retained. The module/exposure declarations count toward code size;
the earlier immutable snapshots preserve their prior forms and sizes.

## Lean burden and validation

| Category | Before | Current | Added |
| --- | ---: | ---: | ---: |
| S semantics | 161 | 225 | 64 |
| H shared proofs | 83 | 139 | 56 |
| R rule-specific proofs | 172 | 258 | 86 |
| A imports/checking | 10 | 12 | 2 |
| C counterexample certificates | 133 | 133 | 0 |
| Total | 559 | 767 | 208 |

New files contribute Dag40, BooleanDag22, DagLemmas56 and BooleanDagRules84 code
lines. Existing Tensor/Boolean module changes contribute two lines each, and
root imports two. Tests and the axiom audit remain separately measured. The
current development checks41 value rules,12 pure graph-context rules,16 support
lemmas and the earlier separately categorized refutations/witnesses. These counts
describe artifacts, not equivalent independent source obligations or model effort.

All33 tool/evidence tests and the integrated checkpoint pass. New scope controls
reject omitted/cross-mapped graph cases, promotion to full source acceptance,
dropping the PRED restriction or extending pointer-self to Identical equivalence.
No new native XLA pass run is claimed by this update.

snapshots/boolean-dag-pilot-v1.zip preserves the entire current Lean pilot and
accounting/control material. reports/boolean-dag-clean-replay.json records its
fresh-directory rebuild without .lake and matching sizes/axiom dependencies.
This is same-agent clean replay, not independent source review.

Accepted complete source rewrites remain0. The mathematical pure-graph layer is
now stronger than isolated value equality, but the diverse reviewed pilot still
needs indexing/layout/reduction/numerical/effect contracts. Full semantic census,
independent correspondence, complete campaign/diagnosis and final audit stay open.
