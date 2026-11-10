# Scalar movement across Select: native replay and algebraic certificate

Source: XLA e58e523b11f1fde802a493a776d158007486e1bf,
xla/hlo/transforms/simplifiers/algebraic_simplifier.cc:638–822 and :11223–11276.
Pass SHA256: 1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f.
Source case: ScalarMultiplyReduction/target-output.

## Observed native behavior

The exact pinned pass changes a legal F32 convolution's value when scalar
movement traverses alternative Select branches. Inputs and filter are all ones.
The input tensor is [1,4,1], filter [4,1,1], output [1,1,1], with one-dimensional
window size4 and b0f_0io->b0f dimension labels. The convolution input is
Select(predicate,2*input,3*input). The output is smaller than either operand,
so ScalarMultiplyReduction selects the output as its scale target.

It visits both branch multiplications, removes their scales from the Select
edges, accumulates both constants and moves their product6 to the output. The
resulting graph is 6*Conv(Select(predicate,input,input),filter).

| Scalar movement | Uniform predicate | Original | Rewritten |
| --- | --- | --- | --- |
| disabled | false | 12 | 12 |
| disabled | true | 8 | 8 |
| enabled | false | 12 | 24 |
| enabled | true | 8 | 24 |

These are finite, exactly representable small values; NaNs, infinities, signed
zeros and subnormal behavior are not used. Both original and resulting modules
verify. This is a value-preservation failure under the recorded pass/evaluator
configuration, not a shape failure or a claim about every production backend.

The test disables general fast math, enables NaN/infinity honoring, disables the
evaluator fast path, disables convolution operand swapping/pad folding/oneDNN,
sets layout-sensitive mode, disables convolution simplification and runs one
pass iteration. The canonical compiler pass is unchanged. Only diagnostic test
sources and a BUILD target are added to the isolated checkout.

Fresh replay: `python tools/run_scalar_select_replay.py --archive scalar-select-replay-vN`
with an unused N. The accepted run is reports/scalar-select-replay-v2/result.json.
It archives fixture, BUILD, Bazel command/events/logs/XML and binary/source hashes,
using --nocache_test_results. Offline integrity and observation checking is
`python tools/check_scalar_select_replay_evidence.py`; that checker does not run XLA.

The first archive, scalar-select-replay-v1, is preserved as a failed diagnostic.
Its disabled-option control incorrectly expected changed=false: the separate
SimplifyConvToMultiply helper ran even with enable_conv_simplification=false.
Its observed enabled value changes are not used as the passing isolated test.
The v2 fixture sets layout-sensitive mode to block that unrelated helper; both
disabled controls now satisfy changed=false and both enabled cases changed=true.

## What Lean establishes

TensorRewrite/Pilot/SelectContraction.lean defines exact integer contraction
against a unit filter by a recursive list sum. branchContraction selects a scale2
or3 for each element using a uniform Boolean predicate. hoistedContraction removes
both branch scales and multiplies the resulting contraction by their product6.
These meanings are written independently of any theorem acceptance checker.

SelectContractionLemmas.lean proves, for arbitrary finite lists, that the original
is the selected coefficient times the sum and the replacement is six times the
sum. SelectContractionRefutation.lean proves they differ whenever the sum is
nonzero, checks both four-one witness values, and refutes the universal identity.
The zero-sum/empty controls also check equal cases, preventing an indiscriminate
rejection model. An invalid equality proof is required to fail.

The stronger nonzero-sum theorem and its two support lemmas depend only on
standard propext/Quot.sound. The two concrete witness theorems and
not_universally_valid have EMPTY axiom dependencies. Existing numerical/shape
certificate empty-dependency gates are preserved. The new general theorem has
its own explicit standard-axiom allowance; it introduces no arithmetic assumption
or axiom asserting that the source rewrite succeeds or fails.

This refutes the algebraic identity in the mathematical-integer track. The native
test supplies the F32 source-level observation. Lean does not yet prove the
binary32 exact-arithmetic bridge, convolution's complete rank/geometry contract,
the C++ traversal or graph/source correspondence. It is therefore not recorded
as an accepted complete XLA-facing source theorem. A small fixed witness suffices
for refutation; successful universal verification still requires source generality.

## Burden, replay and campaign status

The current development is S161/H83/R172/A10/C133, total559 custom Lean code
lines. The previous total was501; the increase58 consists of new model13,
support17, certificates27 and import1. Tests and the axiom audit are reported
separately. There are 41 positive value theorems, eleven supporting lemmas,
seventeen refutation theorems and four concrete shape/algebraic witness facts,
plus the two earlier contract-consistency facts. Full source acceptance remains0.

snapshots/scalar-select-certificates-v1.zip preserves the complete current pilot,
accounting tools, ledgers, fixtures and measurement. A fresh-directory replay
without .lake checks the build, axiom audit, positive/negative controls and matching
size/dependency outputs; see reports/scalar-select-certificate-clean-replay.json.
It is a clean replay by the same agent, not independent review.

The integrated checkpoint additionally checks all native archives, discovery
ledgers and source identities. New archive controls reject falsely claiming
equality or omitting a disabled-option observation even after updating log hashes.

This provides another diagnosed source case, including a finite algebraic failure
outside the earlier exceptional-value question. It does not finish the complete
semantic census, independent source reconciliation, diverse pilot or all-obligation
campaign. The whole-file workflow verdict remains open; a negative claim about
all possible LLM/Lean workflows would not follow from this counterexample.
