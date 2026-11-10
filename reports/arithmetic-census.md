# Addition, division and min/max source census

Source pin: e58e523b11f1fde802a493a776d158007486e1bf.
File: xla/hlo/transforms/simplifiers/algebraic_simplifier.cc.
Extractor/data: tools/extract_arithmetic_cases.py; census/arithmetic-cases.json.

## Source coverage

The batch contains 85 source schemas: Add19, Divide15, Maximum17, Minimum11 and
Compare23. Every one of the five handlers' 64 lexical replacement sites is bound. Five
source-inspected helper records include exact function ranges and original-body
hashes. They are not accepted mathematical specifications or a proof of helper
correctness. All source/type/numerical correspondence remains pending review.

At the collective/comparison checkpoint, the six batches had 296 schema bindings,
235 distinct lexical replacement sites bound and 109 replacement candidates
unmapped. These discovery counts are not the verification denominator. Helper
closures, indirect writes, datatype/configuration profiles and independent
semantic reconciliation are still incomplete.
README.md carries the current aggregate totals after later source batches.

## Important source details

- Add contains direct and broadcast constant reassociation paths, both operand
  orders of subtraction cancellation, partial dynamic-update movement and four
  shared-factor orientations. The distributivity condition is integral output,
  enable_floats_are_real or IsAllFpConstantPowerOf2(c); it is not simply the
  general enable_fast_math flag.
- Add/scatter can concatenate two scatters, nest them through three sequential
  calls, or mutate a single scatter's base before replacing the Add. The mapping
  preserves each complete sequence in source order, including its operand writes.
  Counts and aliases, concat-dimension selection, update windows, reducer bodies,
  collision order and numerical association remain obligations.
- Divide's integral early return occurs after power-of-two and special exp/power/
  sqrt/rsqrt paths, before constant reciprocals and nested quotients. Later
  source conditions inherit that nonintegral restriction. Merely reading each
  local if-condition would omit it.
- TryDivideToShift distinguishes signed and unsigned types. The signed version
  forms a modular negation/select, logical shift, then restores the sign. A proof
  over unbounded positive naturals would miss minimum signed values and legal
  sub-byte widths. Denominators must be effective-scalar constants, direct or
  broadcast, with the source's single-bit and positivity checks.
- InvertConstant uses the host native scalar type through Literal.Populate;
  constant division is not merely an exact rational reciprocal. Several Divide
  identities lack local fast-math guards, while broadcast reciprocal movement
  explicitly requires CPU execution, sink-broadcast and fast math.
- Min/max records the remaining operand's type check when eliminating extrema
  because floating input and result types can differ. Nested-right-second
  simplification mutates an operand while deliberately retaining an ordering
  that the source says affects NaN sign. This is not an unordered lattice law
  under every possible observation relation.
- MinMaxToClamp reshapes bound literals to scalar and evaluates lower<upper.
  It returns a Clamp only for a true result and otherwise returns null; statuses
  can abort the path. Maximum's monotone sinking uses the concrete opcode
  whitelist Cbrt, Erf, Logistic and Tanh. The classification helper is not a
  mathematical proof about every backend implementation of those operators.
- Compare retains unsigned-zero, nonnegative, integral-self and PRED cases,
  causal-mask folding and four in-place min/max operand updates. The last two
  require failure of the enclosing Maximum matcher before the Minimum branch
  can be reached. See reports/compare-census.md for the exact branch distinctions.

## Numerical-contract correction

Add's comment at :1035–1075 explicitly permits rounding, underflow and overflow
differences for shared floating powers of two, and describes the broader
enable_floats_are_real permission. The guard at :1077–1086 can select that rule
even with general fast math disabled. This defeats an inference that that flag
alone guarantees exact IEEE arithmetic, or universal classification preservation,
throughout the whole pass. Other numerical settings and per-family permissions
must be reviewed rather than replaced by a convenient blanket premise.

This does not erase the six predicate-multiply observations under explicit module
settings or the Lean theorem refuting them under the necessary IEEE contract.
It changes what source intent can be inferred from those settings. The intended
contract for that specific replacement remains unresolved; a source-supported
test hypothesis is not an adopted whole-pass semantics. See the correction in
reports/numerical-contract-review.md and its notebook trail.

Comments documenting intended errors are evidence to interpret. They are not
themselves a sufficiently precise observation/refinement relation, and each
desired rewrite must not become an axiom defining its own permission. The
experiment must retain exact and permitted-error tracks separately.

## Validation

The batch validator checks source bounds/body/site identity, complete lexical
replacement coverage within the selected handlers, all sequential writes and
helper source integrity. The combined mapping now rejects changes to mutation
order as well as omissions, even when all site identities remain present.
Controls remove a scatter mutation, reverse its ordered mapping, drop a helper,
alter a body hash and fabricate helper acceptance; each is rejected.

All twenty-four Python tool/evidence tests and the integrated checkpoint pass,
including the unchanged Lean development and archived real-XLA replays. No new
Lean code is added: S148/H66/R172/A9/C106, total501, remains the checked baseline.
No source proof is promoted. The complete census, campaign, diagnosis and final
LLM/Lean feasibility verdict remain open.
