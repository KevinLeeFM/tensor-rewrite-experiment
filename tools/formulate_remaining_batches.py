"""Freeze explicit mathematical proposals for retained records; no C++ or source-guard translation."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE_REVISION = '22cb0da0897299ea0cff4662fa205705062677c0'
BATCHES = ('simple','arithmetic','scalar-control','shape','tensor-index','layout','dot')
PROPOSALS = {}


def add(batch, group, ids, domains, target, premises, residuals, risks=()):
    """Every member is explicitly named; no prefix or wildcard admission is used."""
    for name in ids.split():
        assert name not in PROPOSALS,name
        PROPOSALS[name] = dict(batch=batch,classification=group,candidate_domains=domains.split(),
                              proposed_mathematical_target=target,
                              explicit_mathematical_premises=premises,
                              remaining_mathematical_partitions=residuals,
                              mathematical_risks=list(risks))


# Scalar pointwise and finite-product proposals. IEEE domains are always separate.
add('simple','typed_boolean_word_identities','''HandleAnd/lhs-true HandleAnd/lhs-zero HandleAnd/rhs-true HandleAnd/rhs-zero HandleOr/lhs-true HandleOr/lhs-zero HandleOr/rhs-true HandleOr/rhs-zero HandleNot/involution HandleXor/equal-inputs HandleXor/lhs-zero HandleXor/rhs-zero''',
 'predicate arbitrary_width_bitvector pure_graph effect_graph',
 'Prove the retained pointwise Boolean/bitwise expression, then shape-preserving constant/Broadcast construction and the declared graph observations.',
 ['All finite ranks/extents; actual constant values and scalar types; XOR-equal requires equality of the two input values, not just unrelated syntax.'],
 ['The existing closed value family is narrower than the entire graph/effect record; PRED true is not arbitrary-width word1 as an all-ones mask.',
  'Constant recognition, discarded operands and control prerequisites must have mathematical value/effect contracts; external IR correspondence is future work.'])
add('simple','negation_involution','HandleNegate/involution','exact_ring arbitrary_width_bitvector binary_float_bits',
 'Double scalar negation and its arbitrary-rank tensor lift preserve the declared value or stored-bit observations.',
 ['Use additive negation for exact rings/modular words and actual sign-bit negation for the floating profile.'],
 ['NaN payload, signaling/quiet behavior and exception flags are separate from the already checked stored-bit involution.'])
add('simple','ordered_compare_intersection','''TrySimplifyTautologicalCompare/Lt-Lt TrySimplifyTautologicalCompare/Lt-Gt TrySimplifyTautologicalCompare/Gt-Lt TrySimplifyTautologicalCompare/Gt-Gt''',
 'signed_word_order linear_order',
 'Normalize all four retained comparison operand orientations and prove that intersecting strict upper bounds is comparison with their minimum.',
 ['The same value is compared to both bounds; the chosen signed/linear order and constant representations are explicit.'],
 ['Use actual signed32 values for the word profile; floating unordered comparisons and external matcher identity are not inherited.'])
add('simple','tuple_projection','HandleGetTupleElement/tuple-projection','pure_tuple effect_graph',
 'Projection from a typed finite tuple returns the selected component, with legal index and tensor shape.',
 ['Typed tuple arity, selected bounded index and component result shape.'],
 ['Eliminating evaluation of other tuple fields can alter effects; pure projection does not close the graph observation partition.'])
add('simple','complex_pair_projection','''HandleComplex/components HandleReal/complex-projection HandleReal/noncomplex HandleImag/complex-projection HandleImag/noncomplex''',
 'exact_complex complex_pair_bits pure_tensor',
 'Define Complex/Real/Imag as an admitted pair construction/projection and prove the exact retained projection or noncomplex embedding equation.',
 ['The reconstructed real/imaginary pair uses the same source value for Complex(Real(a),Imag(a)); noncomplex embedding has explicit zero imaginary part.'],
 ['Actual component conversions, signed zero, NaN payloads and representation admission require separate bit-level profiles.'])
add('simple','unit_axis_iota','HandleIota/trivial-axis','bounded_index arbitrary_width_bitvector exact_integer',
 'A bounded coordinate on an extent-zero/one axis produces the zero tensor at every existing output coordinate.',
 ['A legal selected axis and derived extent at most one; actual scalar conversion of coordinate zero.'],
 ['Empty output is vacuous and must not fabricate a zero coordinate; format-specific zero encodings remain explicit.'])
add('simple','exponential_zero','HandleExp/zero-scalar HandleExp/zero-broadcast','exact_real exact_complex rounded_transcendental',
 'Prove Exp(0)=1 for the admitted scalar operation and lift through the exact scalar/Broadcast shape map.',
 ['Actual zero and one representations and legal Broadcast output shape.'],
 ['Exact analysis and rounded executable exp are different operators; exceptional flags and format-specific transcendental implementations remain open.'])
add('simple','subtraction_ring','''HandleSubtract/self HandleSubtract/zero HandleSubtract/constant HandleSubtract/broadcast-constant HandleSubtract/sub-sub-self HandleSubtract/sub-add-self-left HandleSubtract/add-sub-self-left HandleSubtract/sub-add-self-right HandleSubtract/add-sub-self-right''',
 'exact_ring arbitrary_width_bitvector binary_float_bits',
 'Prove each retained oriented subtraction/cancellation equation in an exact ring or actual modular word algebra, retaining any constant Broadcast map.',
 ['Explicit equal-value occurrences for self/cancellation; constant negation and both operand orders use the actual scalar algebra.'],
 ['Rounded subtraction, reassociation, NaN/infinity and signed-zero observations need independent domains; a fast-math label is not a ring axiom.'])
add('simple','multiplication_ring','''HandleMultiply/rhs-one HandleMultiply/rhs-zero HandleMultiply/lhs-one HandleMultiply/lhs-zero HandleMultiply/negated-operands HandleMultiply/four-factors HandleMultiply/constant-product HandleMultiply/broadcast-factor HandleMultiply/legacy-constant-product-direct HandleMultiply/legacy-constant-product-broadcast-scalars''',
 'exact_ring arbitrary_width_bitvector binary_float_bits',
 'Prove the retained zero/one/sign/factor-grouping multiplication graph with its exact operand orientation and scalar/Broadcast constant shapes.',
 ['Ring/modular multiplication and actual same-width literals; nontrivial Broadcast maps must be derived from legal attributes.'],
 ['IEEE annihilation, associativity and literal folding are separate; NaN/infinity, underflow/overflow and signed zero cannot be dropped.'])
add('simple','absolute_square','HandleMultiply/abs-square','linear_ordered_ring binary_float_bits',
 'Prove Abs(a)*Abs(a)=a*a in the independently admitted real/ordered scalar domain and its tensor lift.',
 ['A specified absolute-value operation and scalar multiplication; complex modulus is outside the noncomplex profile.'],
 ['Machine signed-min absolute value, floating exception/status and stored zero signs require independent treatment.'])
add('simple','predicate_product_select','HandleMultiply/predicate-convert','exact_ring arbitrary_width_bitvector binary_float_bits effect_graph',
 'Compare actual conversion of predicate to zero/one followed by multiplication against Select(predicate,x,zero).',
 ['Pure predicate conversion to actual scalar zero/one; output tensor/Broadcast shapes specified.'],
 ['The exact/word law does not establish the floating branch: existing exceptional-product certificates expose NaN/infinity failures under exact stored-value observations.',
  'Discarded operand effects and any allowed numerical refinement relation remain independent.'],['known_exceptional_value_counterexample_partition'])
add('simple','transcendental_multiply','HandleMultiply/exp-product HandleMultiply/sqrt-square HandleMultiply/rsqrt-square',
 'exact_real exact_complex rounded_transcendental',
 'Formulate the actual retained exp/sqrt/rsqrt multiplication identity under independently stated real or principal-complex domains.',
 ['Explicit exp/sqrt/reciprocal meanings, nonnegative or positive input conditions where needed, and the actual output algebra.'],
 ['Zero, negative/complex branch cuts, NaN/infinity and rounded transcendental behavior must remain separate; option names do not justify exact identities.'])
add('simple','convolution_delegation','HandleMultiply/conv-reorder-delegation','exact_contraction ordered_float_contraction',
 'Select and define the concrete convolution/add/multiply replacement graph before proving any equality.',
 ['An explicit mathematical graph, convolution dimension/window attributes and scalar accumulation observations.'],
 ['The retained helper-dependent rhs is not a unique mathematical expression; do not substitute an arbitrary convenient graph.'],['retained_target_not_explicit'])

# Addition, division, ordered min/max and comparison.
add('arithmetic','additive_ring','''HandleAdd/rhs-zero HandleAdd/lhs-zero HandleAdd/constant-right HandleAdd/constant-sum-direct-constants HandleAdd/constant-subtract-direct-constants HandleAdd/constant-sum-broadcast-scalars HandleAdd/constant-subtract-broadcast-scalars HandleAdd/cancel-subtract-lhs HandleAdd/cancel-subtract-rhs''',
 'exact_ring arbitrary_width_bitvector binary_float_bits',
 'Prove the retained oriented zero/commutation/reassociation/cancellation addition graph and preserve constant Broadcast coordinates.',
 ['Actual exact-ring or modular-word operation; identical repeated values and explicit scalar constants.'],
 ['IEEE zero signs, NaNs and rounded grouping cannot inherit ring laws; separately specify numerical permission/refinement and literal evaluation.'])
add('arithmetic','add_dynamic_update','HandleAdd/partial-update-lhs HandleAdd/partial-update-rhs',
 'bounded_dynamic_index exact_ring arbitrary_width_bitvector binary_float_bits',
 'Derive inside/outside clamped-update cases and prove the retained Add/DynamicSlice/DynamicUpdateSlice graph pointwise.',
 ['Legal base/update extents; explicit signed/unsigned index decoder and clamp; same actual update location and zero base.'],
 ['Outside-update addition by zero needs a scalar law; IEEE signed zero and discarded operand/effect observations require separate domains.'])
add('arithmetic','distributive_factoring','HandleAdd/factor-lhs-lhs HandleAdd/factor-lhs-rhs HandleAdd/factor-rhs-lhs HandleAdd/factor-rhs-rhs',
 'exact_ring arbitrary_width_bitvector binary_float_bits',
 'Prove the common-factor graph for all four recorded Multiply operand orientations using independently admitted distributivity.',
 ['Exact ring/modular word algebra and the same factor value; shapes and Broadcast constant maps explicit.'],
 ['A floating power-of-two factor alone does not establish distributivity across overflow, underflow, subnormals or differing rounding; those domains need proof/refutation.'])
add('arithmetic','scatter_add_fusion','HandleAdd/scatter-concat HandleAdd/scatter-nested HandleAdd/scatter-single-rhs HandleAdd/scatter-single-lhs',
 'ordered_scatter exact_ring arbitrary_width_bitvector binary_float_bits',
 'Define actual Scatter update sequences/dimension maps, then compare concatenated, nested or changed-base scatter graphs with their original update order.',
 ['A precisely defined two-argument update reducer, duplicate-index policy, out-of-bounds policy and legal dimension attributes.'],
 ['An Add-shaped reducer root is not enough to assume distinct parameter roles: retain p0+p0 and p1+p1 partitions alongside p0+p1.',
  'Repeated indices and floating reassociation/order require explicit observations; tuple batching/output maps and effects remain open.'],['reducer_parameter_role_gap','duplicate_index_order_gap'])
add('arithmetic','division_identity','HandleDivide/one','exact_field truncating_integer arbitrary_width_bitvector binary_float_bits',
 'Prove division by actual one under each admitted scalar division meaning, then lift to tensor shape.',
 ['Actual one encoding and explicit unsigned/signed/truncating or field division operation.'],
 ['Signaling NaNs, payload changes and exception status are not established by a field identity.'])
add('arithmetic','division_power_mask','HandleDivide/power-two-unsigned HandleDivide/power-two-signed',
 'arbitrary_width_bitvector',
 'Prove actual power-of-two unsigned quotient by logical shift; signed quotient uses Select, modular magnitude negation, logical shift and sign correction.',
 ['Represented positive power divisor; exponent/width and signed positivity bounds; actual shift-count semantics.'],
 ['Signed minimum and sub-byte widths need general proofs, not a positive signed absolute-value assumption; zero/negative divisor extensions stay explicit.'])
add('arithmetic','transcendental_division','''HandleDivide/exp-pair HandleDivide/exp-denominator HandleDivide/power-denominator HandleDivide/sqrt-denominator HandleDivide/rsqrt-denominator''',
 'exact_real exact_complex rounded_transcendental',
 'Formulate the retained quotient-to-product identity using independently defined exp, power, sqrt, rsqrt and reciprocal operators.',
 ['Explicit real or principal-complex domain and nonzero denominators as required by the chosen total/partial model.'],
 ['Zero, infinities, branch cuts, overflow/underflow and rounded operation paths require separate statements; no option label is treated as an algebra law.'])
add('arithmetic','field_division_reassociation','''HandleDivide/constant-direct HandleDivide/constant-broadcast HandleDivide/broadcast-reciprocal HandleDivide/fractions HandleDivide/nested-numerator HandleDivide/nested-denominator HandleDivide/predicate-scalar-broadcast''',
 'exact_field exact_complex binary_float_bits',
 'Prove the retained reciprocal/fraction graph under independently stated denominator conditions and derive all actual Broadcast shapes.',
 ['A specified field or partial reciprocal operation and actual constant inversion; nonzero denominator/cross-product conditions must be established independently.'],
 ['Totalized zero cases and predicate-false times an infinite reciprocal may refute unrestricted equality.',
  'Rounded inverse literals, double rounding, overflow/underflow and NaN/zero-sign/flag observations need independent profiles.'])
for owner in ('HandleMaximum','HandleMinimum'):
 add('arithmetic',owner+'_semilattice',' '.join(owner+'/'+s for s in ('self','lhs-extreme','rhs-extreme','nested-left-lhs','nested-left-rhs','nested-right-first','nested-right-second')),
  'linear_order signed_word_order unsigned_word_order binary_float_bits',
  'Prove the retained idempotent/absorptive/extreme min/max graph in an explicit order, preserving operand priority where observations distinguish ties.',
  ['An admitted min/max operation, actual lower/upper extreme and repeated value occurrences; arbitrary tensor shape.'],
  ['IEEE unordered NaNs, payload propagation, signed-zero ties and native finite extrema are not inherited from LinearOrder.'])
 add('arithmetic',owner+'_clamp',' '.join(owner+'/clamp-'+s for s in ('lhs-lhs','lhs-rhs','rhs-lhs','rhs-rhs')),
  'linear_order signed_word_order unsigned_word_order binary_float_bits',
  'Derive the retained min/max operand orientations and prove equality with the independently specified Clamp(lower,x,upper).',
  ['Actual lower/upper values with independently established ordering and legal scalar Broadcast output maps.'],
  ['Clamp definition, NaN propagation, equal-bound/zero-sign ties and constant comparison semantics require separate domains.'])
add('arithmetic','clamp_absorption','HandleMaximum/clamp-lower-lhs HandleMaximum/clamp-lower-rhs','linear_order binary_float_bits',
 'Prove that the actual Clamp output absorbs the repeated lower bound under Maximum in both orientations.',
 ['A declared clamp definition and ordered bounds; exact repeated lower value.'],
 ['Floating NaN/zero-sign behavior is an independent operation contract, not a consequence of an ordered scalar theorem.'])
add('arithmetic','monotone_max_naturality','HandleMaximum/sink-cbrt HandleMaximum/sink-erf HandleMaximum/sink-logistic HandleMaximum/sink-tanh',
 'exact_real rounded_transcendental',
 'Prove f(max(x,y))=max(f(x),f(y)) from an independently proved monotonicity theorem for the actual selected unary operation.',
 ['Explicit cbrt/erf/logistic/tanh meaning and the chosen order on its real scalar domain.'],
 ['Rounded implementation monotonicity, NaN/zero signs and exceptional/flag observations remain to be instantiated; a helper label is not a proof.'])
add('arithmetic','compare_nonnegative','''HandleCompare/unsigned-lt-zero HandleCompare/unsigned-ge-zero HandleCompare/unsigned-zero-gt HandleCompare/unsigned-zero-le HandleCompare/nonnegative-lt HandleCompare/nonnegative-gt HandleCompare/nonnegative-ge HandleCompare/nonnegative-le''',
 'unsigned_word_order linear_order binary_float_bits',
 'Prove each retained oriented comparison-to-zero constant under the actual unsigned or explicitly nonnegative scalar order.',
 ['An independent nonnegativity predicate and its semantic implication; exact comparison direction and zero value.'],
 ['Floating unordered comparisons distinguish Lt=false from Ge=true on NaN; nonnegative recognition is not adopted as an axiom.'])
add('arithmetic','compare_reflexive',' '.join('HandleCompare/integral-self-'+s for s in ('gt','lt','ne','eq','ge','le')),
 'signed_word_order unsigned_word_order exact_integer',
 'Evaluate the six actual reflexive comparison directions on the same integer/word value, pointwise.',
 ['The same value and a declared signed/unsigned comparison interpretation.'],
 ['IEEE NaN comparisons are a different profile; discarded operand effects need a graph contract.'])
add('arithmetic','predicate_comparison','''HandleCompare/predicate-ne-rhs HandleCompare/predicate-ne-lhs HandleCompare/predicate-eq-rhs HandleCompare/predicate-eq-lhs HandleCompare/causal-mask''',
 'predicate pure_tensor',
 'Prove the recorded predicate comparison or Select/ones/zeros mask equals its retained predicate expression at each coordinate.',
 ['Actual Boolean values, compatible shapes and the specified comparison direction; numerical one/zero conversions explicit for causal-mask.'],
 ['Nonpredicate numeric mask conversions, scalar Broadcast maps and graph effects require separate statements.'])
add('arithmetic','ordered_minmax_comparison','HandleCompare/maximum-first HandleCompare/maximum-second HandleCompare/minimum-first HandleCompare/minimum-second',
 'linear_order signed_word_order unsigned_word_order binary_float_bits',
 'Prove the four retained Gt/min/max equations with the actual operand ordering and repeated values.',
 ['An explicit scalar order and min/max semantics; arbitrary tensor shape.'],
 ['NaN propagation and unordered comparisons can invalidate ordered proofs; binary floating domains remain independent.'])

# Scalar analysis, conversion, selection, tuples and control.
add('scalar-control','absolute_nonnegative','HandleAbs/nonnegative','linear_ordered_ring arbitrary_width_bitvector binary_float_bits',
 'Prove Abs(x)=x on an independently specified nonnegative domain, including the actual tensor shape.',
 ['A declared scalar absolute value and a proved semantic nonnegativity premise.'],
 ['Signed minimum and NaN/negative-zero stored bits or status do not inherit a real absolute-value theorem.'])
add('scalar-control','clamp_idempotence','HandleClamp/idempotent HandleClamp/runtime-id','linear_order bounded_runtime_id binary_float_bits',
 'Prove retained clamp idempotence, or runtime-ID clamp elimination using the independently bounded integer ID range.',
 ['The actual clamp definition and bound values; runtime ID lies in the finite participant/partition interval.'],
 ['Module/participant count and finite-width upper+1 overflow are mathematical bounds to prove, not imported guard assumptions; floating ties/NaNs remain separate.'])
add('scalar-control','logarithm_domains','HandleLog/exp HandleLog/power-real HandleLog/power-complex HandleLog/sqrt HandleLog/rsqrt',
 'exact_real principal_complex rounded_transcendental',
 'Formulate the retained logarithm equation with actual real/principal-complex exp, power, sqrt or reciprocal-sqrt operations and independently derived domains.',
 ['For each branch, explicitly quantify the base/exponent and define power at zero and negative/complex bases; principal argument ranges are part of the mathematical domain.'],
 ['Existing exact log/exp and sqrt domain theorems cover only stated profiles; branch cuts, zero and complex powers must not be erased.',
  'Rounded transcendental implementations and numerical permission/refinement remain open.'])
add('scalar-control','conversion_roundtrip','HandleConvert/same-type HandleConvert/noop-pair HandleConvert/constant-fold',
 'scalar_conversion arbitrary_width_bitvector binary_float_bits',
 'Define each source/destination scalar conversion and prove the retained identity, roundtrip or literal-value equality in its independently specified domain.',
 ['Explicit source/intermediate/destination formats, signedness, rounding/saturation rules and actual constant values.'],
 ['Value preservation of the roundtrip is a theorem obligation, not an assumed meaning of a helper name; NaN payloads, flags and out-of-range behavior remain explicit.'])
add('scalar-control','binary_conversion_delegation','HandleConvert/binary-surround-delegation','scalar_conversion arbitrary_width_bitvector',
 'Select the concrete narrow/wide binary conversion graph, then state the actual operation-specific roundtrip equation.',
 ['An explicit replacement operator and source/intermediate/result scalar formats.'],
 ['The retained helper-dependent graph does not determine a unique mathematical target; arithmetic quotient and modular operations cannot be merged.'],['retained_target_not_explicit'])
add('scalar-control','dynamic_shape_roundtrip','HandleCustomCall/dynamic-roundtrip-raw-size HandleCustomCall/dynamic-roundtrip-clamped-size',
 'dynamic_shape pure_tensor',
 'Define PadToStatic and SliceToDynamic on values and runtime extents, then prove the actual raw or clamped size tuple roundtrip.',
 ['Rank-one bounded runtime extent, actual static capacity, shared value/size provenance and explicit clamp semantics.'],
 ['Static tensor equality alone does not specify dynamic size observations; custom-call effects, error/status and memory/layout observations remain open.'])
add('scalar-control','custom_layout_constraint','HandleCustomCall/layout-identity HandleCustomCall/layout-copy','physical_layout effect_graph',
 'Give LayoutConstraint and Copy independent value/layout/effect meanings and compare the exact retained identity/copy target.',
 ['Explicit logical shape, storage map and observable memory/layout/transfer behavior.'],
 ['Treating both custom calls as identity on a pure tensor would omit the layout and effect observation contract.'])
add('scalar-control','power_special_exponent','HandlePower/zero HandlePower/one HandlePower/two HandlePower/three HandlePower/minus-one HandlePower/half HandlePower/exp-base',
 'exact_ring exact_real principal_complex rounded_transcendental',
 'Define the chosen power operation and prove the actual retained exponent specialization, multiplication order, reciprocal or exp-base graph.',
 ['Explicit exponent representation and power convention; independently stated base domains, including nonnegative half-power and nonzero reciprocal cases where required.'],
 ['Integer power, real rpow and principal complex power differ at zero/negative bases; they need distinct statements.',
  'Rounded power is not definitionally repeated multiplication or sqrt; signed zero, overflow/underflow and branch/status observations remain open.'])
add('scalar-control','reciprocal_sqrt_domains','HandleRsqrt/inverse-square HandleRsqrt/reciprocal','exact_real principal_complex rounded_transcendental',
 'Compare the retained reciprocal-sqrt graph using independently defined reciprocal, power and sqrt operations.',
 ['Explicit nonnegative/positive base conditions and chosen total/partial zero behavior.'],
 ['Zero and infinity, principal complex branches, rounded reciprocal/sqrt composition and flags require separate partitions.'])
add('scalar-control','precision_identity','HandleReducePrecision/full-width','binary_float_bits',
 'Define precision reduction on actual floating encodings and prove full exponent/significand precision leaves all declared observations unchanged.',
 ['Exact format widths, rounding/canonicalization and subnormal rules.'],
 ['NaN payload/quieting, signaling flags and signed zero remain to be checked; matching width numbers alone is not a proof.'])
add('scalar-control','pure_select','''HandleSelect/equal-values HandleSelect/true HandleSelect/false HandleSelect/not-predicate HandleSelect/true-false-direct HandleSelect/true-false-broadcast HandleSelect/false-true-direct HandleSelect/false-true-broadcast HandleSelect/boolean-compare-gt HandleSelect/boolean-compare-ge HandleSelect/boolean-compare-lt HandleSelect/boolean-compare-le HandleSelect/boolean-compare-eq HandleSelect/boolean-compare-ne''',
 'predicate pure_tensor effect_graph',
 'Prove the exact retained Select/Not/Boolean-comparison expression pointwise and derive any scalar-predicate Broadcast target.',
 ['Actual predicate shape and Boolean ordering; repeated branches are equal values and the data tensors have compatible shapes.'],
 ['Whole-graph evaluation/effect/control prerequisites are distinct from pointwise selection; dropping a branch is not automatically effect-preserving.'])
add('scalar-control','select_dynamic_update','''HandleSelect/update-false-tensor-pred HandleSelect/update-false-scalar-pred HandleSelect/update-true-tensor-pred HandleSelect/update-true-scalar-pred''',
 'bounded_dynamic_index predicate pure_tensor',
 'Prove each oriented Select/DynamicUpdateSlice equation by deriving clamped update membership and the sliced local predicate/data coordinates.',
 ['Legal base/update extents, actual shared clamped indices and scalar versus tensor predicate shapes.'],
 ['Index decoders and conversion representability require actual word domains; mathematical graph effects and external admission remain open.'])
add('scalar-control','empty_scatter','HandleScatter/empty-updates HandleScatter/empty-indices','ordered_scatter pure_tuple',
 'Specify Scatter update iteration and prove either empty-update identity or the exact empty-index coordinate mapping to Map, preserving tuple packaging.',
 ['Actual update/index shapes and dimension attributes; no invented implication that empty indices always mean no updates.'],
 ['Index-vector-dimension and rank-zero index behavior, reducer coupling, duplicate/out-of-bounds policy and effects remain to be formalized.'])
add('scalar-control','trivial_sort','HandleSort/trivial-single HandleSort/trivial-tuple','ordered_sort pure_tuple effect_graph',
 'Define axis Sort and prove empty/extent-at-most-one tensors preserve component values and tuple packaging.',
 ['Legal axis and compatible operand shapes; explicit comparator call and stability semantics.'],
 ['Comparator effects, NaN/tie semantics, output shape and layout/observation partitions remain separate even when a pure permutation is trivial.'])
add('scalar-control','square_root_square','HandleSqrt/square-complex HandleSqrt/square-real','exact_real principal_complex rounded_transcendental',
 'Prove or refute the retained sqrt(a*a)=Abs(a) or complex embedding of Abs(a) under explicitly derived principal-branch domains.',
 ['Exact real versus complex definitions and actual modulus embedding; domains must be independent of the desired equation.'],
 ['Existing complex counterexamples and necessary/sufficient exact domains must be retained; rounded multiplication/sqrt and overflow are separate.'],['principal_branch_counterexample_partition'])
add('scalar-control','map_root_evaluation','HandleMap/parameter-root HandleMap/constant-root-scalar HandleMap/constant-root-broadcast HandleMap/elementwise-root',
 'pure_nary_map pure_tensor effect_graph',
 'Define n-ary pointwise Map with bounded parameter selection and prove the retained parameter/constant/elementwise-root evaluation graph.',
 ['Legal parameter indices, scalar operation arity, input/output shapes and actual constant values.'],
 ['Tuple results, effects, scalar-versus-Broadcast output and external expression admission need explicit partitions.'])
add('scalar-control','conditional_boolean_conversion','HandleConditional/predicate-convert','predicate pure_branch effect_graph',
 'Define indexed two-branch Conditional and predicate conversion; prove exact argument/branch swap with observed selected-branch result.',
 ['Conversion maps false/true to the explicit branch indices, and each branch/argument has a typed common output observation.'],
 ['Branch execution, exceptions, effects and control dependencies must be specified; pointwise Select is not by itself a Conditional execution proof.'])

# Shape transformations: actual bounded maps and output well-formedness must be derived.
add('shape','logical_reshape','HandleReshape/empty HandleReshape/identity HandleReshape/compose',
 'bounded_index pure_tensor physical_layout',
 'Define logical equal-count row-major reshape and prove the retained empty/identity/composition graph including derived output shape and bounded coordinates.',
 ['Legal shapes with the required actual element counts; any physical layout observation is an additional independent contract.'],
 ['Zero dimensions and count-zero linearization need separate bounds; a layout-preserving physical bitcast is not implied by logical reshape.'])
add('shape','random_shape_change','HandleReshape/rng-shape HandleTranspose/rng-shape','random_distribution stateful_rng',
 'Specify whether changing RNG result shape preserves distribution, a common flattened sample stream, state transition or all of these, then compare the retained graph.',
 ['An independent random generator/state/sampling contract with actual element count, indexing order and output shape.'],
 ['No probability/stateful RNG model is presently instantiated; equal element count does not prove identical seeded samples, state consumption or joint distributions.'],['rng_observation_contract_missing'])
add('shape','reverse_algebra','HandleReverse/trivial-dimensions HandleReverse/cancel HandleReverse/symmetric-difference',
 'bounded_index pure_tensor',
 'Derive bounded reversal coordinates, normalize repeated legal axes and prove the retained identity or symmetric-difference tensor graph.',
 ['Legal axis lists and exact finite shape extents; extent-one and empty axis-list cases explicit.'],
 ['Axis-list multiplicity, zero extents and physical/effect observations require distinct admission proofs; existing mask/axis models cover only their declared conventions.'])
add('shape','reverse_elementwise','HandleReverse/binary-scalar-0 HandleReverse/binary-scalar-1','bounded_index pure_nary_map',
 'Prove reversal commutes with the actual pure binary operation when the other operand is a scalar Broadcast, preserving operand orientation.',
 ['The same coordinate map applies to nonconstant data and the scalar Broadcast is constant on every output index.'],
 ['Actual binary scalar operation admission and effects are independent of pure map naturality.'])
add('shape','unit_dimension_reindex','HandleReverse/inserted-unit-dimensions HandleReshape/dynamic-update-unit-dims',
 'bounded_index bounded_dynamic_index pure_tensor',
 'Derive insertion/deletion of unit axes and prove the retained Reverse or DynamicUpdateSlice remapping with actual new axes/indices.',
 ['Explicit unit-axis descriptor, bounded inverse coordinate maps and legal clamped update extents/indices.'],
 ['Zero extents, deleted versus inserted dimensions, scalar ranks and finite-width index conversions must be discharged rather than assumed through a shape descriptor.'])
add('shape','slice_basic','HandleSlice/identity HandleSlice/compose-unstrided','bounded_index pure_tensor',
 'Derive legal ordinary Slice output extents and bounded sampling; prove the exact identity or translated unstrided composition.',
 ['Valid starts/limits/positive strides and explicit input/output extents; legality of each transformed Slice is a conclusion obligation.'],
 ['Equal output extents alone need not specify every Slice map without using legality; empty intervals and finite attribute arithmetic remain explicit.'])
add('shape','slice_pad','HandleSlice/padding-only HandleSlice/undo-pad HandleSlice/inside-pad','bounded_index pure_tensor',
 'Compose independent Pad occupancy and Slice sampling; derive the retained fill, inverse-Pad or translated inner-Slice graph and its shape.',
 ['Actual Pad low/high/interior attributes and legal Slice bounds; original fill and stride semantics retained.'],
 ['Negative edges, interior holes, empty inputs/outputs and exact transformed limits require separate partitions.'])
add('shape','transpose_algebra','HandleTranspose/identity HandleTranspose/compose','bounded_index pure_tensor',
 'Prove the exact decoded permutation identity/composition with bounded indices and derived output extents.',
 ['A legal bijective permutation with actual composition order and input/output shape relationship.'],
 ['Sorted-legal implies identity only after legality; physical bitcast layout, effects and any external array decoding remain separate.'])
add('shape','reshape_copy_layout','HandleReshape/copy-reorder HandleReshape/bitcast-chain','bounded_index physical_layout',
 'Define the exact chosen chain ancestor or aligned reshape/copy target, then derive logical and physical coordinate/byte-map equivalence.',
 ['Explicit shapes, storage layout maps, tiles, memory-space observation and the selected concrete target.'],
 ['A profitability test is not a semantic premise; logical equal-count reshape does not establish physical allocation/transfer or alias observations.'])
add('shape','reshape_broadcast','HandleReshape/broadcast','bounded_index pure_tensor',
 'Derive which input Broadcast dimensions survive the logical reshape and prove the retained remapped Broadcast graph.',
 ['Explicit legal shapes, Broadcast dimensions and reshape factor boundaries; count and map equalities must be proved.'],
 ['Unit/zero axes and mixed factor groups need an actual inverse index construction; no shape helper result is treated as the desired map theorem.'])
add('shape','reshape_iota_mixed_radix','HandleReshape/iota-mixed-radix','bounded_index exact_integer arbitrary_width_bitvector',
 'Derive the source Iota coordinate from output mixed-radix coordinates and prove the retained sum/product of actual same-width output Iotas.',
 ['Explicit factor boundaries and legal reshape counts; actual term coefficients and coordinate-conversion widths.'],
 ['Zero factors, division/remainder-by-zero, wrapped Iota arithmetic and coefficient representability remain independent partitions.'])
add('shape','shape_helper_target','''HandleReshape/transpose-chain-delegation HandleReshape/transpose-hoist-delegation HandleSlice/scalar-slice-delegation HandleSlice/reshape-reorder-delegation HandleSlice/reverse-reorder-delegation HandleSlice/stride-delegation HandleTranspose/scatter-fold-delegation HandleTranspose/chain-delegation HandleTranspose/broadcast-delegation''',
 'bounded_index physical_layout',
 'Choose the concrete mathematical replacement expression for the retained delegation and derive its shape and coordinate relation.',
 ['An explicit helper-result graph, not merely a changed/success status.'],
 ['The retained helper-dependent rhs does not determine a single expression; related explicit helper schemas may supply candidate targets but correspondence is not presumed.'],['retained_target_not_explicit'])
add('shape','unit_chain_composition','''TryRemovingBitcastOrReshapeTransposeChain/layout-identity TryRemovingBitcastOrReshapeTransposeChain/layout-bitcast TryRemovingBitcastOrReshapeTransposeChain/logical-identity''',
 'bounded_index physical_layout',
 'Compose the actual finite sequence of unit-axis reshape, transpose and bitcast maps and derive the retained ancestor or final bitcast target.',
 ['An explicit well-formed chain and independently specified logical/physical maps for every node.'],
 ['An accumulated permutation being identity does not by itself prove byte-map or effect equivalence; zero/unit axes and final target shape remain proof obligations.'])
add('shape','transpose_contiguous_chunks','TryHoistTransposeOfReshape/contiguous-chunks','bounded_index pure_tensor',
 'Derive contiguous factor chunks, their order and the exact new reshape/permutation maps for the retained transpose hoist.',
 ['Legal input/intermediate/output shapes and an explicit sorted chunk decomposition with product equations.'],
 ['Chunk coverage, zero products, split/merged axis boundaries and actual bounded coordinate roundtrips remain to be proved.'])
add('shape','slice_dynamic_update','HandleSlice/exact-dynamic-update HandleSlice/inside-dynamic-update','bounded_dynamic_index bounded_index pure_tensor',
 'Prove that a legal ordinary Slice lies exactly within the independently clamped update region, deriving the returned update or translated Slice of it.',
 ['Explicit original index decoder, clamped starts, legal extents and ordinary Slice bounds/strides.'],
 ['Signed/unsigned index conversion, empty updates and physical/effect observations remain separate.'])
add('shape','slice_broadcast','HandleSlice/broadcast-only-dims HandleSlice/broadcast-sink','bounded_index pure_tensor',
 'Project actual Slice starts/limits/strides onto mapped Broadcast axes and derive either unchanged small input or its smaller Slice.',
 ['A legal Broadcast axis map and ordinary Slice attributes; transformed output shapes and ceiling counts are derived.'],
 ['Slicing only replicated dimensions, arbitrary striding, unit/empty axes and transformed attribute legality need distinct index arguments.'])
add('shape','slice_dot','HandleSlice/dot-operands','bounded_index exact_contraction ordered_float_contraction',
 'Move output Slice coordinates into the corresponding free/batch Dot operand coordinates while preserving the contracted fiber and output shape.',
 ['Explicit Dot batch/contracting/free axis maps, legal Slice bounds and unchanged contraction geometry.'],
 ['Precision/conversion/initializer/ordered accumulation and legal transformed dimension lists must be handled separately.'])
add('shape','slice_concatenation','''HandleSlice/concat-exact-piece HandleSlice/concat-subrange-single HandleSlice/concat-subrange-multi TrySimplifyScalarSlice/concat-piece TrySimplifyScalarSlice/concat-slice''',
 'bounded_index pure_tensor',
 'Derive prefix-sum piece selection, translated bounds and retained element order for the exact/subrange/scalar Slice of Concatenate graph.',
 ['Compatible piece shapes, actual concatenation axis and legal Slice interval/stride; transformed Slice bounds proved.'],
 ['Empty pieces, boundary-equal intervals and empty output must not be hidden by prefix selection; rank-one scalar helper is not a general-rank theorem.'])
add('shape','slice_full_window','HandleSlice/reduce-window','bounded_index ordered_reduction pure_tensor',
 'Compose the actual output Slice with an ordered window and derive the corresponding Reduction/Reshape graph and complete contribution sequence.',
 ['Explicit original window/padding, Slice bounds and selected effective reduction axes; actual reducer/initializer retained.'],
 ['Contribution order, implicit padding, mixed kept/reduced axes and the exact output-bound relation need a separate proof from a canonical full-span model.'])
add('shape','transpose_dot_swap','HandleTranspose/dot-canonical HandleTranspose/dot-general','bounded_index exact_contraction ordered_float_contraction',
 'Derive actual swapped Dot operands, batch/free/contracting axis lists and the output permutation; prove the retained tensor equation.',
 ['Legal Dot dimension maps and actual scalar product/accumulation contract with operand-specific precision.'],
 ['Multiplication order for noncommutative/rounded domains, precision swapping and fiber enumeration order must be justified independently.'])
add('shape','transpose_to_reshape','HandleTranspose/degenerate-reshape','bounded_index pure_tensor',
 'Derive that the legal permutation only moves unit axes and equals the actual logical Reshape map.',
 ['A legal permutation and explicit nonunit-axis order with compatible product shapes.'],
 ['Zero extents, all-unit/scalar shapes and physical layout equivalence require independent partitions.'])
add('shape','transpose_physical_bitcast','HandleTranspose/layout-bitcast','physical_layout bounded_index',
 'Prove the actual transpose coordinate-to-byte map equals the retained physical bitcast, including valid output shape.',
 ['Explicit storage layout/order, element encoding, tiles and memory-space observations.'],
 ['A virtual bitcast predicate result cannot substitute for a byte-map theorem; logical coordinate equality alone does not close this profile.'])
add('shape','space_depth_slices','HandleTranspose/space-depth-user-mutation','bounded_index pure_tensor',
 'Derive the split-axis reshape/transpose/reshape map and show the actual finite Slice/Concatenate target preserves every output coordinate.',
 ['Explicit chunk count, chunk extent, axis positions, product equations and legal slice/concat attributes.'],
 ['Zero chunk count, empty dimensions, unsplit axes and output shape must be proved; user replacement effects are outside the pure tensor equation.'])
add('shape','slice_reshape_commute','TryToReorderSliceAndReshape/leading-slice','bounded_index pure_tensor',
 'Derive the leading Slice interval in source mixed-radix coordinates and prove the exact Slice/Reshape target with legal new limits.',
 ['Explicit nonzero suffix products, divisibility, no-spill factor conditions and legal input/output shapes.'],
 ['Zero factors and empty intervals require separate domains rather than division by an assumed nonzero product; transformed bounds remain proof conclusions.'])
add('shape','slice_reverse_commute','TryToReorderSliceAndReverse/commute','bounded_index pure_tensor',
 'Compare the actual retained reverse/Slice transformed bounds and output order using the chosen signed integer division convention.',
 ['All legal original Slice intervals, including empty ones, and legal reversed axes; do not assume original nonempty unless studying a clearly partial profile.'],
 ['Existing empty-slice certificates show the literal transformed formula can change zero output extent; positive repaired statements and the original counterexample must stay distinct.'],['known_empty_shape_counterexample_partition'])
add('shape','slice_stride_removal','RemoveRedundantStride/single-element-axes','bounded_index pure_tensor',
 'Derive output counts under the actual retained start+1 and stride1 replacement, including shape legality and zero/one-element partitions.',
 ['Legal original Slice attributes and the explicit selected-axis inequalities; no invented start<limit premise for the whole record.'],
 ['Existing empty-interval certificates refute unrestricted retained-shape preservation; any nonempty repaired domain remains a partial result.'],['known_empty_shape_counterexample_partition'])
add('shape','transpose_scatter','TryFoldTransposeIntoScatter/simplified-scatter','bounded_index ordered_scatter',
 'Derive the exact operand/update transposes and remapped Scatter dimension numbers, then preserve the actual indexed update trace.',
 ['A precisely defined simplified Scatter, legal permutation and explicit index/update/batch dimension maps.'],
 ['Repeated updates, out-of-bounds indices, tuple reducers, order/precision and effect observations require independent handling.'])
add('shape','transpose_broadcast','SimplifyTransposeOfBroadcast/mapped-dims-logical SimplifyTransposeOfBroadcast/mapped-dims-layout',
 'bounded_index physical_layout pure_tensor',
 'Derive inverse-permutation mapped Broadcast dimensions, their legality/order and the actual output coordinate map.',
 ['Legal original Broadcast axes and permutation/view attributes; explicit output layout if observed.'],
 ['Logical versus physical view semantics, unit/empty dimensions and layout-sort predicates must be proved in their own models.'])

# Tensor indexing and update graphs.
add('tensor-index','concatenation_identities','''HandleConcatenate/unary HandleConcatenate/filter-all-empty HandleConcatenate/filter-one-nonempty HandleConcatenate/filter-many-nonempty HandleConcatenate/flatten HandleConcatenate/adjacent-slices''',
 'bounded_index pure_tensor',
 'Define Concatenate by ordered prefix extents and prove the exact retained filtering/flattening/adjacent-Slice merging graph with derived shapes.',
 ['Compatible nonconcatenated extents, legal axis and actual operand order; original Slice attributes legal.'],
 ['All-empty operands, zero nonconcatenated dimensions and adjacency on every relevant axis require explicit proofs.'])
add('tensor-index','concatenation_padding','HandleConcatenate/pad-low HandleConcatenate/pad-high','bounded_index pure_tensor',
 'Prove the actual low/high Concatenate-with-uniform-tensor equals independently defined Pad, preserving scalar fill and output extents.',
 ['Explicit concatenation axis, constant-side extent, fill scalar and derived nonnegative Pad edge sizes.'],
 ['Both sides uniform, empty inputs and arbitrary other extents require their actual side/priority convention.'])
add('tensor-index','concatenation_unit_repeat','HandleConcatenate/repeat-unit-axis','bounded_index pure_tensor',
 'Delete the repeated operand unit axis by logical Reshape and derive Broadcast of the original operand for the actual repetition count.',
 ['The same operand tensor on every occurrence; input concatenation-axis extent1; explicit nonempty operand list and target axis map.'],
 ['Other empty axes, output repetition extent and physical observations require separate admission.'])
add('tensor-index','broadcast_reshape_transpose','HandleBroadcast/reshape HandleBroadcast/transpose','bounded_index pure_tensor',
 'Derive the equal-count Broadcast coordinate map as the actual logical Reshape or inverse-permutation Transpose.',
 ['A legal injective Broadcast axis map, actual input/output extents and equal element counts.'],
 ['Zero counts may make extent inferences invalid; sorted/order cases and physical layouts need distinct proofs.'])
add('tensor-index','broadcast_unit_axes','HandleBroadcast/inserted-unit-axes HandleBroadcast/drop-unit-axes','bounded_index pure_tensor',
 'Derive deletion/insertion of unit input dimensions and the filtered Broadcast attribute list, proving actual target shape and indexing.',
 ['Explicit unit-axis descriptor and legal Broadcast map; transformed lists preserve order and bounds.'],
 ['Zero axes, scalar ranks, mixed inserted/deleted descriptors and physical observations remain explicit.'])
add('tensor-index','broadcast_user_delegation','HandleBroadcast/sink-users-delegation','pure_nary_map bounded_index',
 'Select the exact smaller elementwise/Broadcast user graph before proving a pure tensor naturality equation.',
 ['An explicit replacement expression and legal operand Broadcast maps.'],
 ['The retained helper-dependent collection of user replacements is not one mathematical graph; no convenient target is silently substituted.'],['retained_target_not_explicit'])
add('tensor-index','uniform_view_users','''HandleBroadcast/scalar-user-reshape HandleBroadcast/scalar-user-reverse HandleBroadcast/scalar-user-transpose HandleBroadcast/scalar-user-sort HandleBroadcast/scalar-user-slice HandleBroadcast/scalar-user-dynamicslice''',
 'bounded_index ordered_sort pure_tensor effect_graph',
 'For each actual retained view/selection/Sort operator, prove a uniform scalar input yields the retained uniform tensor at its derived output shape.',
 ['A precise operator meaning and legal output shape; Sort tuple/comparator and DynamicSlice decoder are explicit.'],
 ['Uniform values do not prove shape legality, dynamic-size preservation or operator effects; each operator needs its own admission/observation domain.'])
add('tensor-index','broadcast_iota_compose','HandleBroadcast/iota HandleBroadcast/compose','bounded_index arbitrary_width_bitvector pure_tensor',
 'Derive the composed Broadcast axis map or remapped Iota coordinate and prove the exact retained tensor graph.',
 ['Legal actual Broadcast attributes, coordinate scalar encoding and output extents.'],
 ['Finite-width Iota conversion, zero extents and nontrivial dimension ordering remain explicit.'])
add('tensor-index','pad_empty_unit','HandlePad/empty-input HandlePad/unit-interior HandlePad/compatible','bounded_index pure_tensor',
 'Define independent Pad occupancy and prove the actual empty-fill, unit-axis interior erasure or identity target.',
 ['Actual edge/interior attributes, positive occupied spacing and legal output extents.'],
 ['Zero edges alone do not erase nonzero interior spacing on a nonunit populated axis; use shape/count conditions explicitly, without importing compatibility as a value axiom.',
  'Negative edges, empty domains and zero-sign/encoding of fill remain separate.'])
add('tensor-index','pad_broadcast_projection','HandlePad/broadcast-projection','bounded_index pure_tensor',
 'Derive the smaller Broadcast/Pad graph from the explicitly padded output-axis subset and show complete occupied-coordinate/fill agreement.',
 ['Legal Broadcast axis injection, actual Pad edge/interior configurations and the exact padded-axis projection list.'],
 ['Dropping unpadded axes, repeated extents, empty inputs and interior holes require bounded inverse maps and output-shape proofs.'])
add('tensor-index','negative_padding','HandlePad/negative-edges','bounded_index pure_tensor physical_layout',
 'Prove independent signed-edge Pad equals nonnegative Pad followed by an ordinary legal cropping Slice.',
 ['Actual signed edges, interior spacing and legal retained output shape; derive positive Pad and Slice starts/limits.'],
 ['Overcropping, empty original input and integer/word attribute representability require precise domains; do not assume transformed Slice legality.'])
add('tensor-index','dynamic_slice_basic','HandleDynamicSlice/scalar HandleDynamicSlice/same-shape HandleDynamicSlice/zero-full-axis-indices','bounded_dynamic_index pure_tensor',
 'Derive the clamped DynamicSlice map and prove scalar/same-shape identity or zero replacement of full-axis start indices.',
 ['Explicit input/result extents, actual signed/unsigned index decoding and saturating clamp.'],
 ['Dynamic extents, representability of bounds, async/effect observations and output well-formedness need independent contracts.'])
add('tensor-index','dynamic_slice_views','''HandleDynamicSlice/broadcast-scalar HandleDynamicSlice/broadcast-array HandleDynamicSlice/unit-reshape HandleDynamicSlice/transpose''',
 'bounded_dynamic_index bounded_index pure_tensor',
 'Derive the exact selected/remapped DynamicSlice indices and sizes through Broadcast, unit-axis Reshape or Transpose.',
 ['Legal view maps, shape extents and actual decoded clamping on corresponding axes.'],
 ['Zero extents, removed axes, signed/unsigned conversion and physical/effect observations cannot be inferred from a shape equality alone.'])
add('tensor-index','constant_dynamic_slice','HandleDynamicSlice/constant-indices','bounded_dynamic_index bounded_index pure_tensor',
 'Evaluate actual constant index decoding and clamp, then prove the corresponding ordinary Slice has legal starts/limits and equal values.',
 ['Explicit integral index constants, input/result extents and output shape.'],
 ['Negative versus unsigned constants, source-width limits and empty shapes require separate cases; no external literal-decoder correspondence is asserted.'])
add('tensor-index','iota_dynamic_slice','''HandleDynamicSlice/iota-plain-same-type HandleDynamicSlice/iota-plain-convert HandleDynamicSlice/iota-scaled-same-type HandleDynamicSlice/iota-scaled-convert''',
 'bounded_dynamic_index arbitrary_width_bitvector pure_tensor',
 'Derive the rank-one singleton DynamicSlice of actual same-width Iota, retaining scalar multiplication, clamp bound and optional output conversion.',
 ['Explicit input/index/result widths and signedness, nonempty legal singleton slice, actual multiplier value and clamp-limit encoding.'],
 ['Iota coordinate wrapping, differing index/element ranges, signed minimum and multiplication order require independent representation proofs.'])
add('tensor-index','nested_dynamic_slice','HandleDynamicSlice/nested','bounded_dynamic_index arbitrary_width_bitvector pure_tensor',
 'Compose the two actual saturating index clamps and conversions and prove the resulting bounded DynamicSlice map.',
 ['Legal inner/outer sizes, actual index widths and sufficient representability of each clamped displacement and final sum.'],
 ['Mixed signed/unsigned decoding, overflow and empty dimensions require derived bounds; source fit-helper names are not adopted proofs.'])
add('tensor-index','scaled_nested_dynamic_slice','HandleDynamicSlice/nested-after-scaled-probe',
 'bounded_dynamic_index arbitrary_width_bitvector pure_tensor',
 'Compare the literal retained target, which discards multiplication, against the actual scaled nested slice on legal data/indices.',
 ['Legal nested slice shapes and actual arbitrary scalar multiplier; do not insert a multiplier-one premise into the whole-record target.'],
 ['Existing mathematical scaled-slice diagnostics/refutations must remain distinct from corrected targets that preserve multiplication; source correspondence stays deferred.'],['known_discarded_multiplier_counterexample_partition'])
add('tensor-index','dynamic_update_pad','HandleDynamicUpdateSlice/pad-scalar-list HandleDynamicUpdateSlice/pad-tuple HandleDynamicUpdateSlice/pad-concatenate',
 'bounded_dynamic_index bounded_index pure_tensor',
 'Prove DynamicUpdateSlice of a uniform base equals independently constructed Pad with clamped low/high edges, decoding each retained index packaging.',
 ['Legal update/base extents and explicit scalar-list, tuple or concatenated index representation; actual fill scalar.'],
 ['Index container decoding, signed/unsigned clamp, empty updates and effect/transfer observations need separate domains.'])
add('tensor-index','dynamic_update_basic','HandleDynamicUpdateSlice/full-update HandleDynamicUpdateSlice/zero-full-axis-indices HandleDynamicUpdateSlice/empty-update',
 'bounded_dynamic_index pure_tensor',
 'Derive exact update membership and prove full-update identity, zeroing of full-axis starts or empty-update identity.',
 ['Legal extents and actual saturating decoded start indices; output shape equals base.'],
 ['Empty coordinate domains, dynamic extents and effect/representation observations are not supplied by pure function equality.'])
add('tensor-index','dynamic_update_pad_concat','HandleDynamicUpdateSlice/pad-concat-high HandleDynamicUpdateSlice/pad-concat-low',
 'bounded_dynamic_index bounded_index pure_tensor',
 'Prove an update exactly fills the low/high Pad edge and equals the retained oriented Concatenate of original data and update.',
 ['Explicit one-sided nonnegative edge padding, exact update extents and clamped location, no interior holes.'],
 ['Other-axis extents, empty cases, boundary saturation and physical layout require independent admission.'])
add('tensor-index','nested_dynamic_update','HandleDynamicUpdateSlice/nested','bounded_dynamic_index arbitrary_width_bitvector pure_tensor',
 'Compose the actual outer DynamicSlice/update region with the inner update and prove the retained summed-clamp DynamicUpdateSlice graph.',
 ['Shared original base/decoded slice location, legal nested extents and sufficient conversion/sum bounds.'],
 ['Mixed-width signedness, overflow and exact inside/outside regions require a full index proof; graph alias/effects are separate.'])
add('tensor-index','gather_empty','HandleGather/empty-input','bounded_gather pure_tensor',
 'First derive the legal empty-input Gather result domain; then compare the retained zero tensor only where the independently specified operator gives that result.',
 ['An explicit Gather slice-size/dimension map and an independently chosen undefined/empty/out-of-bounds behavior.'],
 ['An empty input does not by itself define nonempty Gather values as zero; prove output empty from legality or expose the missing semantic convention.'],['empty_input_gather_domain_gap'])
add('tensor-index','gather_effective_scalar','HandleGather/effective-scalar-rank-zero HandleGather/effective-scalar-unit-array',
 'bounded_gather bounded_index pure_tensor',
 'Derive Gather coordinates on a one-element input and prove the exact scalarization/Broadcast graph with inferred output shape.',
 ['Legal Gather dimensions, index policy and actual singleton input representation.'],
 ['Clamping/out-of-bounds semantics, empty indices and dynamic/physical observations remain explicit.'])
add('tensor-index','gather_select_chain','HandleGather/small-select-chain','bounded_gather arbitrary_width_bitvector predicate',
 'Define the exact typed threshold Select chain and compare it with actual Gather index decoding/clamping at every admitted word value.',
 ['Rank-one data, explicit data extent, index vector convention and actual signed/unsigned comparison and threshold conversion widths.'],
 ['Unrepresentable thresholds, signedness differences and wraparound can change selection; existing bounded word witnesses are partial evidence, not a general type admission proof.'])
add('tensor-index','gather_pad_hoist','HandleGather/pad-hoist-passthrough HandleGather/pad-hoist-batching HandleGather/reshape-pad-hoist',
 'bounded_gather bounded_index pure_tensor physical_layout',
 'Derive the actual adjusted Gather sizes/indices and remapped Pad or Reshape/Pad graph, preserving occupancy and fill at every output coordinate.',
 ['Explicit passthrough/batching dimension maps, legal slices, Pad configurations and reshape factor maps.'],
 ['Unpadding batching indices, interior holes, empty domains, physical bitcast requirements and actual result shape remain independent obligations.'])

# Physical storage, conversion and tuple observations.
add('layout','bitcast_value_maps','HandleBitcast/unary-sandwich HandleBitcast/compose-stage HandleBitcast/compatible-stage HandleBitcast/broadcast-delegation',
 'physical_layout bounded_index pure_nary_map',
 'Define actual physical bitcast byte/index maps and prove the retained unary/chain/identity/Broadcast graph with derived output shape.',
 ['Explicit element encodings, legal equal-storage shapes, layout orders/tiles and scalar operation where present.'],
 ['Byte equality and logical equal-count reshape are distinct; memory/alias/transfer and control observations require their own contracts.'])
add('layout','bitcast_helper_target','HandleBitcast/recursive-inner HandleBitcast/chain-delegation HandleBitcastConvert/concat-delegation HandleCopy/swap-delegation',
 'physical_layout bounded_index',
 'Select the actual concrete inner, chain or Concatenate replacement expression and define its independent physical map.',
 ['A unique mathematical replacement graph and input/output encoding/layout parameters.'],
 ['The retained handler/helper-dependent rhs is not a fixed expression; a successful change flag is not a semantic target.'],['retained_target_not_explicit'])
add('layout','bitcast_convert','HandleBitcastConvert/compose HandleBitcastConvert/same-physical-shape HandleBitcastConvert/last-contiguous-axis HandleBitcastConvert/compatible',
 'bit_encoding physical_layout',
 'Define bit-preserving scalar/lane reinterpretation and prove the actual composition or physical-Bitcast/identity target, including shape and storage width.',
 ['Explicit bitstream order, element widths, sub-byte packing, contiguous axis convention and total source/target storage bits.'],
 ['Endianness, padding bits, tiles and zero-size arrays require precise definitions; equal numerical element counts do not establish bit-preserving conversion.'])
add('layout','copy_layout_algebra','''HandleCopy/compose-identity HandleCopy/compose-copy HandleCopy/compatible HandleCopy/chain-bitcast HandleCopy/reshape-clone HandleCopy/reshape-reorder-new-copy-reshape HandleCopy/reshape-reorder-new-copy-bitcast HandleCopy/reshape-reorder-omit-copy-reshape HandleCopy/reshape-reorder-omit-copy-bitcast SwapCopyBitcastCopy/move-bitcast SwapCopyBitcastCopy/move-copy''',
 'physical_layout bounded_index effect_graph',
 'Derive the exact logical/physical coordinate maps of the retained Copy/Reshape/Bitcast composition and its actual chosen target.',
 ['Explicit endpoint/intermediate layouts, memory spaces, tiles, element encodings and observation of transfers/allocation/aliasing.'],
 ['A pure Copy-as-identity model omits observed storage/transfer behavior; profitability and allocation estimates are not semantic proofs.',
  'Ancestor selection, tile validity and optional omitted copies remain concrete mathematical conditions to derive, not helper-name axioms.'])
add('layout','bitcast_concat_inverse','TrySimplifyTautologicalBitcastConvert/concat','bit_encoding physical_layout bounded_index',
 'Prove inverse bitcast-conversion around actual Concatenate restores the retained original-lane Concatenate bitstream and shape.',
 ['Explicit inverse source/destination encodings, lane widths, concatenation axis and legal storage-size equations.'],
 ['Lane boundary alignment, endianness, padding bits and empty pieces require separate proofs; a source-type match alone is insufficient.'])
add('layout','literal_structure','HandleConstant/tuple HandleConstant/uniform HandleConstant/iota HandleConstant/strided-iota',
 'pure_tuple literal_values arbitrary_width_bitvector binary_float_bits',
 'Define actual literal values and prove equality with the retained recursive tuple, scalar Broadcast or same-width Iota/product construction.',
 ['Explicit tuple arities, leaf shapes/encodings and exact uniform/stride/Iota numerical predicates.'],
 ['Empty/zero-element and TOKEN domains, signed/unsigned stride wrapping, NaN/zero-bit equality and host literal recognition remain distinct mathematical partitions.'])
add('layout','barrier_tuple_projection','HandleOptimizationBarrier/prune-producer HandleOptimizationBarrier/prune-tuple',
 'pure_tuple effect_graph',
 'Define the typed tuple projection and inverse remapping of every surviving consumer, then preserve actual barrier/value/control observations.',
 ['A bounded retained-component selection and total remapping of all observed tuple projections; explicit token/effect semantics.'],
 ['Removing unused values can change evaluation/effects; preserving direct tokens alone is not a full trace theorem.',
  'Barrier semantics, component dependencies and retained multiple-user/root observations remain open independent contracts.'])

# Dot/construction records are retained as data; support records do not automatically enter N.
add('dot','bitcast_construction_support','ReplaceWithBitcast/unary','physical_layout pure_graph',
 'Specify the old unary operator and its intended relation to the constructed equal-storage Bitcast before stating any correctness equation.',
 ['Concrete old operator semantics, source/result types and complete byte/index map.'],
 ['Equal byte size alone cannot prove an arbitrary unary instruction equals Bitcast; this is a construction-support schema, not an automatically correct standalone rewrite.'],['support_schema_not_standalone_rewrite','retained_target_not_explicit'])
add('dot','replacement_context_support','ReplaceInstructionIfCompatible/single ReplaceInstructionIfCompatible/span-single ReplaceInstructionIfCompatible/span-tuple',
 'pure_graph pure_tuple effect_graph',
 'Formulate typed graph-context substitution of an independently established value/refinement equation, including tuple packaging and control observations.',
 ['An actual semantic equation/refinement for the old/new nodes, compatible typed interfaces and explicit graph observations.'],
 ['SameShape is not semantic equality; this retained support schema contributes context infrastructure rather than a standalone optimizer identity.',
  'No new external API/caller/effect correspondence audit is performed.'],['support_schema_not_standalone_rewrite'])
add('dot','narrow_wide_binary','''TryRemoveUpcastAndDowncastSurroundingBinaryOp/add TryRemoveUpcastAndDowncastSurroundingBinaryOp/subtract TryRemoveUpcastAndDowncastSurroundingBinaryOp/multiply TryRemoveUpcastAndDowncastSurroundingBinaryOp/divide TryRemoveUpcastAndDowncastSurroundingBinaryOp/remainder''',
 'arbitrary_width_bitvector scalar_conversion',
 'Prove the actual narrow/wide/narrow binary graph equals the narrow operation, separately for modular Add/Subtract/Multiply and unsigned quotient/remainder.',
 ['Explicit widths, signedness, value-preserving extension and final truncation; actual operation-specific divisor-zero convention.'],
 ['Ring homomorphism covers low-bit arithmetic but does not automatically cover quotient/remainder; signedness and exceptional division need separate statements.'])
add('dot','dot_unit_dimensions','RemoveDegenerateDimensionFromDot/direct RemoveDegenerateDimensionFromDot/reshape-result',
 'bounded_index exact_contraction ordered_float_contraction',
 'Derive removal and renumbering of actual unit Dot axes and prove the direct or result-Reshape target with exact contraction fibers.',
 ['Legal batch/contracting/free axis maps, operand shapes, unit-axis list and output dimension order.'],
 ['Empty contractions, multiplication/initializer/conversion order and exact result shape require proof; physical layouts and precision observations are separate.'])
add('dot','dot_transpose_removal','RemoveTransposesFromDotOperands/keep-order RemoveTransposesFromDotOperands/swap MoveDotParamToRhs/parameter-left',
 'bounded_index exact_contraction ordered_float_contraction',
 'Derive operand and output permutations for the retained transposed or swapped Dot graph and preserve contracted coordinate contributions.',
 ['Actual legal permutation/dimension arrays and scalar product/accumulation semantics with operand-specific precision.'],
 ['Noncommutative multiplication, rounded operand order, zero contraction and output free-axis blocks cannot be inferred from shape compatibility.'])
add('dot','dot_outer_product','''RewriteAsMultiplyDotWithZeroLhsContractingDim/casts-00 RewriteAsMultiplyDotWithZeroLhsContractingDim/casts-01 RewriteAsMultiplyDotWithZeroLhsContractingDim/casts-10 RewriteAsMultiplyDotWithZeroLhsContractingDim/casts-11''',
 'bounded_index exact_contraction ordered_float_contraction scalar_conversion',
 'Prove the actual zero-contracting-axis Dot equals normalized Broadcast/Multiply with the recorded two conversion choices and derived output axes.',
 ['Legal batch/free axis maps, actual input/result formats and independently specified product/accumulator/initializer semantics.'],
 ['A one-product floating fold can differ from a bare product through initializer zero sign; mixed precision and conversion placement require separate proofs.'],['one_product_initializer_observation_gap'])
add('dot','nested_dot_association','''AssociativeReorderNestedDot/lhs-transpose AssociativeReorderNestedDot/lhs-direct AssociativeReorderNestedDot/rhs-transpose AssociativeReorderNestedDot/rhs-direct''',
 'bounded_index exact_contraction ordered_float_contraction',
 'Derive actual nested contraction index bijections and output permutation, then prove finite-sum reassociation/distribution for the retained association.',
 ['Explicit legal axis partitions and exact semiring laws for the exact profile; actual conversion/precision and accumulation observations in any rounded profile.'],
 ['Cost/FLOP thresholds are not algebra laws; floating reassociation, overflow and repeated initialization cannot inherit exact semiring proofs.'])
add('dot','dot_reduce_multiply','RewriteBatchPlusContractingAsReduce/no-free-lhs RewriteBatchPlusContractingAsReduce/no-free-rhs RewriteBatchPlusContractingAsReduce/no-free-both',
 'bounded_index exact_contraction ordered_float_contraction scalar_conversion',
 'Derive normalized operand Broadcasts, precision-specific multiplication, accumulation conversion and actual ordered Reduction for the retained Dot.',
 ['Explicit no-free-axis partition, legal contracting/batch lists, scalar formats and actual initializer.'],
 ['Empty fibers, accumulator widths, multiple conversions and schedule/refinement observations require explicit domains; option/precision names are not semantics.'])
add('dot','empty_dot','HandleDot/empty','bounded_index exact_contraction ordered_float_contraction',
 'Derive empty output or empty contraction fibers from actual Dot dimensions and compare the retained typed zero Broadcast.',
 ['Explicit legal operand/result shapes, product and reduction initializer; distinguish empty outputs from nonempty outputs with an empty fiber.'],
 ['A typed numeric zero may differ from an actual initializer encoding/status; no value can be fabricated merely from an empty output domain.'])
add('dot','dot_helper_target','''HandleDot/outer-product-delegation HandleDot/nested-delegation HandleDot/strength-reduce-delegation HandleDot/degenerate-delegation HandleDot/transposes-delegation HandleDot/parameter-swap-delegation''',
 'bounded_index exact_contraction ordered_float_contraction',
 'Select the concrete mathematical graph from the retained Dot helper delegation before stating its universal equality/refinement target.',
 ['An explicit selected graph, dimension maps and scalar precision/accumulation contract.'],
 ['The retained helper graph is not one expression; related detailed schemas are candidate mathematical targets, not certified caller correspondence.'],['retained_target_not_explicit'])
add('dot','dot_reverse_mirror','HandleDot/mirror-reverse-lhs-to-rhs HandleDot/mirror-reverse-rhs-to-lhs',
 'bounded_index exact_contraction ordered_float_contraction',
 'Derive a simultaneous contraction-coordinate reversal moving actual Reverse from one operand to the other.',
 ['Explicit reversed contracting axes and legal operand dimension maps; chosen scalar product and accumulation order.'],
 ['A bijection preserves an exact sum but can reorder rounded contributions; actual floating schedule/refinement and empty axes remain separate.'])
add('dot','dot_pad_mirror','HandleDot/mirror-pad-lhs-to-rhs HandleDot/mirror-pad-rhs-to-lhs',
 'bounded_index exact_contraction ordered_float_contraction',
 'Derive the exact coordinate/fill transformation moving actual Pad across the contracted Dot operands.',
 ['Explicit Pad edges/interior spacing, fill values, contraction axes and actual scalar zero/annihilation/initializer behavior.'],
 ['IEEE zero times nonfinite values, negative/empty padding and changed contribution count/order need explicit domains; no general Pad-mirror law is assumed.'])
add('dot','dot_broadcast_mirror','HandleDot/mirror-broadcast-lhs-to-rhs HandleDot/mirror-broadcast-rhs-to-lhs',
 'bounded_index exact_contraction ordered_float_contraction',
 'Derive how replicated contraction coordinates transfer between actual Broadcast operands while preserving the retained tensor output map.',
 ['Legal Broadcast and Dot dimension maps, repetition extents and explicit scalar product/accumulation algebra.'],
 ['Multiplicity, removed axes, empty repetitions and rounded accumulation/conversion require independent proofs.'])
add('dot','dot_contracting_reorder','HandleDot/reorder-contracting-lhs HandleDot/reorder-contracting-rhs',
 'bounded_index exact_contraction ordered_float_contraction',
 'Derive the actual reshape/transpose factor map and corresponding constant-operand transformation without assuming contraction sample equality.',
 ['Explicit consecutive unsquished contracting factors, legal permutation/reshape shapes and original operand orientation.'],
 ['Zero/unit factors, mixed precision and any changed accumulation order remain distinct domains.'])
add('dot','dot_concat_partition','HandleDot/concat-lhs HandleDot/concat-rhs',
 'bounded_index exact_contraction ordered_float_contraction',
 'Partition the actual contracted fiber at Concatenate prefix boundaries and derive disjoint constant slices and the retained left-associated Add chain of Dots.',
 ['Explicit rank-two contraction map, legal prefix extents, exact Slice bounds and scalar reduction initialization/algebra.'],
 ['Repeated per-piece initialization, empty pieces and rounded regrouping can change observations; exact distributivity does not close the floating profile.'])
add('dot','dot_dynamic_slice','HandleDot/dynamic-slice-lhs HandleDot/dynamic-slice-rhs',
 'bounded_dynamic_index bounded_index exact_contraction ordered_float_contraction',
 'Move actual clamped free-axis DynamicSlice through the fixed constant Dot while preserving the full contracted fiber and output start-index order.',
 ['Explicit rank-two no-batch contraction, unchanged contracted extent, singleton selected free extent and actual index decoder/clamp.'],
 ['Signed/unsigned start conversion, empty fibers, precision and exact output shape must be derived; physical/effect observations remain separate.'])

# These descriptions name proposed semantics/observations, not accepted operator axioms.
PROFILE_DESCRIPTIONS = {
 'arbitrary_width_bitvector':'BitVec width with explicit modular operations, signed/unsigned decoding and zero-divisor conventions; widths quantified rather than sampled.',
 'binary_float_bits':'Actual admitted format operations observed through stored bits, including zero sign and exceptional encodings; flags are a separate observation.',
 'bit_encoding':'Explicit scalar/lane bitstream encoding, endian order, widths and padding bits.',
 'bounded_dynamic_index':'Actual signed/unsigned finite-word index decoder, integer clamp, bounded result map and representability conditions.',
 'bounded_gather':'An independently defined Gather dimension map, index vector convention, batching, clamping and empty/out-of-bounds behavior.',
 'bounded_index':'Arbitrary finite static ranks/extents, legal bounded coordinate maps, derived transformed shapes and attributes, including zero extents.',
 'bounded_runtime_id':'A finite participant/partition ID model with explicit range and finite-width representation.',
 'complex_pair_bits':'Complex values as explicit pairs of component encodings with declared construction/conversion and projection semantics.',
 'dynamic_shape':'Values paired with bounded runtime extents and static capacities, with explicit dynamic-size observations.',
 'effect_graph':'A typed graph with declared execution/control/state/error observations; pure node equality alone is insufficient.',
 'exact_complex':'Mathematical complex algebra with explicit totalization/domain conditions; not rounded complex execution.',
 'exact_contraction':'A finite contraction with explicit axis maps, scalar semiring product/sum, initializer and tuple/result shape.',
 'exact_field':'An independently admitted mathematical field operation with explicit nonzero or totalized reciprocal domains.',
 'exact_integer':'Unbounded mathematical integers; no implicit transfer to machine arithmetic.',
 'exact_real':'Mathematical real operations with explicit analytic domains and zero/partial-operation conventions.',
 'exact_ring':'Mathematical ring operations and stated scalar identities; no implicit transfer to IEEE arithmetic.',
 'linear_order':'An explicitly specified linear order and actual min/max/clamp/comparison definitions.',
 'linear_ordered_ring':'An exact ordered ring with explicitly defined absolute value and scalar arithmetic.',
 'literal_values':'Typed mathematical tuple/tensor literal values and their actual encoding/pattern predicates.',
 'ordered_float_contraction':'An actual admitted rounded product/conversion/initializer/fold sequence or explicitly specified permitted-result refinement relation.',
 'ordered_reduction':'An explicit whole-state reducer, actual initializer/padding and ordered finite contribution sequence.',
 'ordered_scatter':'A specified indexed update trace with reducer parameter roles, duplicate ordering, batching and out-of-bounds behavior.',
 'ordered_sort':'A specified axis sorting relation/algorithm, comparator calls, stability, tuple coupling and empty-axis behavior.',
 'physical_layout':'Explicit logical-to-storage byte/bit maps, tiles, memory spaces and any observed allocation/transfer/alias effects.',
 'predicate':'Actual Boolean values, Boolean comparisons and legal scalar/tensor predicate shape maps.',
 'principal_complex':'Mathematical principal complex log/power/sqrt with explicit argument/branch-cut and zero domains.',
 'pure_branch':'Typed branch functions and arguments with explicit selector mapping; execution effects need a different profile.',
 'pure_graph':'A mathematical pure typed expression/DAG and its admitted observations; no compiled implementation correspondence.',
 'pure_nary_map':'An actual finite-arity scalar operation and bounded parameter/operand selection, lifted pointwise to explicit shapes.',
 'pure_tensor':'A function from bounded coordinates to declared scalar/tuple values, with explicit static shape.',
 'pure_tuple':'Typed finite products/heterogeneous tuples with bounded projection and component shape/value observations.',
 'random_distribution':'An independently specified probability distribution/joint sampling relation, not assumed seeded-stream equality.',
 'rounded_transcendental':'A concrete rounded exp/log/pow/sqrt/rsqrt/etc. operation and format/exception observations; exact analysis is not its definition.',
 'scalar_conversion':'Explicit source/destination formats, signedness, rounding/saturation, exceptional values and out-of-range behavior.',
 'signed_word_order':'Actual finite-word signed decoding and comparisons, including minimum and maximum values.',
 'stateful_rng':'A specified generator state transition, sample-stream consumption and result coordinate map.',
 'truncating_integer':'Signed integer quotient/remainder truncating toward zero with explicit zero/overflow domains.',
 'unsigned_word_order':'Actual unsigned finite-word value order and comparison semantics.'
}

# Only the complex square-root branch carries this principal-branch risk.
PROPOSALS['HandleSqrt/square-real']['mathematical_risks'] = []

BASELINE = 'census/formulation-evidence-baseline-v1.json'
DOMAINS = 'census/mathematical-domain-proposals-v1.json'
MANIFEST = 'census/workload-formulation-expansion-v1.json'
CATALOG = 'census/workload-formulation-catalog-v2.json'
COMMON = dict(
 proposal_kind='mathematical_target_and_domain_proposal_not_an_accepted_Lean_statement',
 quantifiers='arbitrary legal static ranks/extents and all input values in each explicitly selected profile; dynamic/effect/physical observations require their named models',
 shape_obligation='derive target well-formedness, output shape and bounded maps; do not postulate sample equivalence',
 source_guards_adopted_as_proof_assumptions=False,whole_record_closed=False,
 independent_statement_review='pending',code_correspondence='future_work',
 complete_proof_attempt_for_all_partitions_claimed=False)


def digest(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def read(path): return json.loads((ROOT/path).read_text())


def serialized(value): return json.dumps(value,indent=2)+'\n'


def write_new(path,value):
    target=ROOT/path
    if target.exists():raise ValueError('immutable input already exists; use a successor version: '+path)
    target.write_text(serialized(value))


def expected_worksheets(baseline):
    assert set(PROFILE_DESCRIPTIONS)=={d for row in PROPOSALS.values() for d in row['candidate_domains']}
    outputs={}
    for batch in BATCHES:
        path='census/'+batch+'-cases.json';cases=read(path)['cases']
        assert {c['id'] for c in cases}=={n for n,p in PROPOSALS.items() if p['batch']==batch},batch
        rows=[]
        for case in cases:
            name=case['id'];proposal=PROPOSALS[name]
            risks=proposal['mathematical_risks']
            role=('support_schema' if 'support_schema_not_standalone_rewrite' in risks else
                  'delegated_or_unspecified_target' if 'retained_target_not_explicit' in risks else
                  'transformation_stage' if name in ('HandleBitcast/compose-stage','HandleBitcast/compatible-stage')
                  else 'candidate_transformation_schema')
            rows.append(dict(benchmark_id=name,retained_lhs=case.get('lhs'),retained_rhs=case.get('rhs'),
                classification=proposal['classification'],candidate_domains=proposal['candidate_domains'],
                proposed_mathematical_target=proposal['proposed_mathematical_target'],
                explicit_mathematical_premises=proposal['explicit_mathematical_premises'],
                remaining_mathematical_partitions=proposal['remaining_mathematical_partitions'],
                mathematical_risks=risks,record_role=role,
                denominator_review_action='review whether this record is a distinct rewrite, a partition, support or a stage; do not count it as one obligation automatically',
                existing_candidate_evidence_at_base=baseline['records'][name],
                **COMMON))
        outputs['census/'+batch+'-mathematical-domains-v1.json']=dict(schema=1,
            status='unreviewed_mathematical_formulation_proposals_not_frozen_N_or_F',
            retained_batch=path,retained_batch_sha256=digest(ROOT/path),benchmark_record_count=len(rows),
            base_revision=BASE_REVISION,evidence_baseline=BASELINE,domain_proposals=DOMAINS,
            mathematical_obligation_denominator=None,mathematical_denominator_frozen=False,
            source_guards_adopted_as_proof_assumptions=False,independently_reviewed=False,
            code_correspondence_performed=False,all_workload_attempts_complete=False,
            records=rows)
    assert sum(len(x['records']) for x in outputs.values())==len(PROPOSALS)==380
    return outputs


def freeze():
    import subprocess
    assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()==BASE_REVISION
    # Prevent a partial overwrite if any immutable destination already exists.
    paths=[BASELINE,DOMAINS,MANIFEST,CATALOG]+['census/'+b+'-mathematical-domains-v1.json' for b in BATCHES]
    assert not any((ROOT/path).exists() for path in paths)
    progress=read('census/mathematical-ledger.json')
    evidence={r['benchmark_id']:r['evidence'] for r in progress['benchmark_records']}
    baseline=dict(schema=1,base_revision=BASE_REVISION,
                  input_ledger_sha256=digest(ROOT/'census/mathematical-ledger.json'),
                  record_count=380,correspondence_certified=False,
                  records={n:evidence[n] for n in sorted(PROPOSALS)})
    write_new(BASELINE,baseline)
    domains=dict(schema=1,status='proposed_domains_not_adopted_operator_axioms',
                 profiles={name:dict(meaning=meaning,independently_reviewed=False,
                                    accepted_as_full_semantics=False)
                           for name,meaning in sorted(PROFILE_DESCRIPTIONS.items())})
    write_new(DOMAINS,domains)
    outputs=expected_worksheets(baseline)
    for path,value in outputs.items():write_new(path,value)
    frozen_paths=[BASELINE,DOMAINS,'tools/formulate_remaining_batches.py']+list(outputs)
    manifest=dict(schema=1,status='frozen_proposal_packet_not_verified_formulation',
        base_revision=BASE_REVISION,new_record_proposals=380,classification_groups=124,
        proposed_domain_profiles=38,new_Lean_statements=0,new_custom_Lean_lines=0,
        files=[dict(path=p,sha256=digest(ROOT/p)) for p in frozen_paths],
        worksheets=list(outputs),source_guards_adopted_as_proof_assumptions=False,
        mathematical_denominator_frozen=False,mathematical_obligation_denominator=None,
        whole_benchmark_records_closed=0,independently_reviewed=False,
        all_workload_attempts_complete=False,code_correspondence_performed=False)
    write_new(MANIFEST,manifest)
    prior='census/workload-formulation-catalog-v1.json';catalog=read(prior)
    catalog['supersedes']=dict(path=prior,sha256=digest(ROOT/prior))
    catalog['proposal_expansion']=dict(path=MANIFEST,sha256=digest(ROOT/MANIFEST))
    catalog['worksheets'] += [dict(path=p,sha256=digest(ROOT/p),retained_record_count=len(x['records']))
                              for p,x in outputs.items()]
    catalog['scope']='retained-record domain/dependency worksheets including unreviewed proposals; presence is not completed formulation, proof attempt or a frozen obligation denominator'
    write_new(CATALOG,catalog)
    print('Frozen380 mathematical record proposals in7 worksheets;124 classification groups/38 proposed domains. No new Lean proof acceptance.')


if __name__=='__main__':
    import argparse
    parser=argparse.ArgumentParser();parser.add_argument('--freeze',action='store_true');args=parser.parse_args()
    if args.freeze:freeze()
    else:raise SystemExit('Use --freeze only for the first creation; tools/check_formulation_expansion.py validates the frozen packet.')
