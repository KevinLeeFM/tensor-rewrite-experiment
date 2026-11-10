# Whole-schema replacement API paths and bounded skip outcomes

Every one of the487 provisional source schemas now has typed static links to
replacement APIs or explicit external/construction boundaries. The paths
preserve actual argument/default profiles and helper dependencies. They are
not feasible execution paths, a frozen semantic denominator, accepted source
proofs, or an effect-closed model.

A separate real-XLA diagnostic demonstrates why API outcomes belong in the
contract: a default-false relay call can insert a new instruction, skip replacing
a controlled old node, return OK and report a changed graph. Repetition retains
more unused new nodes. Fixed-point mode reaches the source's50-run cap on the
tested input. Values agree and graphs verify; no unbounded nontermination or
Lean refutation is claimed.

XLA pin: e58e523b11f1fde802a493a776d158007486e1bf. Canonical target SHA256:
1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f.
The canonical pass is unchanged. Source acceptance remains zero.

## Static API census

`tools/replacement_api_paths.py` consumes the complete source-call inventory,
the compiler-selected call variants and the provisional site/case bindings.
It parses byte-preserving argument ranges and distinguishes selected classes,
overloads and local targets. The helper closure uses the292 selected static
local edges across161 source functions, retaining one witness chain to each
reachable API site. It also records helper-level unmatched and nonlocal calls.

All487 schemas (452 replacement bindings and35 delegations) have links. There
are529 schema/API witness chains reaching all285 catalogued source call sites:

| API or boundary | Distinct source sites |
| --- | ---: |
| Visitor ReplaceInstruction returning Status | 126 |
| Visitor ReplaceInstruction returning StatusOr<bool> | 2 |
| Visitor ReplaceWithNewInstruction | 125 |
| Instruction ReplaceOperandWith | 20 |
| Instruction ReplaceOperandWithDifferentShape | 4 |
| Instruction ReplaceAllUsesWith | 4 |
| Instruction ReplaceUsesWith | 1 |
| Computation CloneWithReplacements construction boundary | 2 |
| External convolution operand-swap rewrite boundary | 1 |

Typed template instantiations and a construction sharing a call range do not
inflate these source-site counts. API choices use compiler-selected class/type
identities, not terminal names alone.

Of the125 ReplaceWithNewInstruction sites,120 supply two arguments and inherit
relay=false; five supply four arguments with relay=true. Those five are at
2866,6927,6941,7089,7186. The128 existing-instruction visitor calls always relay
controls internally. The29 low-level use/operand rewires do not relay control
edges or remove old producers in those APIs. The remaining3 sites are explicit
construction/external-rewrite boundaries, not interchangeable primitive rewires.

The source catalog includes17 body-hashed contract excerpts: visitor defaults/
status handling, both compatibility wrappers, computation insertion/replacement,
operand removal, control copying/dropping, low-level rewiring, external swap,
clone wrapper and fixed-point default/driver/cap. Behaviors remain source-
inspected drafts awaiting independent semantic review; they are not Lean axioms.

Static exposure counts are nonexclusive:262 schemas reach an always-relaying
visitor call;198 reach default-false relay;6 reach an explicit-true new-node call;
29 reach low-level rewiring;3 reach the construction/external boundaries. These
are review-priority dimensions, not correct/incorrect rule counts. The helper
alternatives are overapproximated without composing guards or return/status paths.

Three initially uncovered anchors were inspected. The singleton tuple Reduce
and ReduceWindow cases use CloneWithReplacements before their actual tuple
replacement, so both construction and replacement remain visible. Convolution
operand swap delegates to an external rewrite with a backend callback; that
boundary is explicit instead of being labeled a harmless helper with no rewrite.
The285 sites are not a complete external mutation model. All286 unmatched macro
call sites and6814 nonlocal/unresolved call IDs remain in function summaries.
Virtual callbacks, alternative preprocessing, aliases, status propagation and
sequential graph effects still need reviewed contracts.

## Native default-false outcome

Source case: HandleAdd/constant-right, at943–948. The input is scalar s32
`add(constant(2), parameter(0))` with parameter value5. It is run with no
control edge, a marker control predecessor, or a marker control successor.
A new swapped Add is constructed by the source branch.

The visitor defaults relay=false. Computation ReplaceWithNewInstruction first
adds the new instruction, then its replacement routine returns false if the
old node has controls and relay=false. The outer wrapper DCHECKs changed but
returns OK; the visitor sets changed=true on that OK status. The optimized
build therefore retains both the original root and the newly inserted node.
The change flag reflects an insertion, not a completed replacement.

Fixture: tests/xla/replacement_status_replay_test.cc.
Immutable archive: reports/replacement-status-replay-v1. It records the opt
build, exact fixture/BUILD, command/events, logs, XML and binary hash. There are
30 checked rows over12 profile/mode recipes:

| Profile | No rewrite | Three handler/single-pass runs | One fixed-point run |
| --- | --- | --- | --- |
| No controls | stable | first swaps root; next two stable; node count stable | swaps root and converges; node count stable |
| Old control predecessor | stable | old root retained; +1 node each run | old root retained; +50 nodes; reaches cap |
| Old control successor | stable | old root retained; +1 node each run | old root retained; +50 nodes; reaches cap |

Every result is7 and every checked graph passes HloVerifier. The two capped
runs emit the actual source circular-simplification warning. Source declarations
pin the rerun cap to50 and the option default totrue. This is a bounded native
observation in Bazel opt, not a debug-build claim, a universal termination theorem,
a semantic value counterexample or evidence that every default-false site grows.
The cap prevents an inference of unbounded nontermination. The inactive/no-
control/single-pass controls isolate insertion, replacement and iteration behavior.

## Validation, replay and burden

The integrated `python tools/checkpoint.py` passes51 tool/evidence tests, all
Lean checks and every native archive validator. A separate test independently
computes least-fixed-point reachability from the typed graph and verifies every
witness edge, all schemas and the argument/default counts. Adversarial controls
reject omitted cases/endpoints/frontiers, wrong overloads/defaults, broken chains,
changed contract text, source acceptance, a frozen denominator, and erased root/
cap observations. Green checks do not promote the unresolved semantic boundaries.

`snapshots/replacement-api-census-v1.zip` bundles exact inventory inputs, body-
hashed sources, tooling, native evidence and the pinned parser packages.
`reports/replacement-api-offline-replay.json` records rebuilding the API artifact
and checking the archived native outcomes in a fresh directory without network
access. The rebuilt artifact matches exactly. It reuses archived typed compiler
outputs and native test evidence; it does not rerun Clang or rebuild XLA. The
original typed/native runs remain independently hash-checked by the checkpoint.
The replay records interpreter/platform identity; this is not a hermetic OS image.

Custom Lean remains2127 lines (S612,H751,R504,A24,C236). This turn changes no
Lean sources, and their bytes exactly match the previous clean Lean snapshot,
`snapshots/boolean-control-family-pilot-v1.zip`. The checkpoint reruns the Lean
build/audits/controls. Non-Lean implementation added:

| Artifact | Physical lines | Bytes |
| --- | ---: | ---: |
| replacement_api_paths.py | 190 | 13289 |
| check_replacement_api_evidence.py | 68 | 4519 |
| run_replacement_status_replay.py | 87 | 4928 |
| replacement_status_replay_test.cc | 98 | 4710 |

These counts describe tooling, not Lean proof burden. Shared checkpoint/unit
integration edits are outside that new-file subtotal and remain hash-recorded.

Next, compose guards and API outcomes for semantic case partitions, including
insertion-before-skip, callback/alias/frame effects and iteration observations.
Independently review these contracts/census and the diverse pilot, then conduct
the full campaign and residual diagnosis. The whole-file research question
remains unresolved; static API links do not meet its final exit gate.

Offline API snapshot SHA256: 7b10d7f79193457419b6002770b93d9c397ccd5d5d5ea03e54fd46955749550e.
