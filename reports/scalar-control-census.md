# Numerical/control source-schema batch

Source revision: e58e523b11f1fde802a493a776d158007486e1bf.
File: xla/hlo/transforms/simplifiers/algebraic_simplifier.cc.
Extractor: tools/extract_scalar_control_cases.py.
Data: census/scalar-control-cases.json; census/site-case-map.json.

This batch records 55 schemas across 14 handlers: Abs, Clamp, Log, Convert,
CustomCall, Power, Rsqrt, ReducePrecision, Select, Scatter, Sort, Sqrt, Map and
Conditional. It covers all 44 lexical replacement sites within these handlers.
It also records Convert's delegated helper rather than treating the helper call
as an established identity. Source extraction remains primary-agent reviewed.

When this batch was added, the combined three batches had 133 schema bindings, 113 distinct lexical
replacement sites bound and 231 replacement candidates unmapped. Lexical sites
include declarations elsewhere and are not an authoritative rewrite count.
Multiple source cases can share one replacement call; intermediate mutations
can belong to one source case. No full-source proof is accepted by this update.

## Splits that affect the eventual statements

- Select permits scalar predicates for tensor results. Its Boolean identities
  explicitly broadcast the predicate or its negation when required. These are
  rank/shape conditions, not a proof solely about one Bool value.
- Predicate compare/select has six directions, sharing four replacement calls.
  Operand-pointer relationships and the PRED comparison contract are retained.
- Select with a dynamic-update branch is split by branch orientation and by
  scalar/tensor predicate. Tensor predicates are sliced at the same indices;
  scalar predicates remain scalar. Dynamic index clamping and update extents
  require shared slice/update semantics before acceptance.
- Conditional rewrites an integer-index branch arrangement into a Boolean
  arrangement with explicit true/false branch and argument reversal. Branch
  effects, selector conversion and traversal reachability remain obligations.
- The rank-one PadToStatic/SliceToDynamic custom-call roundtrip has raw and
  clamped size paths. Their ABI contracts are not inferred just from the names.
- Map's Parameter-root handler returns even when compatibility replacement
  fails. Extraction distinguishes a successful rewrite from a successful handler
  return. Unused computation operations/effects require review.

## Numerical caution

Log(Sqrt(a)), Log(Rsqrt(a)), the two Rsqrt rewrites and several Power branches
have no local fast-math guard. Their source descriptions are not asserted to be
equal over real numbers, complex numbers, or finite machine floats interchangeably.
Rounding, overflow/underflow, NaNs, zeros and domain/branch conventions matter.

The complex Sqrt-square path creates a real Abs then converts its result back
to the complex type. An independent statement of fast-math permissions is needed
to assess the principal-root/modulus relationship. A fast-math option is not
permission to use each desired identity as its own axiom.

IsNonNegative and IsConvertPairNoOp are retained as helper dependencies to expand,
not replaced with stronger mathematical premises. Constant-folding delegates to
Literal.Convert, whose conversion/error behavior is part of the source contract.
ReducePrecision's full-width condition also needs exceptional/subnormal review.

## Validation and limits

The extractor checks pinned owner bounds and body hashes, exact replacement
line/call/text and selected-handler replacement coverage. Negative controls
remove a Sqrt branch, alter a source line/body identity and fabricate acceptance;
all must be rejected. The combined mapping and structural review ledger also
pass their omission controls. The integrated checkpoint passes.

These checks catch bookkeeping mistakes. They do not prove guard translation,
helper closure, all indirect graph effects, type-profile exhaustiveness or source
correspondence. Lean source size remains unchanged by this extraction update;
no new Lean code or rule-specific human proof was introduced. The experiment's
whole-file outcome remains open.
