# Full-call discovery and supplementary effect reconciliation

Source pin: XLA e58e523b11f1fde802a493a776d158007486e1bf.
Target: xla/hlo/transforms/simplifiers/algebraic_simplifier.cc.
Pass SHA256: 1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f.

## Why replacement-site coverage did not finish the census

The earlier map binds all 339 executable lexical replacement-related sites to
487 overlapping provisional schemas. The legacy mutation vocabulary also records
959 syntactic calls and 436 assignment expressions. That vocabulary deliberately
filters names, and therefore misses APIs such as clear_sharding,
SetupDerivedInstruction, CopyOriginalValue, AddRecoveryComputation and
AddEmbeddedComputation. Several were already retained by manual case evidence;
they were not automatically reconciled against a complete call-expression list.

tools/full_call_inventory.py now records every call_expression in the same
error-free, byte-preserving syntax-only view. It produces 7,391 call expressions
across 161 function definitions and reconciles all 58 handler bodies with their
provisional schemas. All 959 earlier candidates occur in the full list. No
handler is call-free or missing a schema. These are syntax/coverage observations,
not a claim that every call mutates the graph or that every case is source-faithful.

Template calls use their terminal function identifier rather than a template
argument identifier. Eight callee expressions remain explicitly unresolved:
returned Shape-comparison functors and immediately invoked lambdas. Their source
bounds, bodies and syntactic contexts remain indexed; they are not dropped.

The inventory also attaches candidate same-name local definitions to 298 call
sites. At 113 sites there is more than one such candidate. It does NOT resolve
receiver types, overloads, virtual methods, function objects or callbacks. Every
candidate relation retains that uncertainty; a same-name function is not proof
that a call dispatches there. Header definitions and external helpers need their
own dependency contracts. Constructors and implicit C++ calls/writes still need
additional analysis. An error-free tree is not a typechecked translation unit.

Data: census/full-call-inventory.json. The original lexical and filtered syntax
inventories remain separate, so neither the earlier counts nor their meaning is
silently redefined.

## Source-inspected supplementary calls

tools/nonreplacement_effects.py records 49 calls outside the old vocabulary,
classified by inspected source/API behavior in census/nonreplacement-effects.json.

| Category | Call sites | Obligation relevance |
| --- | ---: | --- |
| Visitor traversal state | 1 | Reset traversal state; not a tensor write itself |
| Visitor changed flag | 19 | Change reporting/control flow; not an additional rewrite |
| Derived instruction metadata/hook | 13 | Sharding, metadata, result accuracy, frontend/backend attributes |
| Cached scalar-add computation | 1 | May create an embedded computation on cache miss |
| Local dimension-number value | 7 | Local protobuf/list mutation feeding later construction |
| Original-value projection | 2 | Remap metadata on the barrier and its projected operand |
| Recovery table/metadata | 2 | Module table and possibly instruction metadata mutations |
| Existing instruction sharding | 1 | Pad projection clears the original broadcast's sharding |
| Local shape layout | 1 | Modify a copied shape for subsequent construction |
| Embedded reducer computation | 2 | Add cloned computations to the module before replacement |

The 49 are not 49 additional independent rewrites. Many form part of already
mapped graph changes. Their record status is source-inspected, pending independent
semantic review. Case links currently enumerate possible schemas of the enclosing
owner and explicitly require exact branch/caller composition; an owner-wide link
does not assert that the effect occurs in every schema.

Eight source behavior contracts retain exact ranges/hashes. The module
implementation is additionally archived in sources/effects-contract-manifest.json;
other inspected headers/implementations are already pinned by existing manifests.

HloInstruction::SetupDerivedInstruction conditionally propagates sharding,
metadata, result accuracy, frontend attributes/statistics and backend config, and
removes the compute-type annotation. The visitor overload is a virtual hook whose
base implementation delegates to that method. A backend override is not justified
by the base implementation. Derived nodes can already have attributes, making
the conditional overwrite/clear behavior relevant.

The vector CopyOriginalValue overload prunes negative index-map entries, creates
a new OriginalValue object retaining call hierarchy, and copies compatible tuple
subtrees. In the barrier case the source and destination can be the same existing
instruction. It is not just a name copy on a new tensor node.

AddRecoveryComputation may return early for absent/synthetic original values,
create new instruction metadata, pass through identity arrays or insert recovery
table entries with placeholder names and recovery modules. Its callback can also
decline recovery. Broadcast's inserted-unit-axis elimination constructs a reshape
recovery computation, whereas identity-Transpose elimination registers the
default recovery relation. Their mathematical tensor-value identities do not
by themselves establish this metadata behavior.

AddEmbeddedComputation calls AddComputationInternal with non-entry and identifier-
uniquifying settings. The scalar Add cache is initialized in an inline header
helper, beyond the target .cc's function list. Its first use can add a module
computation. RunImpl constructs one visitor for the supplied module and reuses it
across that module's computations; ResetState resets visit/change state while the
type-keyed scalar Add cache remains with the visitor. A future formal contract
must reflect the actual lifetime and module ownership rather than assuming every
AddReduce has no module-level effect.

## Direct pointer writes and alias distinctions

All 15 assignment expressions whose target starts with dereference and contains
mutable_ have source-inspected binding classifications. This is a deliberately
limited syntactic slice of the 436 assignments, not exhaustive alias analysis.

Five write existing nodes: the barrier shape, Pad's original broadcast shape and
dimensions, and the original RNG shapes in Reshape/Transpose elimination. Eight
write newly constructed node shape/layout/padding attributes. Two copy contracting
lists into local DotDimensionNumbers. The evidence records which actual binding
establishes that distinction; naming a pointer new_x would not suffice.

Pad's existing broadcast is protected by its one-user guard and has shape,
dimension map, sharding and updated layout effects before later graph replacement.
New Slice/Concat/Dot shape/layout assignments belong to the construction obligations
of their caller cases. They are not writes to unrelated old operands merely
because they use mutable_shape(). Conversely, RNG shape mutation changes an old
node and cannot be treated as independent allocation.

The pinned operation semantics describe RNG by distributions with scalar
parameters and distinguish RngBitGenerator's explicit state interface. They do
not by themselves settle seeded/backend observations or all joint distribution
properties needed by the shape changes. The RNG obligations remain distribution/
state-refinement questions; no fixed-sample equality theorem is assumed or
counterexample claimed here.

## Checks and remaining work

All 32 tool/evidence tests and the integrated checkpoint pass. New controls catch
omitted formerly unindexed calls, template-name mistakes, unresolved overload or
virtual dispatch falsely promoted, detached handler call lists, lost macro
provenance, recovery-call omission, existing RNG mutation reclassified as a new
node, missing effect contracts and premature acceptance. Source bytes and all
existing numerical/shape/algebraic proof/native evidence remain checked.

No new native pass run or Lean code is added. Size remains S161/H83/R172/A10/C133,
total559, and accepted complete source rewrites remain0. The complete census still
needs the other calls, local/implicit writes, aliases, concrete guards, legal
type/shape/option profiles and exact caller/helper effects reconciled. The
provisional 487 schemas cannot yet be frozen as N. Independent correspondence,
the diverse pilot, complete campaign/diagnosis and final audit remain open.
