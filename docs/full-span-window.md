# Ordered full-span windows as reduction and reshape

The canonical mixed-axis window is now proved equal to the existing ordered
reduction followed by logical reshape. The proof derives the geometry, complete
contribution list and reshape map. It assumes no scalar algebra: the value type,
binary operation, initializer and padding value are arbitrary.

For each axis in `Reduction.Plan`, `FullSpanWindow.windowPlan` constructs:

- A kept axis: original input extent, kernel extent1, output extent equal to input.
- A reduced axis: kernel extent equal to input, output extent1.

Both use stride1, base/kernel dilation1, zero padding and no reversal. Arbitrary
mixed kept/reduced axes, ranks and natural extents are supported. In particular,
rank zero has one contribution; an empty reduction fiber returns the actual
initializer; a kept empty axis gives an empty result. Zero kernel extents belong
to this declared model without asserting external IR admission.

## Derived graph equality

`OrderedCoordinates.enumerate_uncons` proves that row-major coordinate enumeration
is the ordered concatenation of first-axis/tail blocks. `sample_valid` proves that
the actual bounded sampler returns the separately assembled coordinate at every
kernel position. `sampled_fiber` and `values_fiber` identify its entire ordered
value list with `Reduction.fiberValues`, fixing retained coordinates and varying
reduced coordinates in the original axis order. Invalid padding samples never
occur, so padding can be arbitrary.

`output_count` derives equal element counts after removing reduced singleton
axes. `output_linearize` derives preservation of logical position, and
`output_reshape` proves that deletion is exactly the existing `Reshape.reshapeIndex`.
No assumed shape equality or desired index-map equality is a theorem premise.
`reduce_reshape` applies the same operation to identical lists from the same
initializer. `original_reduce_reshape` uses the proved inverse input transports
so the input can have the original reduction shape directly.

For example, reduce axes0 and2 of an input with shape[2,2,3]. The window output
has shape[1,2,1], and the reduction output has shape[2]. With input values1..12 in
row-major order, the two fibers are[1,2,3,7,8,9] and[4,5,6,10,11,12]. Logical
reshape inserts the singleton axes without changing these fibers. Operation
`10*a+b` with initializer7 gives7123789 on the first fiber. Reordering values or
omitting the initializer changes the result. The proof retains both for every
operation, including nonassociative operations.

## Evidence and size

`census/full-span-window-v1.json` pins new sources, executable fixture/oracle,
existing sampler/reduction/reshape/index dependencies and the Lake manifest.
`reports/full-span-window.json` records20 checked statements: four shared ordered
coordinate results and sixteen geometry/transport/graph results. Transitive
axioms are limited to the existing standard logical whitelist. No new project
axiom or admitted proof is used.

New custom Lean is315 code lines: S40/H198/R76/A1/C0. Project totals are5576
(S1332/H2075/R1629/A81/C459),207 theory statements and467 ledger declarations;
four library-integration theorems are separately audited. Imported library code
is disclosed separately and is not charged again. The31-physical-line IO fixture
uses interpolation, is outside the primary accepted lexical language and is
reported separately rather than counted as proof code.

The independent Python oracle enumerates *original input coordinates*, filtering
by the retained output axes; it does not run a window sampler or use the Lean
recursive fiber definition. All585 plans through rank3, with extents0..3 and
every keep/reduce choice, match on1111 output traces and nonassociative fold values.
Controls include scalar/empty cases, retained and removed zero extents, every
mixed axis order, initializer omission and reversed-trace mutations. These are
finite specification controls; the Lean statements provide arbitrary-rank and
arbitrary-extent generality. All50 focused tests pass. Commands/transcripts are in
`reports/full-span-window-validation-v1/`.

## Remaining boundaries

The theorem is complete for its declared canonical graph profile. The retained
`HandleReduceWindow/full-dimensions` label receives two candidate partial evidence
bindings, without accepting its provenance notes as mathematical assumptions.
All488 records remain:370 awaiting formulation/domain partitions,106 with partial
model evidence and12 carrying the earlier declared logical-value family. Zero
whole records close. Mathematical N/F and the full-workload verdict remain open.

Other geometries, Pad/Broadcast/Convert composition, cumulative counts, tuple and
representation partitions, numerical observation contracts and the full-window
family campaign remain open. Arbitrary operation equality preserves a shared
mathematical schedule; it does not establish a backend's schedule, flags, FMA
policy, representation or physical layout. New statements await independent
review:118 later statements are outside the reviewed89-statement foundation;
the unchanged41-statement extension packet is only part of that backlog.
Code correspondence remains user-deferred future work.
