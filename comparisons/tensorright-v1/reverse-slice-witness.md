# TensorRight's reverse/Slice rule has an invalid replacement

For a one-dimensional input of length 10, the paper artifact's rule
`slice/rule13` permits an original Slice with start 2, exclusive end 8 and
stride 2. The output has length 3, and output index 0 is valid. For example,
on the input `[0,1,2,3,4,5,6,7,8,9]`, reversing first and then taking this
slice would read `[7,5,3]`.

The artifact's own formulas give `count = (8 − 2) / 2 − 1 = 2`,
`startRhs = 2 + 2 × 2 + 1 − 10 = −3`, and `endRhs = 3`. The replacement
Slice therefore starts at −3. TensorRight's Slice semantics explicitly
requires a nonnegative start, so this replacement is invalid. The concrete
Lean certificates in `ReverseSliceFailure.lean` check the original validity,
an accessible output, the formula's exact bounds and the invalid replacement.
They are independent of the tensor element type.

To check the translation, we added only a precondition fixing those four input
parameters to the frozen artifact's own rule; see `reverse-slice-witness.patch`.
Running the rebuilt TensorRight verifier produced the same witness for Bool,
Int and Real: it reported `lhsTensorIsValid: true`, `rhsTensorIsValid: false`,
output index 0 and the bounds above. Full logs are in
`reverse-slice-witness.stdout` and `reverse-slice-witness.stderr`;
`rerun_reverse_slice_witness.sh` reproduces the run with the pinned Docker image.
The original, unrestricted suite had reported this rule as a solver failure
in its archive and our rerun. The fixed-input run is a separate diagnostic.

This disproves the paper artifact's modeled rule under its written conditions.
It does **not** establish that XLA performs this rewrite, that its guards match,
or that an actual compiler bug has been reproduced.
