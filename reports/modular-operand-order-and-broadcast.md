# Operand-order and Broadcast bridges for modular arithmetic

Seven new general value theorems connect the modular Add/Multiply laws to
captured commutative operand orientations and the source's Broadcast construction.
A261-run native matrix checks all displayed orientations, two nonuniform
Broadcast axis choices, scalar constant gathering and negative source guards.
All87 corresponding Lean model vectors agree with native values and a separate
integer-modulo/index reference.

XLA pin: e58e523b11f1fde802a493a776d158007486e1bf. Target SHA256 remains
1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f.
Lean4.35.0/Std remain pinned; the canonical pass is unchanged. Source acceptance
remains zero and the semantic census denominator remains unfrozen.

## General statements

OperandOrder.map₂ records whether a source node's operands have the captured
forward or swapped orientation. It is an explicit logical-value definition,
not an implementation of C++ Match. The generic map₂_eq bridge requires an
explicit commutativity law. It cannot silently make subtraction or floating
payload-sensitive operations commutative. Two shared pullback lemmas establish
binary evaluation and constant preservation through one index map.

ModularArithmeticBridges instantiates these facts with BitVec multiplication:

| General bridge | Alternatives represented | Related provisional schemas |
| --- | --- | --- |
| factor_any_order | both inner factors' positions, four combinations | all four HandleAdd/factor-* schemas |
| mul_assoc_any_order | inner/outer Multiply positions, four combinations | HandleMultiply/constant-product |
| four_factors_any_order | three Multiply positions, eight combinations | HandleMultiply/four-factors |
| add_broadcast_assoc | gather constant sum before the shared Broadcast | HandleAdd/constant-sum-broadcast-scalars |
| sub_add_broadcast | gather constants across Subtract/Add | HandleAdd/constant-subtract-broadcast-scalars |
| mul_broadcast_assoc | gather scalar product before Broadcast | HandleMultiply/legacy-constant-product-broadcast-scalars |
| broadcast_factor_any_order | two Multiply positions and concrete operand projection | HandleMultiply/broadcast-factor |

These seven theorems relate to ten overlapping schemas; some already had narrower
value laws. They are not ten newly accepted source rewrites. Rank, extents and
bit width remain general. The Broadcast theorems use the actual bounded signed-
axis decoding and extent equalities of IndexMaps.broadcastIndex. The scalar-
factor theorem moves a uniform scalar into the smaller operand's multiplication,
then broadcasts using the same dimension array. It supports scalar and empty
shape instances without extrapolating from the concrete native matrix.

The extent-equality premise agrees with ShapeVerifier::HandleBroadcast1741–1762
and the evaluator's3254–3276 checks: mapped operand and output extents must be
equal in HLO Broadcast. This is not an assumed NumPy/StableHLO broadcasting rule.
Axis length/range are checked by the existing BroadcastAxes model; additional
legal-HLO restrictions do not weaken these value laws. C++ attribute decoding
and dynamic-shape correspondence remain part of source review.

The bridge statements account for captured orientations and logical projection.
Actual stateful matcher binding, constant literal/evaluator construction, datatype
eligibility and graph/API/frame effects still need source correspondence. The
plan permits independently reviewed source-to-theorem mapping; it does not
require a verified C++ extractor. That review remains pending, and no machine-
checked extraction theorem is claimed. The earlier control-order and insertion-
before-skip findings still apply to whole-source acceptance.

## Native and model matrix

Fixture: tests/xla/modular_bridge_replay_test.cc.
Successful immutable archive: reports/modular-bridge-replay-v2.
It records exact fixture/BUILD, command/events, logs, XML and binary hash.

| Recipe family | Recipes per dtype |
| --- | ---: |
| Shared factor in each inner operand position | 4 |
| Nested constant product in each inner/outer position | 4 |
| Four factors in all three node orientations | 8 |
| Scalar-factor movement, four orientations × axes0/1 | 8 |
| Scalar Broadcast Add/Subtract/Multiply gathering | 3 |
| Nonscalar constant / non-Broadcast other-operand guard controls | 2 |
| Total | 29 |

Three dtypes (u8/u32/u64) ×29 recipes × handler/pass/no-rewrite modes give261
runs with1044 output cells, also checked in the original graphs. All intended
handler/pass rewrites fire. Both guard recipes remain unchanged in handler and
full-pass modes. All no-rewrite controls remain unchanged. Every rewritten
module passes HloVerifier, and native HloEvaluator values match the independent
modulo/index reference.

The output is2×2; the Broadcast operand has two distinct values. Axes0 and1 are
both legal but give different outputs. At width8, scalar-factor movement with
one axis yields [0,254,250,0], and the other yields [0,6,2,0]. The Lean probes
compute the actual before/after Tensor expressions, operand orientation flags,
scalar empty-axis Broadcasts and decoded dimension arrays for all87 recipes.
An intentionally false kernel claim changes one legal Broadcast axis to the
other and is rejected after evaluating real projected values.

The native guard controls require scalar constant shape and an actual Broadcast
of the other nonconstant operand. They do not establish floating permissions,
signed-source semantics, alias effects or all legal source configurations.
No effectful operators or changed schedules are hidden in the native fixtures.

V1 remains a failed archive. Its type-like HLO identifier s1 was reserved and
prevented parsing the scalar-constant recipes. V2 replaces those fixture names;
the source pass and mathematical statements are unchanged. The validator checks
that the failed run remains failed, rather than counting it as numerical evidence.

## Validation and artifact burden

The integrated checkpoint passes53 tool/evidence tests, the Lean build/axiom
checks, positive probes and false-proof rejection, and all native archive gates.
Adversarial tests reject omitted orientations, a fired negative guard, erased
axis-dependent values, source acceptance and claimed matcher/graph proofs.
The three new shared lemmas have audited dependencies: map₂_eq uses Quot.sound;
the two pullback facts have no axioms. The seven rule bridges use only audited
standard dependencies. Every previous theorem axiom set remains unchanged.

| Lean category | Previous | Current | Added |
| --- | ---: | ---: | ---: |
| S semantics | 612 | 622 | 10 |
| H shared support | 751 | 772 | 21 |
| R rule proofs | 574 | 643 | 69 |
| A imports/checking | 25 | 26 | 1 |
| C certificates | 236 | 236 | 0 |
| Total | 2198 | 2299 | 101 |

The development now has71 value laws and72 shared support lemmas. Pure/effectful
graph rules and diagnostic certificates retain separate counts. Tests/audits
are separately measured; native/Python tooling is not hidden in Lean LOC:

| New file | Physical lines | Bytes |
| --- | ---: | ---: |
| modular_bridge_cases.py | 41 | 1977 |
| check_modular_bridge_evidence.py | 100 | 7486 |
| run_modular_bridge_replay.py | 78 | 4274 |
| modular_bridge_replay_test.cc | 153 | 8570 |

snapshots/modular-bridge-pilot-v1.zip and
reports/modular-bridge-clean-replay.json preserve fresh Lean replay without Lake
caches. Measurements, model vectors and prior axiom sets match. This is same-
agent replay, not independent semantic/source review or rebuilding native XLA
in the fresh directory.

Next, review the source matcher/literal/type correspondence and compose these
value bridges with the actual graph/API outcome contract. Remaining numerical
and operator families, dynamic/physical representation, independent census/pilot
review, the whole-file campaign/diagnosis and the final verdict remain required.

Fresh Lean snapshot SHA256: 1715c25e65c9464ea43da02ebe55129940682002bf08af513762492499b37e21.
