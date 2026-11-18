# Paired-axis zero-pad / dot

One exact signed-integer contraction equality for either padded operand orientation.
Source algebraic_simplifier.cc 3708–3775. At any batch/free output coordinate the
two functions are paired contracting fibers in dimension-number order. Arbitrary
retained padding, including negative-edge cropping, is evaluated upstream and
preserved in x; its axis has effective (low,high,interior)=(0,0,0) and its
retained padded extent. Noncontracting retained padding selects the same fibers.
The source fires only with a zero fill and at least one eligible nonzero pad; the
equality also admits the identity configuration. Shape-compatible operands are
assumed by this common extent encoding. Zero axes have no elements; rank zero has
one empty coordinate. Exact mathematical Int; no fixed-width, IEEE, layout,
profitability, host execution or correspondence claim.

The original enumerates the complete padded grid and evaluates each zero-filled
scatter; the replacement enumerates the low/extent-minus-high/interior-plus-one
strided slice. Required facts include unique padded destinations, destination
bounds, and slice cardinality. No correspondence assumption in Case. Freeze the
spec, toolchain and source with SHA256SUMS; only pinned Std imported. Launch
targeted compiler after freezing. Proof and controls are editable only within
this packet. Gate: exact Case, allowed standard axioms, nonempty and empty
controls, deliberately wrong sampling, fresh replay and independent review.
Baseline campaign 40c486c. Check progress within five minutes; no package build.
