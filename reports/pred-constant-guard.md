# Connecting PRED constant recognition to graph rewriting

Source pin: XLA e58e523b11f1fde802a493a776d158007486e1bf.
Target helpers: UnwrapToConstant/IsAll in algebraic_simplifier.cc:98–137;
literal storage checks: literal.cc:2316–2405. The latter is additionally pinned
by sources/constant-guard-contract-manifest.json.

## Actual source behavior

UnwrapToConstant follows operand0 through exactly Broadcast, Copy, DynamicSlice,
Reshape, Reverse, Slice and Transpose. Constant terminates successfully; any
other opcode returns nullptr. The int8 IsAll overload then asks whether every
literal storage element equals the requested value. PRED uses0/1 for false/true
and rejects values such as2 that do not round-trip through its native type.

AllElementsEqualValue accepts empty storage. For nonempty storage it compares
the first element with the requested value, then compares overlapping adjacent
memory ranges. This checks all stored representations, rather than merely one
element. RawData has dense/default-bit-width storage preconditions. C++ object
representations, memcmp and physical addressing are not formalized by our model.

census/pred-guard-contract.json records the source wrapper identity/hash, model
wrapper names, theorem identities and explicit remaining translation work. The
checker matches both whitelists and rejects silently adding an unsupported model
operator. Other scalar types and the IsAll Literal/IsAllFloat overloads are outside
this PRED guard result; their source obligations remain open.

## Kernel-checked guard abstraction

ConstantGuard.lean represents finite Boolean literal storage and a bounded
logical-coordinate-to-storage address function. Its executable matchesAll checks
the first element and every adjacent pair, including the native empty case.
It is not defined by the proposition it is supposed to establish.

The View syntax contains literal leaves, unrecognized operation values and the
seven wrapper tags with total output-to-input coordinate maps. Ranks and shapes
can change along a chain. Independent View.eval computes the tensor value;
View.isAll follows recognized wrappers and applies the finite storage check.
An unrecognized operation is rejected even when its denotation happens to be
uniform. The function-valued addresses/maps are mathematical objects, without a
fabricated executable Repr instance.

ConstantGuardLemmas.lean proves:

1. A successful first/adjacent check makes every stored Boolean equal the target.
2. Bounded literal reads therefore denote the corresponding constant tensor.
3. This remains true through arbitrary finite wrapper chains and total index maps.

GuardedBooleanDag.and_rhs_true_of_isAll uses that proof to eliminate And and
redirect its graph uses. Its premise is now a successful executable view guard,
rather than an unexplained equality of the rhs tensor with constant true. This
is one guard bridge for an existing case, not an additional independent source
rewrite or a new source-coverage numerator.

The total-map interface proves uniformity independently of how a legal map is
implemented. It does not prove that concrete C++ broadcast, reshape, slice,
dynamic-slice clamping, transpose or reverse attributes decode to those maps.
Likewise the bounded literal address must still be related to actual storage,
layouts and element representation. These are disclosed source bridges, not
newly assumed source guards. Graph-prefix extraction and replacement API/frame
contracts also remain pending. Complete source acceptance stays0.

## Native differential checks

reports/pred-guard-replay-v1/result.json archives an actual compiled XLA test.
It invokes the public, unchanged AlgebraicSimplifierVisitor::HandleAnd directly,
so no earlier producer simplification erases the wrapper whose recognition is
under test. This is a direct handler run, NOT a full pass traversal. The archive
records xla_handler_run=true and xla_full_pass_run=false; its checker rejects
promoting that scope.

| Cases | Expected source result | Observed |
| --- | --- | --- |
| Direct true literal | Replace And by lhs | Pass |
| Seven wrappers over true literals | Replace And by lhs | All pass |
| Not(false), semantically all true but unsupported | No change | Pass |
| Nonuniform literal | No change | Pass |
| Empty PRED literal storage | Matches both0 and1 | Pass |
| Mixed/ones storage and requested value2 | Native matching/rejection behavior | Pass |

All ten handler cases verify before/after and preserve all four tested output
values. The DynamicSlice case uses an out-of-range start99, exercising native
clamping on a uniform input. These finite tests supplement the model proof; they
do not establish the universal C++ attribute/map translation. Literal API checks
cover empty, nonuniform and uniform storage and value2 rejection.

The compiler implementation is unchanged. The isolated checkout adds only
diagnostic fixtures and BUILD targets. The archive preserves fixture, BUILD,
uncached Bazel command/events/logs/XML, binary hash, commit and pass source hash.
Fresh execution uses tools/run_pred_guard_replay.py with an unused
pred-guard-replay-vN archive. tools/check_pred_guard_evidence.py is an offline
source/model/archive check and does not run the handler or pass.

## Controls, size and remaining gate

Lean controls exercise nonuniform tails, both empty-literal targets, unsupported
uniform operations and rank-changing wrapper chains. An invalid proof that ignores
a later nonuniform element must fail with the expected rfl error only. Evidence
controls reject a missing wrapper, an unsupported model tag, a false full-pass
claim and falsely claiming the unsupported Not case rewrote.

All34 tool/evidence tests and the integrated checkpoint pass. All prior theorem
axiom sets are unchanged; new dependencies use only standard Lean foundations.
There are41 value rules,12 graph-context rules,19 support lemmas and one guard
bridge, with earlier refutation/witness groups retained. These groups overlap
source cases and must not be summed as independent coverage.

| Lean category | Previous | Current | Increase |
| --- | ---: | ---: | ---: |
| S | 225 | 265 | 40 |
| H | 139 | 175 | 36 |
| R | 258 | 276 | 18 |
| A | 12 | 14 | 2 |
| C | 133 | 133 | 0 |
| Total | 767 | 863 | 96 |

snapshots/pred-guard-pilot-v1.zip preserves the complete Lean pilot and controls.
reports/pred-guard-clean-replay.json records a fresh-directory build without
.lake, matching measurement and axiom outputs. It replays the Lean pilot, not the
native binary build, and is same-agent rather than independent review.

The diverse reviewed pilot and complete semantic census/campaign remain open.
Next connect actual typed storage/indexing and matcher/API observations, then
extend graph/guard reasoning across indexing, layout, reduction, numerical and
effectful families. This result does not settle the whole-file research question.
