# Tensor rewrite verification experiment

**Active scope:** mathematical tensor-rewrite proofs/refutations. Code-correspondence
tasks and proofs are user-deferred future work; see [scope](docs/theory-scope.md).
Historical source/native evidence is preserved and does not gate mathematical acceptance.
The current theory target is `TensorRewriteTheory`; run `python3 tools/check_theory.py`.
The theory target now has 422 checked mathematical statements; custom Lean totals **8,774**.
See `reports/theory-progress.json` for category counts, dependency reuse and axiom audits.
All488 retained records now have domain/dependency worksheets, including374 covered only by
unreviewed proposals after the six-record Scatter refinement; this is not completed formalization or proof acceptance. See [the proposal scope](docs/workload-formulation-proposals.md).


Independent Git/Lake project for tensor rewrite verification. The current proof
baseline uses pinned Mathlib and FloatLib dependencies; see [dependency setup](docs/dependencies.md).
Run `lake update`, `lake build`, then `python3 tools/check_libraries.py`.
Git remotes are local configuration; inspect them with `git remote -v`.
Historical Std-only proofs/evidence are retained.
The initial library-integration checkpoint had **2,796 custom Lean lines**: the historical 2,763
plus 33 integration lines (category A). Imported library code is listed separately.
See `reports/library-setup.json` for build and axiom-audit evidence.

Implementation/evidence workspace for the 2026-11-10 plan in `../notes/`.
Scheduling remains in `../notes/TODO.md`. The final research goal is active.

The initial dependency order is source/artifact freeze → discovery inventory →
reviewed case census and semantic dependency map → pilot definitions/proofs →
whole-file campaign. Measurement tooling runs alongside the census because it
does not depend on the tensor semantics. A discovery index is not a frozen N.

## Initial milestone status

| Milestone | Status | Evidence |
| --- | --- | --- |
| M0: establish workspace and immutable inputs | Complete | `sources/manifest.json`, offline hash verification |
| M1: recover historical implemented-rule inventory | Complete as static recovery | `census/historical-rules.json`: 118 main-suite invocations; reproduction and mapping remain open |
| M2: source discovery and initial case extraction | Every executable lexical replacement candidate mapped; semantic census in progress | `census/source-sites.json`, `census/site-case-map.json` |
| M3: initial source-size tool | Tested prototype | `tools/lean_size.py`; interpolation rejected; full accepted-language convention not frozen |
| M4: independently reconciled census and pilot semantic contract | All161 top-level function bodies read;all488 provisional local source records normalized; canonical census/semantic closure pending | No denominator or accepted source coverage claimed |

## Reproduce the initial checkpoint

Core tools use Python 3's standard library. Structural C++ discovery also uses
the pinned packages in `requirements-parser.txt`, installed into this workspace:

```sh
python3 -m pip install --no-cache-dir --target .parser-deps --report reports/parser-install.json -r requirements-parser.txt
```

The pinned locally installed toolchain is Lean
4.35.0; `lean --version` should report commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. The original checkpoint used Std only;
the current Mathlib and FloatLib pins are documented in `docs/dependencies.md`.

```sh
python3 tools/freeze_inputs.py --check
python3 tools/source_inventory.py
python3 tools/structural_inventory.py
python3 tools/artifact_inventory.py
python3 tools/extract_simple_cases.py
python3 tools/extract_shape_cases.py
python3 tools/extract_scalar_control_cases.py
python3 tools/extract_arithmetic_cases.py
python3 tools/extract_layout_cases.py
python3 tools/extract_collective_rotation_cases.py
python3 tools/extract_tensor_index_cases.py
python3 tools/extract_reduction_cases.py
python3 tools/extract_dot_cases.py
python3 tools/extract_convolution_cases.py
python3 tools/reconcile_sites.py
python3 tools/full_call_inventory.py
python3 tools/nonreplacement_effects.py
python3 tools/build_review_ledger.py
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -v
python3 tools/checkpoint.py
```

For a fresh workspace without `sources/manifest.json`, first run
`python3 tools/freeze_inputs.py` with network access. Snapshot files preserve
upstream licenses. Archived instructions are reference data; their Docker and
installation commands have not been executed. Generated protobuf headers and
transitive XLA dependencies are not a build closure. The historical solver
results included in the archive are author-provided evidence, not our rerun.

## Accounting and limits

The initial checkpoint contained no tensor proofs. A subsequent value pilot now
checks 48 value identities, twelve pure graph-context rules, one guard bridge and sixty support
lemmas; see `reports/pilot-values.json`. Graph rules overlap the value cases.
Source-rewrite acceptance remains zero pending graph/source-contract review.
The counter supports nested
comments, ordinary/raw strings, character literals and escaped identifiers;
unsupported interpolation fails explicitly. It measures lexical source lines,
not Lean syntax validity or proof acceptance. Before final use, expand compiler
cross-checks and pin the accepted syntax convention. All custom Lean automation,
definitions and proof dependencies must eventually enter S/H/R/A accounting.

Initial task provenance: one primary agent, model reported by session as
gpt-6.1-sol; no subagents, no human-supplied rule proofs. Source cases are
agent-extracted and await independent review. No scientific stopping ceiling
or maintainability threshold has been silently adopted. These are setup choices
before the scored campaign, not prerequisites for source archiving/discovery.

The simple-source extraction now contains 51 source schemas across 14
handlers/helpers in `census/simple-cases.json`, with inspected helper behavior
and unresolved contracts in `reports/simple-case-contracts.md`. These are
pending-review schemas with unsplit dtype variants, not a frozen denominator.

`census/shape-cases.json` now contains 58 anchored shape/indexing schemas. The additional
implementation files are pinned in `sources/dependency-supplement.json` and checked
by the checkpoint command. `reports/shape-contracts.md` records their implications.

`census/site-case-map.json` binds every extracted schema to an exact replacement
site or delegated helper call. Its mapped/residual partition covers the lexical
replacement inventory and is checked for omission/tampering. This remains a
primary-agent mapping, not independent semantic review or a complete census.

## First semantic pilot

Run `python3 tools/check_pilot.py` to rebuild the arbitrary-rank tensor value
model, check all value/index lemmas and their axiom dependencies, verify scalar,
empty and nontrivial-index controls and require rejection of false identities.
The historical Std-only pilot totals are S=776, H=926, R=691, A=33, C=337 code lines (2763 total including certificates);
test/audit lines are listed separately. The baseline is pinned Lean/Std only.
This extends the first Boolean/bitvector pilot with logical axis reversal,
mask composition, list-of-legal-axes triviality and shape-aware axis permutation.
Transpose identity/composition is checked with explicit inverse/extent witnesses;
a noncommuting-permutation control rejects the wrong composition order.
It does not complete the
diverse pilot or graph-level source guards. The graph/layout/type-admission tasks
remain open. First-checked Boolean/bitvector sources (85 lines) are preserved in
`snapshots/value-pilot-v1.zip`; later measurements count the added shared theory.

The source permutation-array adapter proves signed-axis decoding under explicit
range hypotheses and matches XLA permutation_util.h ComposePermutations
(`left[right[i]]`). This is a specification bridge; extraction, the imperative
C++ loop refinement and the graph-rewrite contract remain open.

The source-shaped append loop is now proved equal to the array specification
for all ranks in `PermutationLoopLemmas.lean`. `tools/check_native_permutation.py`
compiles the exact pinned template with documented dependency shims and tests
all permutation pairs through rank five; a swapped-index mutant must fail. This
does not formally verify the C++ implementation or a complete XLA pass.

## Structural census discovery

`census/structural-sites.json` adds enclosing function declarations, branch/loop/
lambda context and short-circuit prerequisites for candidate mutation calls.
A call within an if-condition is marked as condition evaluation, not as evidence
that the condition returned true. Lexical/structural differences are explicit.
XLA macros cause parse errors in the unpreprocessed source; error regions and
affected function owners remain flagged. This is not a typechecked C++ unit or
a completed semantic census. `reports/structural-discovery.md` explains the
remaining discrepancies and parser limits.

The byte-preserving syntax view in `tools/cpp_syntax_view.py` records every macro
or annotation adjustment separately. `census/normalized-structural-sites.json`
now parses the pinned file without grammar errors and recovers macro-contained
calls. Original source coordinates/text and unmodeled macro status/return
behavior are retained; a clean syntax parse does not close the semantic census.

Subtraction now has source-schema records for all six replacement sites, including
operand-order and direct/broadcast-constant variants. Integral-profile value laws
are checked at arbitrary width/shape; floating-point and graph obligations remain
open. Wrong-sign and modular-wraparound controls are part of the pilot checks.

## Real pinned-XLA nonfinite replay

The isolated source replay now reproduces the predicate-multiply NaN-to-zero
change with fast math disabled for positive/negative infinity and quiet NaN,
in both operand orders. `reports/xla-replay-v2/result.json` links archived source,
HLO graphs, successful test events/logs and binary identity. The first witness
is preserved separately in `reports/xla-replay-v1/`.

Run `python3 tools/check_xla_replay_evidence.py` to check the archive offline;
it does not execute a new pass run. Intended numerical-contract review and a
kernel-checked floating-point refutation remain open. A passing diagnostic test
here means the expected mismatch was observed, not that the rewrite is correct.

## Kernel-checked nonfinite refutation

`Float32Exceptional.lean` defines a necessary IEEE exceptional-output relation,
leaving finite arithmetic unconstrained. `PredMulRefutation.lean` rejects the
observed replacement for every infinity/NaN encoding and transfers rejection to
any stronger refining semantics. All certificate axiom reports are empty.
This is not a complete floating-point implementation or an unchecked solver call.

Refutation code is counted separately as C (certificate code), rather than added
to correctness-rule R. The report counts one refuted value target under an
explicit contract, alongside the existing positive value identities. Intended
optimizer-contract adoption and source/contract refinement remain open.

The latest replay (`reports/xla-replay-v3/result.json`) explicitly disables CPU
unsafe math and evaluator fast paths and asserts NaN/infinity honoring at runtime.
All six changes persist. `reports/numerical-contract-review.md` traces production
flag defaults and CPU-to-simplifier propagation; supporting sources are hashed
in `sources/numerical-contract-manifest.json`. This supports the chosen numerical
profile as a hypothesis to test; independent source/profile adjudication remains
open. The later arithmetic census shows why disabled fast math alone cannot
establish an exact whole-pass numerical contract: see the correction in
`reports/numerical-contract-review.md`.

## Numerical and control-flow source census

`census/scalar-control-cases.json` adds 55 pending-review schemas across 14
handlers. Every lexical replacement site in those handlers has a binding;
delegated conversions remain explicit helper obligations. Across all ten
batches there are 487 schema bindings covering all 339 distinct executable replacement-
related sites, with zero lexical replacement candidates unmapped and five AST-confirmed noncall
declarations in an explicit exclusion partition. These counts are discovery
accounting, not a rewrite denominator or accepted proof count.

`reports/scalar-control-census.md` explains the scalar-predicate, branch-order,
custom-call and numerical-contract splits. The checkpoint checks source/body/site
identity, selected-handler replacement coverage and false-acceptance controls.

## Empty-slice shape failures

The shape batch covers all 47 lexical replacement sites in its twelve handlers/
helpers, including the remaining Slice/Transpose paths. `reports/indexing-census.md`
explains which helper algorithms, layout contracts and user mutations remain to
be verified. All source acceptance remains pending.

`reports/empty-slice-replay-v2/result.json` archives two verified input modules
that the exact pinned pass rewrites into invalid modules: redundant-stride
removal and slice/reverse reordering both turn a zero-length slice into bounds
that infer one element while retaining the declared zero-element shape. A
nonempty stride control rewrites successfully and remains valid. This diagnostic
passes because it expects and checks the invalid outputs. It is not a Lean proof
or a passing correctness test for these rewrites.

`python3 tools/check_empty_slice_replay_evidence.py` verifies the archive offline.
For a fresh actual run with the prepared pinned checkout, choose an unused
numbered archive, for example:

```sh
python3 tools/run_empty_slice_replay.py --archive empty-slice-replay-v3
```

The first diagnostic, whose expected-invalid output also triggered a destruction-
time fixture check, remains preserved in `reports/empty-slice-replay-v1/`.

The shape failures now have kernel-checked certificates in `SliceShape.lean` and
`EmptySliceRefutation.lean`, with empty axiom dependencies. These establish legal
input bounds, exact transformed bounds and failure to preserve the retained
output extent. Controls distinguish truncating from Euclidean integer division
and admit valid nonempty transformations. Source extraction and the signed-int64
range bridge remain open; no whole-source acceptance is implied.

`reports/empty-slice-formal-refutation.md` describes the scope and code burden:
30 new model lines, 33 certificate lines and one import line. The first checked
development is preserved in `snapshots/empty-slice-certificates-v1.zip`.

## Addition, division and min/max census

`census/arithmetic-cases.json` has 85 pending-review schemas across Add, Divide,
Maximum, Minimum and Compare, covering all 64 lexical replacement sites in those handlers.
Five helper contracts have inspected source bounds/body hashes. Addition's
scatter transformations retain ordered groups of operand mutations and final
replacement, and the checker rejects silently reordered groups.

`reports/arithmetic-census.md` distinguishes source numerical permissions from
candidate mathematical specifications. No new Lean code or accepted source
rewrite is added by this extraction checkpoint.

## Layout stages and non-call writes

`census/layout-cases.json` adds 30 branch/stage schemas across seven handlers/
helpers, covering their 21 lexical replacement sites and eight inspected helper
contracts. Bitcast stages can rebind their current node and continue; barrier
pruning changes its operand/shape/metadata and user tuple indices. These stage
records still require composition into complete source obligations.

The structural inventory and review ledger now also retain 436 assignment
expressions, including local assignments and 28 that overlap explicit syntax
normalization. They are pending type/alias/path review, not 436 graph rewrites.
`reports/layout-census.md` records the exact scope and limitations. The integrated
checkpoint rejects omitted assignments, altered provenance and missing barrier
effects. Lean code size remains 501 lines.

## Collective participation, remainder, rotation and comparison

`census/collective-rotation-cases.json` adds 17 schemas across eight handlers/
helpers and binds 15 lexical replacement candidates. Collective factories are
explicitly labeled as argument construction within a containing replacement,
not extra graph rewrites or a sequential mutation trace. Wrapper delegation,
conditional/async exclusions, replica counts, host arithmetic and rotation
normalization remain visible. Supporting sources are pinned in
`sources/collective-contract-manifest.json`.

Compare adds 23 schemas to the arithmetic batch. `reports/compare-census.md` and
`reports/collective-rotation-census.md` explain the guards and remaining contracts.
All 24 tool/evidence tests and the integrated checkpoint pass. This update adds
source extraction, not accepted source proofs or new Lean code.

## Core tensor indexing and Gather

`census/tensor-index-cases.json` adds 56 source schemas across Concatenate,
Broadcast, Pad, DynamicSlice, DynamicUpdateSlice and Gather. It binds all 40
lexical replacement sites in those handlers. Dimension/index loops, clamping,
representability guards, Pad's auxiliary graph writes and effects on users are
retained explicitly. `mutable_operands()` is checked against the pinned header:
it returns a vector by value, so editing that temporary does not mutate graph edges.

`reports/tensor-index-census.md` describes the helper/shape/type boundaries and
the remaining source families. All 25 tool/evidence tests and the integrated
checkpoint pass; Lean code size remains 501 lines and source acceptance zero.

## Reductions and window geometry

`census/reduction-cases.json` adds 60 schemas across Reduce, ReduceWindow and four
rewrite helpers, binding all 34 executable replacement-related calls in that
scope. Reducer construction is distinguished from graph replacement; local
replacement lambdas retain their caller guards. Eight inspected helper contracts
include the actual extrema matchers, whose names also cover native limits for
formats without infinity.

The pinned operation documentation in `sources/reduction-contract-manifest.json`
requires identity initial values and allows reassociation. Those statements need
precise formal domains/observation relations; they do not make every floating
rewrite an exact equation. `reports/reduction-census.md` records the scope, status
handling and remaining semantics. All 26 tool/evidence tests and the integrated
checkpoint pass, with Lean size unchanged at 501 lines.

## Dot, convolution and lexical mapping completion

`census/dot-cases.json` adds 44 schemas covering dot transformations and shared
replacement/cast primitives. `census/convolution-cases.json` adds 31 schemas
covering convolution stages, scalar-movement loops and delegated operand swapping.
Every one of the 339 executable lexical replacement candidates now has a binding;
five declaration-only candidates are separately justified. The 487 overlapping
schemas are not a frozen obligation denominator. Non-replacement effects and all
source mappings still require semantic reconciliation and independent review.

`reports/dot-convolution-census.md` records dimension maps, precision/virtual-hook
boundaries, continuing F32 promotion, loop multiplicity and the initial scalar/
Select hypothesis. Two external swapper sources are pinned in
`sources/convolution-contract-manifest.json`. All 28 tool/evidence tests and the
integrated checkpoint passed at that mapping checkpoint with 501 Lean lines;
the subsequent scalar/Select certificate raises the current total to559.
Full-source acceptance remains zero. Next: complete semantic/path/effect reconciliation and the reviewed
diverse pilot, then execute the complete campaign and final audit.

## Finite scalar movement across Select

`reports/scalar-select-replay-v2/result.json` archives a fresh exact-source XLA
replay: Select branches scale an all-one convolution input by2 or3. With scalar
movement enabled, both scales are removed and their product6 moves to the output,
changing true8->24 and false12->24. Disabled-option controls remain unchanged;
all modules verify. The isolated test uses layout-sensitive mode and disables
other convolution rewrites. The initial failed diagnostic is retained as v1.

`reports/scalar-select-refutation.md` separates that native F32 observation from
the new exact-integer Lean contraction model. A general nonzero-sum refutation,
both concrete witness values and the failure of universal identity check. The
concrete and universal certificates have empty axiom dependencies; the stronger
general theorem uses only explicitly audited standard propext/Quot.sound.
No binary32/C++ source correspondence theorem is claimed.

The complete Lean pilot replays from `snapshots/scalar-select-certificates-v1.zip`
in a fresh directory without build caches, reproducing its559-line measurement
and axiom dependencies. The integrated checkpoint and all29 tool/evidence tests
pass, including controls against omitted disabled observations and false equality
claims. Full source acceptance stays zero; the complete campaign remains open.

## Calls and effects beyond replacement names

`census/full-call-inventory.json` adds all7,391 syntactic call expressions in161
function definitions, retaining all959 earlier candidates and reconciling all58
handlers with their provisional schemas. Eight indirect callee expressions stay
explicitly unresolved; local same-name definitions are dispatch candidates only.
This covers syntactic calls, not every C++ mutation or implicit operation.
That artifact remains syntax-only. A separate compiler-backed inventory now
resolves its static callees as described in the typed-census section below.

`census/nonreplacement-effects.json` classifies49 additional metadata, module,
visitor-state and local-value calls and all15 direct mutable-pointer assignments
in its selected scope. Existing RNG/barrier/broadcast writes are distinguished
from newly constructed node attributes and local dimension values. Source behavior
contracts include metadata copying, original-value recovery and embedded reducers.
`reports/full-call-effect-reconciliation.md` records the evidence and remaining
alias/path/profile work. All32 tool/evidence tests and the integrated checkpoint
pass; Lean remains559 lines and complete source acceptance remains zero.

## Shared graph contexts for PRED rules

`TensorRewrite/Pilot/Dag.lean` models arbitrary finite acyclic dataflow graphs
with bounded prefix references, explicit sharing/root references and partial
operator semantics. Its proved reference transformation deletes a node and
redirects every later use while preserving newly bound references. The companion
lemmas establish context preservation from a checked local value law.

Twelve Boolean rules now use this graph layer for arbitrary same-shape PRED
tensors and arbitrary graph suffixes. `reports/boolean-dag-contexts.md` explains
their source partitions, IsAll/matcher/replacement-API bridges still pending,
controls and all208 added Lean lines. The current total is767; full source
acceptance remains zero. Metadata/control/effects and the source Identical branch
are not established by the pure graph model.

All33 tool/evidence tests and the integrated checkpoint pass. The complete pilot
also replays without build caches from `snapshots/boolean-dag-pilot-v1.zip`,
with matching axiom and size outputs in `reports/boolean-dag-clean-replay.json`.
Earlier axiom sets are unchanged. Next: connect source guards/typed observations
and build the diverse reviewed pilot across the remaining semantic families.

## PRED constant-recognition bridge

`ConstantGuard` proves that its finite literal check and seven recognized index
wrappers imply a constant tensor. `GuardedBooleanDag` uses that guard to justify
an existing And graph rewrite. `reports/pred-constant-guard.md` separates this
abstraction from the C++ storage/layout/attribute translation still pending.

`reports/pred-guard-replay-v1/result.json` archives ten unchanged real-HandleAnd
checks and literal boundary tests. These direct calls preserve wrapper producers;
the record explicitly does not claim a full pass traversal. All34 tool/evidence
tests and the integrated checkpoint pass. The full Lean pilot replays from
`snapshots/pred-guard-pilot-v1.zip` without caches, matching its863-line measurement
and axiom audit. Complete source acceptance remains zero.

## Concrete static index maps

`IndexMaps` constructs Broadcast and Slice coordinate maps from checked attributes;
`SliceIndexBounds` derives static Slice bounds from the inferred output count.
The guard views now use these concrete maps. `reports/concrete-static-index-maps.md`
records HLO/client Broadcast distinctions and the remaining finite-arithmetic,
dynamic-shape and storage/layout translation gaps.

Nonuniform Lean coordinate probes agree with four pinned native operator tests in
`reports/index-map-evaluator-v1/result.json`. This archive executes the evaluator,
not a rewrite. All35 tool/evidence tests and the integrated checkpoint pass. The
958-line Lean pilot replays without caches from
`snapshots/static-index-maps-pilot-v1.zip`, matching axioms and coordinate outputs.
Full source acceptance and the whole-workload verdict remain open.

## Bounded DynamicSlice and index-oracle profiles

`DynamicIndex` constructs clamped coordinate maps with derived bounds and
connects them to recognized constant views. Signed and unsigned finite-word
decoding remain explicit. `reports/dynamic-slice-index-profiles.md` records the
source contracts and a native evaluator boundary:18 of20 tested index inputs
agree with logical clamping, while high-bit u64 starts select the lower edge
after signed conversion instead of the logical upper edge. This operator-only
diagnostic is separate from simplifier rewrite counterexamples.

Three empty-axiom Lean certificates establish disagreement between the two
index interpretations. They enter C accounting separately from rewrite-related
refutation counts. All36 tool/evidence tests and the integrated checkpoint pass.
The1059-line pilot replays without caches from
`snapshots/dynamic-index-pilot-v1.zip`, matching size, dependencies and index
probes; see `reports/dynamic-index-clean-replay.json`. Source/backend index
contract reconciliation and independent correspondence review remain open.

## Nested DynamicSlice composition

One additional mathematical-track rule proves nested slice composition for
arbitrary finite rank, bounded static extents and element type. Its three shared
support lemmas derive combined-start bounds and coordinate-map equality.
`reports/nested-dynamic-slice-composition.md` records the exact source guards.

The native full-pass replay in `reports/nested-slice-replay-v2` reproduces five
evaluator-relative value changes among eight rewritten cases, with eight no-pass
controls. Typed HLO clamps and the original DynamicSlice evaluator interpret
high-bit u64 starts differently. Four separately counted Lean certificates
establish the concrete evaluator-profile differences; they do not establish a
production backend contract. The general logical proof remains valid.

All37 tool/evidence tests and the integrated checkpoint pass. The1169-line pilot
replays without caches from `snapshots/nested-slice-pilot-v1.zip`; the replay
report preserves its hash and matches measurement, axiom and index diagnostics.
Source-review entries retain null accepted proofs while linking both profiles.

## Logical reshape and linear positions

`FiniteProduct` and `LinearIndex` now provide total row-major packing/unpacking
with both inverse laws for arbitrary finite rank and natural extents. `Reshape`
uses those maps across equal-count shapes, including scalars and empty tensors,
and supplies the concrete map to constant recognition. Three additional value
rules prove identity, composition and empty-output replacement.

`reports/logical-reshape-linearization.md` records source meanings, hypotheses
and remaining finite-arithmetic/dynamic/layout/graph translation boundaries.
The native archive `reports/reshape-replay-v3` separates five direct-handler
checks, five full-pass checks and five no-rewrite controls. Logical output
coordinates agree for nonuniform row/column layout cases and scalar/empty
boundaries. Full traversal's bitcast results are distinguished from direct
reshape-handler composition; physical bitcast correctness remains unproved.

All38 tool/evidence tests and the integrated checkpoint pass. The1358-line
pilot replays without caches from `snapshots/reshape-pilot-v1.zip`, matching
measurement, axioms and coordinate probes in `reports/reshape-clean-replay.json`.
Source acceptance remains zero; the diverse reviewed pilot and final verdict
remain open.

## Static reduction fibers and initializer laws

`Reduction.Plan` constructs arbitrary-rank kept/reduced shapes and ordered
coordinate fibers. General count proofs derive singleton fibers from equal
nonempty counts and treat zero dimensions separately. Three new value rules
prove empty-input/output initializer broadcasts and same-count reshape with
the actual initializer's identity law explicit.

`reports/static-reduction-fibers.md` records the contract and remaining source,
layout, reassociation and tuple/effect boundaries. The native archive
`reports/reduction-replay-v1` contains seven direct-handler, seven full-pass
and seven no-rewrite runs. Lawful Boolean examples agree with Lean; a well-typed
nonidentity initializer changes values outside the documented semantic domain
and is retained as a domain control, not a source counterexample.

All39 tool/evidence tests and the integrated checkpoint pass. The1572-line
pilot replays without caches from `snapshots/reduction-pilot-v1.zip`, with
matching measurements, axioms and probes in `reports/reduction-clean-replay.json`.
Independent source correspondence, the full campaign and final verdict remain open.

## Typed calls and schema delegations

The real pinned C++ compile action now produces an archived Clang22.1.8 AST.
`census/typed-call-inventory.json` represents all161 source functions and matches
7105 of7391 syntactic sites by exact source range and owner. All113 ambiguous
local-name candidate sets have selected declarations:110 local definitions and
three external IsAll members. Eight formerly unnamed functor/lambda calls select
operator(). Explicit casts are distinguished from calls;286 unmatched macro
invocations and25 dependent template sites remain explicit.

`census/typed-delegation-evidence.json` links all35 extracted delegation schemas
to compiler-selected local helpers and scoped pending model results. The typed
inventory's292 local dependency edges are static declarations, not closed runtime
dispatch or semantic effect proofs. `reports/typed-call-and-delegation-census.md`
records compiler/header provenance, residuals, controls and remaining obligations.

All45 tool/evidence tests and the integrated checkpoint pass. Lean development
stays1572 lines; six new auxiliary Python scripts are measured separately.
`snapshots/typed-call-census-v1.zip` replays typed evidence in a fresh directory
without build caches, as recorded in `reports/typed-call-clean-replay.json`.
This replays compiler output, not C++ compilation or independent source review.
The denominator and complete source acceptance remain open.

## Dense physical layouts and transpose bitcasts

`DenseLayout` derives physical cell addresses from legal minor-to-major
permutations, with coordinate and buffer read/write inverses. The source's
permutation-composition guard implies transpose/bitcast equality for arbitrary
finite rank in the static untiled same-cell-type profile. Source byte formats,
packing, tiles, memory spaces and graph observations remain separate obligations.

`reports/dense-layout-transpose-bitcast.md` records fifteen dense native runs
with compatible/incompatible layouts, a layout-insensitive control and a rank3
cycle. A separate direct-handler tiled diagnostic changes a verified transpose
into a bitcast rejected by the explicit ArraySize verifier policy. It does not
evaluate tiled values or establish an adopted backend failure/Lean refutation.

All46 tool/evidence tests and the integrated checkpoint pass. The1775-line
development replays without caches from `snapshots/dense-layout-pilot-v1.zip`,
matching size, axiom sets and probes in `reports/dense-layout-clean-replay.json`.
Every prior theorem axiom set is preserved after exposing four legacy modules.
Full source acceptance and the whole-file verdict remain open.


## Effectful fixed schedules and control-order diagnostic

Twelve Boolean rules now preserve complete state/error outcomes in arbitrary
external contexts under one fixed DAG schedule. A separate native replay shows
that forwarding And(A,false) with a control successor B can remove the path
requiring A before B. The native schedule verifier admits B,A after the rewrite;
synchronous custom-call callbacks execute that order with equal root values.
Explicit-predecessor, identity, unordered-input and no-rewrite controls delimit
the finding. Seven Lean certificates prove the finite prerequisite-order witness.
These are distinct from a source extraction theorem or compiled backend result.

All47 tool/evidence tests and the integrated checkpoint pass. The2086-line
custom Lean development replays without caches from
`snapshots/effectful-graph-pilot-v1.zip`; prior axiom sets are preserved.
See `reports/effectful-graph-and-control-order.md`,
`reports/effectful-graph-clean-replay.json`, and
`census/effectful-graph-contract.json`. Source acceptance remains zero;
all-schedule observations, API/frame effects, independent census/pilot review
and the whole-file campaign/final verdict remain open.


## Boolean-family discarded-prerequisite diagnosis

All twelve scalar PRED pilot branches now have native source-linked ordering
witnesses, including identities whose discarded constants carry control
prerequisites. A144-run matrix checks no-rewrite/direct-handler/full-pass modes
and a test-only added control edge, with old-node-predecessor and already-
unordered controls. The pointer-self Xor path differs from the helper-guarded
eleven cases. Both effects survive; equal root values accompany newly admissible
reverse callback traces. This is not a compiled backend or production fix claim.

Two generic prerequisite-extension lemmas and five diagnostic-repair certificates
bring custom Lean to2127 lines (test/audit sizes separate). All48 tool/evidence
tests and the integrated checkpoint pass. Fresh proof replay from
`snapshots/boolean-control-family-pilot-v1.zip` preserves prior axiom sets.
Review packets carry the scoped proofs and diagnostic with null source acceptance.
See `reports/boolean-family-control-diagnosis.md`,
`reports/boolean-control-family-clean-replay.json`, and
`census/boolean-control-family-contract.json`. The next broad census work is
replacement API/control classification; the whole research verdict remains open.


## Whole-schema replacement API paths and skip outcomes

All487 provisional schemas now link to typed static API sites or explicit
external/construction boundaries:285 sites and529 witness chains over the
selected local call graph. The catalog separates visitor overloads, low-level
rewires and argument defaults. Of125 new-instruction replacements,120 use
relay=false by default and five explicitly relay=true. Guard/status/alias
composition and external effects remain open; this is not a frozen semantic N.

A native scalar Add canonicalization replay shows insertion before a skipped
controlled replacement: the old root remains, the optimized visitor reports
change, and unused new nodes accumulate. Three single passes add one node each;
fixed-point mode reaches the actual50-run cap with50 added nodes. No-control
and no-rewrite controls isolate the behavior; all values/graph verifiers agree.
The report makes no unbounded-nontermination or Lean-refutation claim.

All51 tool/evidence tests and the checkpoint pass. Offline fresh-directory
replay from `snapshots/replacement-api-census-v1.zip` rebuilds the path inventory
and validates the archived native evidence. It does not rebuild Clang/XLA.
Lean sources remain byte-identical to the prior clean2127-line snapshot;
non-Lean tooling is measured separately. See
`reports/replacement-api-census-and-status.md`,
`reports/replacement-api-offline-replay.json`, and
`census/replacement-api-paths.json`. Source acceptance remains zero; semantic
partition/source review and the whole-file campaign/final verdict remain open.


## Modular Add/Multiply numerical pilot

Sixteen general finite-word tensor laws now cover identities, reassociation,
cancellation, negated products and factoring at arbitrary finite rank/extents/
width, without no-overflow premises. Eight displayed source recipes have72
native u8/u32/u64 runs over nonuniform overflow vectors, with handler/pass/no-
rewrite controls. Native values, Lean tensor expressions and an independent
integer-modulo reference agree. A false unbounded-Nat decoding claim is rejected.
Floating/complex, signed-source representation, AnyOrder/broadcast construction,
helper guards and graph/API correspondence remain open.

All52 tool/evidence tests and the checkpoint pass. The2198-line custom Lean
artifact replays without caches from `snapshots/modular-arithmetic-pilot-v2.zip`,
with prior axiom sets preserved. There are64 value laws; these are not source
acceptance counts. See `reports/modular-arithmetic-pilot.md`,
`reports/modular-arithmetic-clean-replay-v2.json`, and
`census/modular-arithmetic-contract.json`. The diverse reviewed pilot, semantic
census and whole-file campaign/verdict are still incomplete.


## Modular operand-order and Broadcast bridges

Seven general bridges now cover captured Multiply orientations, all shared-
factor positions and scalar-factor/constant gathering through concrete checked
Broadcast axes. A261-run native u8/u32/u64 matrix checks29 recipes per dtype in
handler/pass/no-rewrite modes, including two guard controls. All87 Lean model
vectors match native/modulo-index references; a wrong legal-axis claim is rejected.
These are logical-value bridges. Actual matcher/literal/type and graph/API/frame
correspondence remains pending independent review, not a required verified C++
extractor. No source acceptance is inferred.

All53 tool/evidence tests and the checkpoint pass. The2299-line development
replays without caches from `snapshots/modular-bridge-pilot-v1.zip`; prior axiom
sets remain unchanged. There are71 value laws and72 support lemmas, with tests/
audits and non-Lean tooling measured separately. See
`reports/modular-operand-order-and-broadcast.md`,
`reports/modular-bridge-clean-replay.json`, and
`census/modular-bridge-contract.json`. The whole-file campaign/verdict remains open.


## Signed promotion/observation bridge and review readiness

Eight general support theorems connect signed widening, unsigned intermediate
arithmetic, signed reinterpretation/narrowing and injective signed observations.
The typed evaluator uses64-bit intermediates for the inspected binary operations;
Negate has a separate unsigned-ReturnT path. A144-run s8/s16/s32/s64 matrix checks
12 Add/Subtract/Multiply/Negate recipes. All48 promoted Lean vectors match native
raw/signed values and separate mathematical references, including extrema.

All54 tool/evidence tests and clean Lean replay pass. The2345-line development
has71 value laws and80 support lemmas; signed implementation bridges do not
inflate source acceptance. Review, graph/API/backend correspondence and other
operator contracts remain open. See `reports/signed-word-promotion-and-review.md`,
`reports/signed-word-clean-replay.json`, and `census/signed-word-contract.json`.

`reviews/packets/census-pilot-v1.md` and its hashed560-input zip are ready for
independent review of the preceding2299-line basis. The human authorized a separate
Codex reviewer, whose partial review is complete; `reviews/census-pilot-v1-dispatch.json` records
the assignment and completed report. The report dispositions20 selected targets
and reads43/58 Handle-prefixed bodies; census/source acceptance remains open. That frozen packet does not
silently include the later signed extension. Source acceptance remains zero and
the whole-file experiment/verdict remain incomplete.


## Ordered contraction and zero-initialized MAC boundary

General contraction now constructs bounded operand coordinates from arbitrary
batch/free/contract groups and axis bijections. Six rules cover empty operands,
output or contraction fibers and no-contracting-axis outer products, with the
initializer identity after finish explicit. Six support lemmas accompany them.
The15 integer Lean vectors agree with independent Python coordinates and45 native
mode/profile results;12 further binary32 native runs isolate signed zero. The
matrix guard control has a nonempty contraction and the rewrite option enabled.

The57-run latest archive preserves verified graphs, mixed s8/s32-to-s32 casts,
batch permutations, rank-four/scalar/empty cases and option/layout controls.
Dropping the original positive-zero accumulator changes some negative-zero bits
under the slow evaluator. Numeric equality holds. Four Lean certificates concern
only the explicit minimal MAC profile; backend observation permissions remain
open, so this is not promoted to a source refutation.

The development now totals2547 custom Lean lines,77 value laws and86 support
lemmas. All57 tool/evidence tests and the full checkpoint pass. See
`reports/contraction-foundations-and-zero-mac.md`, `reports/contraction-clean-replay.json`
and `census/contraction-contract.json`. Independent frozen-baseline review and
whole-file acceptance remain separate; no semantic denominator is frozen.


Independent-review correction: the structural58-record `handlers` inventory
contains57 visitor override handlers plus the shared HandleAllReduceOrReduceScatter
helper (header line305). It is a lexical Handle-prefix count, not a count of
58 override entry points or a semantic denominator. The corrected follow-up
packet is `reviews/packets/census-pilot-v3.md`; it includes all Python tests and
older-schema native archives omitted by the original packet. v1 remains frozen.

The independent result is `reviews/results/census-pilot-v1-codex-reviewer.md`;
`reviews/census-pilot-v1-resolution.json` tracks its outstanding semantic and
schedule-observation gates. The corrected v3 input archive passes clean Python
suite/native-baseline preflight (`reports/review-packet-v3-preflight.json`), and
its Lean bytes match the successful final clean snapshot. These packaging checks
do not independently review the later signed-word or contraction semantics.


## Ordered source paths and NaN-aware comparisons

Complete integrator inspection of Broadcast/Compare/Pad and four helpers now
records ordered paths for41 existing schemas, including continuation and effects
before skip/error. These link into the central review ledger. Native strict-mode
Compare replay covers60 producer/direction/mode cases;16 GE/LE runs change a NaN
cell from false to true after IsNonNegative-recognized floating producers. Six
empty-axiom Lean certificates refute true outputs under a necessary ordinary
ordered NaN comparison profile. Backend/source contract review remains open.

The separate review supplements cover five more large handlers and record
Scatter parameter-role, narrow-index Gather and Concatenate allocation/skip
candidates with their exact validation levels. They are not promoted to defects
without replay/certification. Current custom Lean totals2586 lines,77 value laws
and86 support lemmas;59 tool/evidence tests, full checkpoint and fresh Lean replay
pass. See `reports/ordered-source-paths-and-nan-comparison.md`,
`census/ordered-source-paths.json`, `census/source-review-findings.json`, and
`reports/ordered-comparison-clean-replay.json`. Whole-file acceptance remains open.

The completed shape-handler supplement brings independent full-body reading to
53/58 Handle-prefixed functions and corrects the earlier blanket Broadcast-ordering
advisory. Five indexing/reduction bodies remain assigned to the authorized reviewer.
The conditional Reshape/DUS empty-update finding is kept separate from an ordinary
full-pass counterexample; cleanup and async reachability require investigation.
See `reviews/results/census-pilot-v1-shape-handlers-codex-reviewer.md`.


## Confirmed scaled nested-DynamicSlice continuation

The failed-Iota probe can retain a stripped operand binding and drop a runtime
multiplication in the later nested-slice path. Exact handler/full-pass runs
change finite S32 results28→4, with verified graphs and orientation/width/type/
constant-conversion/direct-nested/intended-Iota controls. Seven checked word/index
certificates model the actual original Multiply expression. This is distinct from
the earlier high-bit-u64 evaluator profile.

The new source partition raises the current provisional schema count487→488,
with339 distinct lexical sites unchanged and531 API witnesses over285 endpoints.
Historical frozen packets remain unchanged. Semantic N/F and source acceptance
remain open. All58 Handle-prefixed bodies have been independently read; helper
roles/dependencies and full semantic closure remain under review.

Current custom Lean totals2636 lines;61 tests, full checkpoint and clean replay
pass. See `reports/scaled-nested-slice-continuation.md`,
`census/scaled-nested-slice-contract.json`, `census/schema-revisions.json` and
`reports/scaled-nested-slice-clean-replay.json`. The next concrete witnesses are
Scatter reducer parameter roles and narrow-index Gather unrolling.


## Confirmed Scatter roles and Gather literals

Seventy-five native profile/mode runs confirm value changes in the two single-
Scatter Add paths when the callback repeats a parameter, and in small-Gather
unrolling when S8 comparison literals narrow128 to−128. Gather's principal
witnesses use in-bounds indices0 and127; threshold4 skips the extent129 example.
Eight Lean certificates and four general safe-condition lemmas distinguish the
actual source guards from stronger sufficient conditions. Both-Scatter branches
remain unreplayed. See `reports/reducer-roles-and-index-literals.md` and
`reports/reducer-index-clean-replay.json` for scope, controls and clean replay.

Current custom Lean totals2763 lines, with77 value laws and90 support lemmas;
64 tool/evidence tests and the checkpoint pass. The authenticated independent
reviews now cover all161 top-level function bodies. The source-normalization
registry checks230 local records against813 exact excerpts;258 provisional IDs
remain to normalize. Aliases, caller/global/effect composition, canonical N/F,
source-proof acceptance and the full campaign remain open. Accepted source
rewrites remain zero. Counterexample detection is a verification success and
does not alone answer whether the workflow suffices for this whole workload.


## Allocation status and empty-shape domain diagnostics

Concatenate replay now has120 run/step records. Fifteen preserve the original
root and values while adding nodes and reporting unchanged; predecessor skips
and successor relays differ. A DynamicSlice unit-reshape replay has21 records
and four checked constructor deaths on verifier-accepted empty inputs. Pinned
positive-size prose versus zero-size shape inference is an explicit unresolved
semantic-domain boundary. These are native operational/construction diagnostics,
with no new Lean/source acceptance or backend claim.

See `reports/concat-allocation-and-empty-reshape.md`,
`census/concatenate-status-contract.json` and
`census/dynamic-slice-empty-reshape-contract.json`. The independent simple/scalar
batch plus reduction/collective and Dot/convolution reviews complete local
normalization of all488 current records (1447 excerpts); aliases,
shadowed paths and function-byte/source-excerpt provenance are retained. Custom
Lean stays2763 lines;68 tests, the checkpoint and both new evidence validators
pass. Canonical N/F, semantic correspondence, reviewed pilot and campaign gates
remain open.


## Mathematical campaign ledger

The retained benchmark corpus is frozen at488 records in
`census/mathematical-corpus-v1.json`. The mathematical ledger audits268 registered
model declarations and preserves all benchmark records without a coverage claim.
Seventy-four records have candidate model evidence; full statement/domain
partitions and whole-record results remain open. See
[the ledger report](reports/mathematical-ledger-v1.md).

Run `python3 tools/mathematical_ledger.py` to rebuild the mathematical inventory
and its Lean type/axiom audit without C++ processing or native pass replay.
`TensorRewrite/Theory/ContractionAlgebra.lean` adds arbitrary-rank semiring
contraction distributivity on both operands, with identity finish. These laws
do not assert IEEE floating-point distributivity.


## Complete declared logical-value family

[Typed logical values](docs/mathematical-families.md) now has a frozen mathematical
contract and20 complete profiles:12 predicates and8 universally parameterized word
profiles. The soundness theorem requires equal tensor values for equal-input XOR;
predicate True identities cannot be instantiated as word-one rules. Completeness,
duplicate-free enumeration and all-width uniformity are also proved. This organizes
the earlier individual identities; it is not20 new rewrite discoveries.

The ledger audits248 declarations and attaches this pure-value family to12 candidate
benchmark labels. Whole-record partitions, independent statement review and the full
mathematical denominator remain open. See [evidence](reports/typed-logical-family-v1.md).
Run `python3 tools/check_logical_family.py` after `python3 tools/check_theory.py`.


## Exact convolution theory

The [factored convolution model](docs/convolution-model.md) now derives bounded
window coordinates with grouping, stride, signed padding, dilation and reversal.
Twenty checked theorems cover geometry, empty/zero cases, linearity and
per-output-feature/bias scaling under an explicit Semiring contract. Twenty-two
semantic controls agree with an independent integer finite-sum oracle. IEEE
accumulation, precision conversion and physical-layout normalization remain open;
this does not complete the31-record convolution batch.

The ledger now audits268 registered declarations. Run
`python3 tools/check_convolution_model.py` after `python3 tools/check_theory.py`.
See [the evidence report](reports/exact-convolution-model.md).


## Pointwise convolution reduction

Exact pointwise convolution now reduces to a genuine sum over input channels;
with one channel per group, it reduces to one product. Thirteen new checked
statements derive shape, bounded sampling and loop reindexing for arbitrary
ranks/extents/groups/channels, including empty domains and rank zero. Eight
semantic profiles compare both formulations with an independent integer oracle
at78 output coordinates. The extension adds175 custom Lean lines.

See [the statement and reproduction guide](docs/convolution-pointwise.md) and
`reports/convolution-pointwise.json`. This is exact Semiring theory. The existing
Dot-model bridge was still open at that checkpoint and is proved below. Other
convolution geometry/conversion partitions, independent semantic review and
full-workload mathematical closure remain open.


## Pointwise convolution as matrix Dot

The channel sum now connects to the existing `Contraction.dotTensor` model.
Each batch/feature-group pair uses matrices with input shape `[B*S,C]`, kernel
shape `[O,C]` and result shape `[B*S,O]`, where `S` is the spatial element count.
Both coordinate round trips and both directions of the value identity are proved
for arbitrary ranks/extents/groups/channels under the exact pointwise conditions.

The bridge adds12 checked statements and205 custom Lean lines. Eleven profiles
compare220 values and matrix coordinates in two enumeration orders against an
independent convolution oracle. All17 mathematical accounting tests pass. See
[the statement and reproduction guide](docs/convolution-dot.md) and
`reports/convolution-dot.json`. IEEE, conversions, physical layout, other window
partitions and the full research verdict remain open.


## Mixed-window product and reduction

The exact model now proves convolution with mixed unit-kernel/single-output
spatial axes equals a product reduced only over nonunit kernel axes. One input
channel is required; geometry and selected kernel reversal are derived. Eleven
new checked statements add226 Lean lines. Eleven profiles compare123 outputs
against an independent oracle, and all20 mathematical accounting tests pass.

See [the mixed-window guide](docs/convolution-separable.md),
`reports/convolution-separable.json` and the versioned31-record mathematical
domain worksheet. Nine conversion variants and seven helper-composition
references remain visible; no final obligation denominator or full convolution
family is claimed.


## Ordered binary32 pointwise Dot

Pointwise convolution and matrix Dot now have identical ordered contribution
lists and folds without scalar algebra assumptions. The pinned binary32
specialization preserves stored values under the same separate multiply/add
schedule. The one-channel formula retains its initial addition and finish;
concrete signed-zero and reversed-fold counterexamples prove why those details
matter. External backend/FMA/precision contracts remain separate.

Fifteen new statements add241 custom Lean lines. Twelve binary32 profiles match
an independent rational oracle, and a heterogeneous non-associative fold also
agrees. All23 mathematical accounting tests pass. See
[the ordered contract](docs/convolution-ordered.md), `reports/convolution-ordered.json`
and the preserved failed-v1/corrected-v2 checker history. Full workload closure
and independent semantic review remain open.


## Frozen mathematical review and clean replay

The mathematical snapshot at `9bcd447` passes a clean project replay:105 project
modules rebuilt, all12 replay stages and23 mathematical accounting tests passed,
and nine complete JSON results reproduced. Ten pinned dependency source/compiled
caches were reused with clean tracked sources. The standalone Pilot audit also
passes. Three additional review/replay integrity tests pass.

The user-authorized independent reviewer inspected the 268-file packet and found
no false statement in the inspected 89-statement foundation. Two bookkeeping
findings require correction: 30 omitted retained declarations and 12 refutation
lines misclassified as correctness proofs. The response registers 349 declarations
and corrects R/C attribution without changing Lean statements or the total.
The correction recheck has closed both findings; full-workload review remains open. See [the review/replay guide](docs/mathematical-review.md)
and `reports/mathematical-clean-replay-v1.md`. Custom Lean remains4165 lines.


## Exact real and principal-complex domains

Five explicit log/sqrt profiles now have14 checked declarations and eight symbolic
branch/shape controls. Complex log(exp z)=z iff −π<Im(z)≤π; complex sqrt(z*z)
equals the embedded magnitude iff z is real. Two explicit counterexamples refute
the unguarded mathematical versions. These exact domains do not establish rounded
transcendental or fast-math semantics. See [the domain guide](docs/scalar-domains.md).
New Lean is118 lines (H20/R79/A1/C18), giving4283 total and103 theory/363 ledger
declarations. The four integration theorems remain separate. The old89-statement
independent review does not cover these14 additions; their review remains open.
All488 records remain, with401 unformulated/75 partial/12 declared logical-family
records and zero whole records closed. Code correspondence remains future work.


## Bounded reduction algebra

The actual ordered reduction now equals a sum over derived bounded reduced
coordinates, with inverse kept/reduced coordinate maps. Constant, negation,
regrouping and whole-state tuple laws add27 checked statements and315 Lean lines;
three separate certificates refute missing nonemptiness/initializer/algebra laws.
Nine profiles give20 oracle-agreeing output observations. All60 retained reduction
records have a mathematical formulation/dependency diagnosis across19 groups;
window, arg-extremum, axis-adapter and numerical gaps remain explicit.
See [the reduction guide](docs/reduction-algebra.md). All38 focused tests pass.
Current totals are130 theory statements,390 ledger declarations and4598 custom
Lean lines, with four integration theorems separate. The41 statements added after
the old89-statement review await independent review. Whole-workload closure is open.


## Ordered window core

The ordered window model retains each invalid sample's padding value and its
actual initializer. Unit windows with undilated input equal a derived affine
crop/stride gather under explicit padding laws. Empty and tuple-state cases,
pointwise elimination conditions and two padding-law certificates add29 statements
and322 Lean lines. The separate Slice/Pad target graph is still unproved; no
IEEE add-zero/linear-order-extrema profile is silently assumed.
See [the window guide](docs/reduction-window.md). All42 focused tests pass,
with15 profiles/45 oracle observations. Current totals:159 theory/419 ledger
declarations,4920 custom Lean lines; four integration theorems separate.
All31 window records remain in a domain map, with partial core evidence for19.
No whole record is closed. These29 additions await review separately from the
unchanged41-statement packet. Code correspondence and the full verdict remain open.


## Constructed Slice/Pad factorization

The fused unit-window gather is now equal to an actual Map -> Slice -> Pad graph
with derived ordinary Slice bounds/count, nonnegative padding and exact output
shape. The window corollary retains the original unit/undilated/padding conditions.
Twenty-eight statements add341 Lean lines; total5261, theory187/ledger447.
All46 focused tests pass, including675 independent axis profiles and15 tensor
profiles/45 outputs. Two certificates reject incorrect rounding/clipping.
See [the graph construction guide](docs/slice-pad-factorization.md). This closes
the earlier canonical mathematical graph gap; numerical/full-span/composition
partitions and independent review remain open. No whole benchmark record closes
from this alone; code correspondence and the full-workload verdict remain open.


## Ordered full-span windows

Canonical mixed kept/full-span windows now equal the existing ordered reduction
followed by logical reshape, with geometry, contribution order and shape maps
derived. The theorem supports any operation and initializer, including scalar
and empty cases. Twenty statements add315 custom Lean lines (S40/H198/R76/A1).
All50 focused tests pass;585 mixed axis plans/1111 outputs match an independent
input-coordinate filtering oracle. See [the full-span guide](docs/full-span-window.md).
Totals:5576 lines,207 theory/467 ledger declarations, four integration theorems
separate. All488 records remain370 unformulated/106 partial/12 logical-family;
zero whole records closed. Compositions, numerical domains and the full campaign
remain open. New statements await review; code correspondence stays future work.


## Pad/window fusion and converted fill

Independent edge/interior Pad now fuses into an ordered window with derived
empty-safe geometry, complete contribution-list equality and the actual initializer.
Pure heterogeneous conversion retains the actual converted fill. Twenty-three
statements add387 Lean lines; total5963, theory230/ledger490 (four integration
results separate). Two certificates expose incorrect empty-input high padding
and unequal fill values. See [the fusion guide](docs/pad-window-fusion.md).
All54 focused tests pass;655 profiles/3043 outputs match a materialized-Pad oracle.
The successor window worksheet retains31 records,22 with partial core associations.
All488 records remain368 unformulated/108 partial/12 logical-family; zero whole
records close. Broadcast alternatives, cumulative counts, other partitions and
independent review remain open. Code correspondence and the full verdict remain open.


## Cumulative prefixes and integer count domains

Actual cumulative windows now have derived ordered leading-padding/prefix lists,
with a scan at any axis and arbitrary positive retained strides. Exact semiring
and all-width modular word products match Broadcast(value)*(Iota+1); count
observations have signed/unsigned exact-range iff theorems. Three certificates
expose missing initializer and overflow conditions. See [the prefix guide](docs/prefix-window-counts.md).
Thirty-four statements add466 Lean lines; total6429, theory264/ledger524, with
four integration theorems separate. All58 focused tests pass:726 profiles/1290
outputs,45 count-conversion controls and four nonzero retained-stride controls.
Window worksheet v3 retains31 records,26 with partial core associations. All488
records remain364 unformulated/112 partial/12 logical-family; zero whole records
close. Rounded products, width/wrapper conversions, broadcast/tuple cases and
independent review remain open. Code correspondence and the final verdict remain open.


## Covered singleton broadcasts and singleton tuple values

Covered singleton windows now equal a derived logical Reshape/Broadcast graph,
with actual ordered samples and explicit two-sided initializer/padding identities;
associativity is unnecessary. An arbitrary pure singleton-tuple window has a closed
value-family proof, including a FloatLib binary32 stored-bit instance. See the
[broadcast and tuple guide](docs/broadcast-window-and-tuples.md).
Thirty-six statements add636 Lean lines; total7065, theory300/ledger560, four
integration results separate. All66 focused tests pass;3780 axis configurations,
1277 tensor profiles/440 outputs,10 tuple and eight finite binary32 outputs agree
with independent oracles. Worksheet v4 retains31 records,29 with core evidence;
the two combined Pad/broadcast compositions remain open. Complete declared value
profiles total21. All488 records remain361 unformulated/114 partial/13 carrying
value families; zero whole records close. Statement review, the full campaign and
its verdict remain open; code correspondence stays future work.


## Composed Pad/window broadcasts

Raw Pad/window attributes now derive terminal coverage and pointwise retained axes,
then compose actual Pad fusion with logical Reshape/Broadcast. Direct and converted
fills retain explicit initializer identities. See [the composition guide](docs/pad-broadcast-composition.md).
Thirteen statements add242 Lean lines; total7307, theory313/ledger573, four
integration results separate. All70 focused tests pass:14400 raw axis configurations,
3785 tensor profiles and1805 outputs agree with a materialized-Pad oracle.
Worksheet v5 retains31 window records, all with core evidence; whole-record and
numerical/observation partitions remain open. All488 records are359 unformulated,
116 partial and13 carrying declared value families; zero whole records close.
Complete declared profiles remain21. Independent review and the full mathematical
campaign/verdict remain open; code correspondence stays future work.


## Word remainder domains and whole-corpus formulation audit

All-width unsigned/signed remainder nesting, actual sign-corrected power masks and
bounded Iota/offset graphs now have explicit range proofs and overflow certificates.
A FloatLib binary32 certificate refutes fixed-order uniform fold/product bit equality;
floating truncating remainder and collective permitted-behavior contracts remain open.
See [the remainder and workload guide](docs/remainder-and-collective-domains.md).
Twenty-eight statements add240 Lean lines; total7547, theory341/ledger601, four
integration results separate. All75 focused tests pass:5461 word pairs,361 integers,
2350 Iota profiles/2368 outputs and30 finite binary32 controls agree with independent
oracles. A full retained-ID audit finds108 records with domain worksheets and380
without;73 records have evidence but no such worksheet. These are formulation gaps,
not a frozen N/F or proof-coverage fraction. All488 records remain351 unformulated,
124 partial and13 carrying value families; whole-record closure stays zero.
The full mathematical campaign/review/verdict remain open; code correspondence is future work.


## Whole-workload proposal worksheets

All380 previously missing records now have explicit mathematical target/domain
proposals in seven immutable worksheets. The successor catalog covers all488
retained IDs;380 have only the new unreviewed proposal worksheets. Four support
schemas, two stages and23 unspecified-target risks remain visible. See
[the formulation scope and remaining gates](docs/workload-formulation-proposals.md).
No new Lean statement or line is accepted: totals remain341 theory/601 ledger and7547
custom Lean lines, with21 complete declared value profiles and zero whole records
closed. All80 focused tests pass. Record proof statuses stay351 needing formal
statement/domain work,124 partial and13 carrying value families. Worksheet presence
is not completed formulation, all-case attempts or a frozen N/F. The full campaign,
independent reviews and final verdict remain open; code correspondence is future work.


## Ordered Scatter semantics and partial fusion

An actual full-rank window Scatter model now derives bounded events from signed
index axes, preserves duplicate order and whole coupled state, and proves empty/
full-window Map and associative/commutative trace fusion. Actual word parameter
roles and four contract certificates remain explicit. See [the model and open
bridges](docs/ordered-scatter.md). Tensor-input Concatenate and general dimension/
transpose bridges are still unproved. Thirty-six statements add480 Lean lines;
totals8027, theory377/ledger637, four integration results separate. Independent
oracles agree on2709 profiles/3354 events/2968 outputs,11872 role controls and four
finite binary32 outputs. All86 focused tests pass. Catalog v3 refines six records, leaving374 covered only
by unreviewed proposals. Whole-record closure stays0; full campaign/review/verdict
remain open. Code correspondence remains user-deferred future work.

## Leading-axis tensor-input Scatter bridge

The [Concat bridge](docs/scatter-concat.md) now derives actual input-tensor concatenation
to exact ordered Scatter events, with arbitrary shared trailing batch dimensions.
Sequential composition needs no scalar laws; result fusion explicitly requires
assoc/comm, with an arbitrary-width word Add instance. Nine statements add201
custom Lean lines. General dimension layouts and the full campaign remain open.

## Raw Scatter update-layout bridge

The [raw update-layout model](docs/scatter-layout.md) now derives actual interleaved
batch/window tensor reads and inserted singleton operand-window coordinates to
the existing exact ordered event list. Sixteen statements add278 custom Lean lines.
A checked counterexample distinguishes raw storage order from declared Scatter
order. General dimension bridges and the whole-workload verdict remain open.

## Actual raw index-vector representations

The [index-tensor reader](docs/scatter-indices.md) now proves bounded coordinate and
pack/read inverses for an explicit vector axis at any position or an implicit
single-component vector. Actual vector-axis relayout preserves Scatter with its
original update order. Twenty statements add268 custom Lean lines. A checked
zero-vector counterexample distinguishes raw tensor emptiness from an empty batch
or a single-update Map. General dimension/graph bridges and the full campaign remain open.
