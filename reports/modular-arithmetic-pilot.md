# Modular Add/Multiply extends the numerical pilot

Sixteen new pointwise tensor laws cover modular Add/Multiply identities,
commutation, reassociation, cancellation, negated operands and factoring. The
proofs quantify over arbitrary finite rank, extents and bit width, including
empty/scalar tensors and the degenerate zero-width mathematical word model.
They do not assume that intermediate arithmetic avoids overflow.

Eight native source branches are exercised at u8/u32/u64 with overflowing inputs,
with direct-handler, full-pass and no-rewrite controls. Lean tensor expressions,
native before/after values and a separate Python integer-modulo reference agree.
This adds finite-word numerical evidence to the pilot, without treating these
laws as floating-point or whole-source graph proofs.

XLA pin: e58e523b11f1fde802a493a776d158007486e1bf. Target SHA256 remains
1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f.
Lean4.35.0 and Std remain pinned; the canonical pass is unchanged. Source
acceptance remains zero and the semantic census denominator remains unfrozen.

## Proof statements and source partitions

TensorRewrite/Pilot/ModularArithmetic.lean uses the existing logical Tensor
model and pinned Std BitVec operations. Addition and multiplication are modulo
2^width. The source maps in census/modular-arithmetic-contract.json are scoped
candidates, not a reviewed extraction of the C++ pass.

| Laws | Candidate source cases |
| --- | --- |
| Add zero on each side | HandleAdd/rhs-zero, lhs-zero |
| Add commutation | HandleAdd/constant-right |
| Add association | HandleAdd/constant-sum-direct-constants |
| Subtraction plus gathered addend | HandleAdd/constant-subtract-direct-constants |
| Add/Subtract cancellation in each operand order | HandleAdd/cancel-subtract-rhs, cancel-subtract-lhs |
| Multiply zero/one on each side | HandleMultiply/rhs-zero, lhs-zero, rhs-one, lhs-one |
| Multiply two negated operands | HandleMultiply/negated-operands |
| Multiply association | HandleMultiply/constant-product |
| Factor common rhs/lhs operand | HandleAdd/factor-rhs-rhs, factor-lhs-lhs |
| Regroup four factors | HandleMultiply/four-factors |

There are16 theorem/source pairs in this extension. The statements allow more
logical values than their source matchers, which is legitimate for value-law
proofs; source eligibility and actual replacement still need correspondence.
Specific operand orders are explicit. Mixed factor positions, other AnyOrder
alternatives and broadcast construction remain separate source obligations.
Shared factors may be arbitrary tensors; source constants, when present, are
represented by same-shape tensor values. No hidden floating-point permission,
signed-decoding contract, no-overflow premise or fixed dimension is introduced.

The scalar algebra is reused from the already-pinned Std BitVec library. All
experiment-owned wrappers/imports are counted. This is library-assisted proof
construction, not evidence that the agent developed Std's modular arithmetic
from scratch. New theorem axiom dependencies are exactly propext and Quot.sound;
all prior theorem dependency sets and stricter certificate gates are retained.

## Overflow execution evidence

Native fixture: tests/xla/modular_arithmetic_replay_test.cc.
Archive: reports/modular-arithmetic-replay-v1, including exact fixture/BUILD,
command/events, logs, XML and binary hash. Each width uses six nonuniform input
cells containing zero, one, the maximum word, high bit, maximum-minus-one and3,
with independent second operands/shared factors. All modules are ordinary
same-shape rank1 arrays; general rank/size comes from the Lean theorem, not
extrapolation from these fixtures.

| Native recipe | Corresponding value law |
| --- | --- |
| x+0 | add_rhs_zero |
| 2+x → x+2 | add_comm |
| (x+2)+3 → x+(2+3) | add_assoc |
| x*c+y*c → (x+y)*c | factor_right |
| x*0 | mul_rhs_zero |
| x*1 | mul_rhs_one |
| (-x)*(-y) → x*y | mul_neg_neg |
| (x*2)*(y*3) → (x*y)*(2*3) | four_factors |

Eight recipes × three widths × three modes give72 native runs and432 checked
output cells, also checked in their original graphs. Every intended handler/
pass case reports change; no-rewrite controls report no change. All rewritten
modules pass HloVerifier. The unsigned C++ reference uses defined uint64_t wrap
and masks narrower widths; the separate Python reference uses unbounded integer
arithmetic followed by modulo2^width. Neither asks the simplifier for its expected
answer. The author is the same agent; separate implementations are not an
independent semantic/source review.

Lean probes actually evaluate both original and replacement Tensor expressions
on the same vectors, yielding24 model rows with all cells retained. At width8,
255+2 decodes to1, rather than257. The negative kernel control rejects decoding
255+1 as the unbounded Nat value256. Modular word equality must not silently
become equality of unbounded natural sums.

The native data validates eight displayed source recipes. The other eight laws
remain kernel-checked value evidence awaiting their own source controls and
review. No floating, signed or complex native execution is claimed here.
Likewise, this does not discharge constant matching/evaluation, index pullbacks,
metadata, aliases, control-order/refinement or insertion-before-skip outcomes.
Those remain required in the whole-source track.

## Validation and burden

The complete checkpoint passes52 tool/evidence tests, all Lean proofs, axiom
audits, positive probes, false-proof rejection and native evidence checks.
Mutation controls reject a floating/unbounded profile, source acceptance,
claimed source review, missing rules/runs, erased overflow, broadened execution
scope and disagreement in the Lean model output. Review packets now retain the
new value theorem links with null accepted source proofs.

| Lean category | Previous | Current | Added |
| --- | ---: | ---: | ---: |
| S semantics | 612 | 612 | 0 |
| H shared support | 751 | 751 | 0 |
| R rule proofs | 504 | 574 | 70 |
| A imports/checking | 24 | 25 | 1 |
| C certificates | 236 | 236 | 0 |
| Total | 2127 | 2198 | 71 |

There are now64 value theorems and69 shared support lemmas, with pure/effectful
graph rules and diagnostic certificates counted in separate fields. These are
not accepted source-rewrite counts. Tests/audits are separately measured in
reports/pilot-values.json. The reused scalar laws are in Std, already part of
the disclosed dependency baseline. New non-Lean files are measured separately:

| Artifact | Physical lines | Bytes |
| --- | ---: | ---: |
| modular_arithmetic_cases.py | 27 | 1092 |
| check_modular_arithmetic_evidence.py | 80 | 6274 |
| run_modular_arithmetic_replay.py | 78 | 4259 |
| modular_arithmetic_replay_test.cc | 125 | 6500 |

snapshots/modular-arithmetic-pilot-v2.zip and
reports/modular-arithmetic-clean-replay-v2.json preserve fresh Lean replay
without Lake caches, matching measurements/model outputs and all prior axiom
sets. V1 preserves the earlier draft mapping wording; v2 clarifies arbitrary
shared factors versus source constant/broadcast construction without changing
proofs. The replay is by the same agent and does not rebuild native XLA in the
fresh directory.

Next numerical work includes source AnyOrder/broadcast bridges and signed/
other integral representation, then floating/complex exceptions and permitted
observations. Guard/API/frame and all-schedule graph correspondence still apply
to these short algebraic proofs. Independent semantic census/pilot review,
remaining operator families, the whole campaign and final research verdict
remain open.

Fresh Lean snapshot SHA256: a6f66658c7bd5b7e73818c87ec4091d7a09535f5fba092fdd6583529d9663e04.
