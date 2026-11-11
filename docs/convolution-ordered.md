# Ordered pointwise convolution and binary32 stored values

The new `ConvolutionOrdered` model makes scalar operations and precision stages
explicit. Input and kernel values may have different types; multiplication
produces accumulator values, and finish converts the final accumulator to an
independent result type. Contributions are listed by input channel, then
spatial kernel position, folded left from a specified initializer.

Invalid spatial samples contribute the supplied accumulator value. This is an
explicit mathematical padding contract. The pointwise theorem never observes
that value because every sample is valid. Adoption of a padded floating-point
operator contract remains separate. With Semiring operations, zero padding and
initializer, and identity finish, `convolve_semiring` proves agreement with the
preceding exact convolution definition.

## Order-preserving Dot theorem

For every pointwise plan, `terms_eq_dot_terms` proves equality of the complete
ordered contribution lists with the existing matrix Dot model. The original
position and corresponding Dot position have the same numeric list index. The
proof casts the contribution count; it does not use a permutation-invariance
or reassociation law.

`convolve_eq_dot` and `dot_eq_convolve` preserve multiplication, addition,
initializer and finish exactly. Scalar types/functions are arbitrary; no
associativity, commutativity, distributivity or identity premise is used. The
existing batch/spatial flattening maps and their inverse coordinate proofs
remain in force. Ranks, extents, groups, batches and channels are arbitrary.
Pointwise conditions are a unit spatial kernel/stride/base dilation and zero
padding; positive kernel dilation and reversal remain arbitrary.

`convolve_single_channel` exposes the correct ordered one-product formula:

```
finish (add initial (multiply inputValue kernelValue))
```

Removing the initial addition or finish requires further scalar facts.
A fixed mixed-precision product/finish definition is preserved by sharing those
functions on both sides. Changing conversion placement is a separate obligation.

## Binary32 consequences and counterexamples

`ConvolutionFloat.binary32_pointwise_dot` specializes the theorem to the pinned
FloatLib binary32 addition and multiplication, preserving stored values for all
operands, including signed zeros and exceptional encodings. It concerns the
specified sequence of separate products/additions. The model does not assert an
external convolution/Dot backend uses that sequence, FMA policy, precision stages
or value-only observation contract. Flags are not observed by these operations.

`binary32_reference_eq` proves the entire ordered value model agrees with the
library's reference scalar addition/multiplication, under the same initializer,
padding contribution and finish. Existing library refinement theorems are reused;
no new assumption about floating-point algebra is introduced.

Two kernel-checked concrete statements show why the exact-semiring conclusions
cannot be transferred mechanically to this ordered stored-value contract:

- A positive-zero-initialized fold of the product `(-0) * 1` yields positive zero;
  the bare product is negative zero. Their words are `0` and `0x80000000`.
- Folding the finite contributions `[2^24, 1, -2^24]` from positive zero yields
  zero; reversing them yields one, word `0x3f800000`.

These refute fold omission and arbitrary reversal under this declared numerical
contract. Retained benchmark labels are candidate metadata; no whole source
rewrite or external backend outcome is inferred from these witnesses.

## Evidence and reproduce

Fifteen new statements pass kernel checking and standard-axiom audit. Twelve
rank-zero binary32 controls evaluate ordered convolution, matrix Dot and the
reference-operations model. Their words match an independent exact-rational
nearest-even oracle for finite inputs, without host floating-point arithmetic.
They cover signed zero/initializers, empty channel lists, subnormals, the normal
boundary, half-ulp ties, large finite values and mixed products. A separate
heterogeneous Nat/Int product, non-associative Int fold and nonidentity finish
returns94 in both operators. Universal ranks and scalar functions are established
by the Lean proofs; these finite controls inspect numerical model meaning.

```sh
python3 tools/check_theory.py
python3 tools/check_convolution_ordered.py
python3 tools/mathematical_ledger.py
python3 -m unittest discover -s tests -p 'test_convolution*.py' -v
python3 -m unittest discover -s tests -p test_logical_family.py -v
python3 -m unittest discover -s tests -p test_mathematical_ledger.py -v
```

The accepted source pins are in `census/convolution-ordered-v2.json`; results are
in `reports/convolution-ordered.json`. The initial v1 checker failed because a
one-group Python regex returns strings, while the assertion expected tuples.
The v1 source/manifest snapshot and failure classification are retained. V2
corrects only that parser; Lean statements and code-size measurements are unchanged.

Independent statement review, broader numerical/conversion/padding/layout
partitions, the full workload and final feasibility verdict remain open.
Code correspondence remains future work.
