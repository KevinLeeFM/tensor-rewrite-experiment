# Constructing the separate Map/Slice/Pad graph

The unit-window affine gather is now equal to an independently defined graph:
map the scalar function over the input, apply an ordinary well-formed Slice,
then apply nonnegative Pad. The graph's bounds and shapes are constructed and
proved; no desired shape equality or index correspondence is a supplied premise.

For one axis let N be the input extent, O the output extent, s>0 the stride,
and L the signed low padding. The original affine input position at output i
is i*s-L. Define signed ceiling division ceil(z/s)=-floor(-z/s), then derive:

- A=min(O,max(ceil(L/s),0)), the first potentially valid output;
- B=min(O,max(ceil((L+N)/s),0)), the end of the valid interval;
- M=B-A, the Slice output extent;
- start=min(N,max(A*s-L,0));
- limit=start when M=0, otherwise start+(M-1)*s+1;
- Slice stride=s, Pad low=A and Pad high=O-B.

Lean proves A<=B<=O and that an output is valid exactly when A<=i<B. It proves
ordinary Slice bounds 0<=start<=limit<=N, positive stride and inferred Slice
extent exactly M using the existing `SliceShape.IsWellFormed` contract. It then
proves A+M+(O-B)=O and composes the actual Slice/Pad index maps to recover i*s-L.
These results include empty input/output/valid intervals, arbitrary positive
strides and arbitrary signed padding. Rank remains arbitrary; the tensor proof
also covers rank zero. The clipped empty-Slice start prevents invalid attributes
when strides skip every input sample or all outputs lie outside the input.

The equality holds for arbitrary pure scalar functions f:alpha->beta and a
separate beta padding value. Controls include an Int-to-Bool map. Mapping before
Slice is interpreted as pure tensor values; global effects, exception flags and
partial/failing maps are not established by this model.

## Window corollaries and limits

Combining the graph equality with the previous window result proves a unit-window
reduction equal to this constructed graph under the original conditions:
unit kernel, undilated input and op(initial,padding)=padding. No initializer or
padding condition is erased. Exact AddZeroClass and LinearOrder min/max instances
have direct corollaries. The generic graph keeps the initialized operation's
operand order. No IEEE add-zero identity, NaN/signed-zero policy, machine-width
attribute arithmetic, physical layout or compiled implementation is supplied.

This closes the earlier *mathematical graph-construction gap* for that canonical
profile. It does not certify that the C++ pass constructs these precise attributes,
prove every numerical domain or close all retained window records. The original
window manifest/result remain unchanged, with their earlier scoped false flag;
`census/slice-pad-v1.json` and its result record the new extension and parent model.
Full-span windows, Pad/Broadcast/Convert composition, cumulative counts and the
remaining scalar/observation partitions still need work. Code correspondence
remains user-deferred future work.

Two kernel certificates reject tempting incorrect constructions. A rounded-down
Slice start changes the first retained value from2 to1 despite legal Slice bounds
and equal output shapes. Omitting threshold clipping changes an all-padding
output extent from2 to4. These diagnose bad mathematical factoring strategies,
not compiler implementations or proof-search infeasibility.

## Reproduce and measure

```sh
python3 tools/check_theory.py
python3 tools/check_slice_pad.py
python3 tools/mathematical_ledger.py
python3 -m unittest discover -s tests -p test_slice_pad.py -v
```

Twenty-eight new registered statements comprise18 shared-support lemmas,8 graph/
window results and2 geometry certificates. New Lean is341 lines:
S62/H128/R109/A1/C41. Current total5261 is S1292/H1877/R1553/A80/C459; imported
libraries and already counted project models are reused, not counted twice.
The75-line interpolated IO fixture is separate and reported physically.

An independent oracle enumerates output positions to derive the valid interval,
without using the ceiling-division formulas. All675 finite axis profiles agree
on thresholds, Slice bounds/count/legality and reconstructed shape. Fifteen tensor
profiles/45 outputs compare the actual graph with the affine gather, including
empty and multidimensional cases, heterogeneous maps and ineligible window
profiles that must not inherit the reduction corollary. Generality comes from
the Lean proofs, not the finite controls. All46 focused checks pass; only standard
allowed Lean axioms occur. The28 additions await independent semantic review.

Theory/ledger totals are187/447, with four integration theorems separate. All488
benchmark records remain371 needing formal statement/domain partitions,105 partial,
and12 carrying the earlier logical-value family. Whole records closed stays0;
mathematical N/F, full campaign and final verdict remain open. The earlier frozen
41-statement review packet is unchanged and does not contain this extension.
