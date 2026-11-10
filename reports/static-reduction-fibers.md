# Static reduction fibers, initializer laws and empty dimensions

Source pin: XLA e58e523b11f1fde802a493a776d158007486e1bf.
Contracts and theorem identities: census/reduction-logical-contract.json.
Profile: static single-output ordered fibers; initializer law explicit;
reassociation and physical layout remain separate. Source acceptance stays0.

## Source obligations and semantic domain

ShouldBroadcastReduce tests zero-element input or result. BroadcastReduce's
single-output path broadcasts the actual initializer. HandleReduce's next
same-element-count path replaces reduction with reshape, relying explicitly on
the initializer being an identity. Layout-sensitive mode additionally checks
ReshapeIsBitcast. The source cases and caller/helper relationships remain
separate records, with no accepted source proof.
The pending review ledger covers selected replacement/mutation candidates;
the empty caller's BroadcastReduce delegation is recorded in the site-case map
and full-call inventory rather than that candidate-call list. Full caller/helper
correspondence review must follow those records together.

The pinned operation_semantics.md:3831–3890 requires identity initializers and
permits reassociation, including floating numerical differences. Shape inference
checks reducer types, axis ranges and duplicates; passing those checks does not
prove the reducer's algebraic laws. The evaluator initializes each output with
the supplied initializer before applying the reducer over the corresponding
input coordinates. Exact source ranges/hashes are preserved in the contract.

The new logical semantics describes one ordered fold, not the full set of
permitted floating behaviors. Its empty/singleton rules do not assume an
arbitrary reducer is a commutative monoid. Empty fibers need no reducer law;
same-count elimination explicitly requires operation(initial,value)=value.
An independently adopted floating observation relation and source translation
remain obligations. No law is inferred merely from a source matcher name.

## Arbitrary-axis construction and proofs

Reduction.Plan consumes input axes in order, keeping or reducing each natural
extent. It derives input/result ranks, shapes and the product of reduced extents.
This admits arbitrary finite ranks and arbitrary interleavings of kept/reduced
axes, including zero extents. It does not accept a caller-chosen tensor index
map. Constructing a plan from the source's signed axis array is still an
unverified translation step.

fiberValues fixes the kept coordinates and enumerates reduced coordinates in a
declared order. reduceTensor folds that list with the supplied operation and
initializer. The value representation and raw enumeration are independent of
the optimization theorems. Generic list support proves constant-size flatMap
length; tensor support proves each fiber's length and the factorization
inputCount=outputCount*fiberCount, including zeros.

For equal input/output counts and positive output count, cancellation forces
fiberCount=1. Product-one reasoning then derives that every reduced extent is
one. Unit-index reconstruction inserts zero at those axes; its logical linear
position equals the output position. The earlier reshape round-trip theorems
identify this reconstruction with the concrete reshape map.

Three rule theorems follow:

- Empty input produces the actual initializer at every output coordinate.
- Empty output has the initializer broadcast's logical values, vacuously.
- Equal element counts yield the specified reshape when the initializer's left
  identity law holds. The proof handles empty output separately, so it never
  cancels a zero element count or assumes all reduced axes are unit-sized.

The theorems are parametric in element type and operation. They cover logical
values in this static ordered model; they do not establish source finite-count
arithmetic, physical layout, arbitrary permitted reduction orders, tuple reducer
packing, effects or replacement API/frame behavior.

## Native execution and an intentionally invalid semantic input

reports/reduction-replay-v1 archives one native test with seven profiles, each
run without rewriting, through direct HandleReduce and through one full pass.
All original/rewritten graphs pass HLO verification. Layout sensitivity is
enabled; the full pass runs once. Boolean AND supplies exact lawful examples.

| Profile | Initializer | Before | Handler/pass result |
| --- | --- | --- | --- |
| [1,3,1], reduce axes0,2 | true | false,true,false | Reshape, same values |
| [2,3], no reduced axes | true | true,false,true,false,true,false | Reshape, same values |
| [2,0,3], reduce axis1 | true | Six true values | Initializer broadcast |
| [0,2], reduce axis1 | true | No elements | Empty initializer broadcast |
| Scalar, no reduced axes | true | false | Reshape, same value |
| [2,3,2], reduce axes0,2 | true | false,false,true | No rewrite, same values |
| [1,3,1], reduce axes0,2 | false | false,false,false | false,true,false |

The last row is the nonidentity domain control. AND(false,true) is false, so
false is not an identity for Boolean AND. The graph is well typed and verified
but violates the documented semantic precondition. Its changed values are not
counted as a source counterexample. All seven no-rewrite runs retain their
original values and HLO. The ordinary nontrivial fiber also remains unchanged
by the layout-sensitive handler/pass and supplies operator-model evidence.

Native results read output coordinates directly. Actual Lean probes agree for
all profiles, including the invalid-control difference. A kernel example also
checks the ordered nontrivial coordinate-label fiber [2,3,8,9]; Boolean native
results establish membership/value agreement on these examples, not universal
iteration-order correspondence for noncommutative reducers.

The archive preserves fixture, BUILD, uncached Bazel command/events/logs/XML,
source identity and binary hash. Reproduce with tools/run_reduction_replay.py
and an unused reduction-replay-vN archive name. This is seven handler, seven
full-pass and seven no-rewrite executions, not21 verified source obligations.

## Integrity checks, code size and remaining gates

tools/check_reduction_evidence.py validates exact source/profile identities,
proof/source-case partitions, all21 native observations and actual Lean probe
output. Controls reject labeling the nonidentity example a source counterexample,
dropping the identity premise, omitting that domain control, or changing model
fiber results. A false Lean proof asserting identity for arbitrary initializers
must fail. The integrated checkpoint and39 tool/evidence tests pass. Earlier
axiom sets are preserved; new dependencies remain within the standard allowlist.

| Lean category | Previous | Current | Added |
| --- | ---: | ---: | ---: |
| S semantics | 426 | 482 | 56 |
| H support | 416 | 528 | 112 |
| R rule proofs | 319 | 364 | 45 |
| A imports/checking | 20 | 21 | 1 |
| C certificates | 177 | 177 | 0 |
| Total | 1358 | 1572 | 214 |

The increase includes all plan, coordinate enumeration, count, unit-axis and
reshape-connection code. Diagnostic/audit sources are separate in
reports/pilot-values.json; no new refutation certificate is claimed for the
invalid initializer. There are now47 value identities and50 support theorems,
plus separately counted graph and nested-slice results. These overlap source
cases and do not define a coverage numerator.

snapshots/reduction-pilot-v1.zip preserves the complete Lean development.
reports/reduction-clean-replay.json records fresh replay without a build cache,
matching measurements, dependencies and index/reduction probes. This is
same-agent Lean replay, not independent source review or native rebuilding.

The reviewed pilot still needs physical-layout and advanced numerical/effect
contracts, and reduction work still includes transpose/reshape movement,
merging, tuples, windows and reassociation. Complete semantic census, source
correspondence, full campaign and final research verdict remain unfinished.
