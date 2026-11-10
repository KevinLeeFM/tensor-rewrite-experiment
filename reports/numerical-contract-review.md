# Primary-source review of the nonfinite profile

Revision: e58e523b11f1fde802a493a776d158007486e1bf.
Evidence files/hashes: sources/numerical-contract-manifest.json.

## Source evidence

- xla/xla.proto:273–282 describes xla_cpu_enable_fast_math as enabling unsafe
  assumptions, including absence of NaNs/infinities and indistinguishable signed
  zeros. The nearby honor_nans/honor_infs flags constrain enabled fast math.
- xla/debug_options_flags.cc:287–294 defaults CPU fast math to false and the
  honor flags to true. Fast min/max is a separate setting; it is explicitly
  disabled in the latest replay, rather than relied upon for multiplication.
- xla/service/cpu/cpu_compiler.cc:366–377 propagates the module CPU fast-math flag
  into AlgebraicSimplifierOptions::enable_fast_math. It also derives min/max NaN
  propagation from the separate fast-min/max flag.
- The hardware-independent test base's standard GetDebugOptionsForTest reads
  flags and enables an evaluator fast path. Its separate SetAotFastMathDebugOptions
  helper enables unsafe math only when called. A grep hit in that helper is not
  evidence that all fixture modules use unsafe math.
- The existing MultiplyOfConvertedPred test (:14777 onward) checks Select shape
  and layout and reruns the verifier; it does not compare nonfinite values.

Superseded as a whole-pass inference by the arithmetic census below:

Inference: these sources support preserving nonfinite classification in a CPU
profile with unsafe math disabled. This is a narrower requirement than exact
rounding or NaN-payload equality. They do not establish every backend's numerical
guarantees, and this review is not independent semantic adjudication.

Current interpretation: the flag documentation motivates the special-value
profile as a hypothesis, but it does not establish a whole-pass guarantee.
HandleAdd's documented distributivity permission (:1035–1086) admits some
floating rounding/underflow/overflow differences through a power-of-two guard
even when general fast math is disabled. Thus classification preservation
cannot be inferred globally from that flag alone. The intended contract of
HandleMultiply/predicate-convert still needs case-specific adjudication; neither
the source comment about another family nor the flag descriptions settle it.
The six observed changes and conditional Lean refutation remain reproducible.
Why the earlier reading was plausible: it traced the module flag into the pass
but had not yet inspected all family-specific numerical permissions. Details:
reports/arithmetic-census.md.

## Replay with explicit settings

reports/xla-replay-v3/result.json records all six mismatches with runtime assertions
for CPU fast math=false, honor_nans=true, honor_infs=true, evaluator fast path=false,
and AlgebraicSimplifier fast math=false. Fast CPU/GPU min/max settings are also
disabled in the fixture. Original and rewritten graphs are evaluated through
the actual pinned evaluator; the pass changes Multiply to Select and NaN to zero.

This addresses reliance on environment/test defaults and the evaluator's optional
fast path. The build succeeds and successful test events, source and binary
identities are archived. V1/V2 observations remain historical evidence rather than
being overwritten. The offline checker verifies the strict settings and source
hashes without pretending to execute the pass again.

## Relationship to the Lean certificate

The Lean necessary exceptional-result relation rejects the observed output,
independently of finite rounding and NaN sign/payload. Its refinement theorem
transfers that rejection to any stronger semantics satisfying the necessary
condition. Actual source observations, primary-source intent evidence and the
formal certificate are distinct parts of the argument; no trusted C++ extraction
or complete backend semantics has been proved here.

Remaining review: validate the chosen profile independently, audit source/contract
correspondence and classify this source case in the final census. The whole-file
automatic verification question and other rewrite families remain open.
