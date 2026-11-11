# Separate Slice/Pad factorization milestone

The canonical Map/Slice/Pad replacement graph now has derived legal ordinary
Slice attributes, exact output shape and value equality with the affine gather.
Signed ceiling thresholds and clipping handle arbitrary positive stride, signed
padding and empty valid intervals. Unit-window corollaries retain their original
kernel/base-dilation/padding laws. Exact additive/order instances do not establish
IEEE behavior. Two certificates reject incorrect starts and unclipped shapes.

New28 statements use341 Lean lines (S62/H128/R109/A1/C41), total5261. All46 focused
tests pass. Independent enumeration agrees on675 axis configurations and15 tensor
profiles/45 outputs. The earlier fused-target graph gap is closed for the declared
canonical mathematical profile, without supplying a desired correspondence as a
premise. This does not certify C++ graph construction or all numerical domains.

All488 records remain371 unformulated/105 partial/12 declared logical-family;
zero whole records closed. Theory/ledger187/447, four integration theorems
separate. Independent review of this extension, full workload and verdict remain
open. See docs/slice-pad-factorization.md and the JSON companion for exact scope,
measurement and validation. Code correspondence remains future work.
