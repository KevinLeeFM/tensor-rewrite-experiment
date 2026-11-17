# Theory-side mixed-role audit

## Scope and method

Reviewed the 23 `TensorRewrite/Theory/*.lean` paths assigned by `frozen-cases.json` in the `TensorRewrite/Theory` partition. Read the source of all 23 files, their imports and declarations, the gate, and the maintained/paper direct-consumer fields in `comparisons/library-closure-audit-20261117/inventory.json`. The row-by-row evidence is in `theory-review.json`; rows use the frozen path names and retain the gate's one-row-per-path shape.

All 23 current source hashes match both the frozen case list and the base inventory. The review is read-only with respect to Lean sources. No build, proof replay, source edit, or independent second review was performed. Direct consumer links below are the frozen inventory's direct edges; they establish concrete use, but not the full call chain or the correctness of the consumer.

## High-risk public surfaces

### Pointwise convolution

`ConvolutionPointwise.lean` is a specialized helper over the explicit `Convolution.Plan`, not a source-matcher theorem. `IsPointwiseAxis` requires unit kernel extent, unit stride, unit base dilation, and zero low/high padding (lines 16–27). `channelSum` consumes a supplied output/input shape equality and unit-kernel proof (lines 40–50). The comments explicitly explain why kernel dilation/reversal do not constrain the sole coordinate. `ConvolutionPointwiseLemmas.lean` derives the resulting geometry and sample equality conditional on those conditions. The module has several maintained consumers, including `FixedTacticsStatements`, `BroadcastWindow`, `ReductionWindow`, and its lemma/proof layers, so it is a high-fan-in model boundary. I found no concealed condition beyond the named premises in the inspected surface. These are mathematical model facts; the mapping from an XLA matcher to these premises remains unverified here.

### Reduction fiber and reduction algebra

`ReductionFiber.lean` models an ordered plan by recursively traversing keep/reduce axes; its reduced shape preserves reduced-axis relative order (lines 16–52). `ReductionFiberLemmas.lean` proves coordinate split/merge and finite-sum/fiber correspondence. `ReductionAlgebra.lean` is downstream proof logic, not generic infrastructure: its identities are conditional on each theorem's algebraic laws, initializer behavior, or nonemptiness. The file's comments and signatures expose these conditions. Its paper consumers include `GroupedSums` and `Reduction`; the direct maintained consumer is `ReductionCounterexamples`. I found no theorem in the inspected files that silently supplies a source reduction matcher or erases the modeled fold order.

### Window and padding chain

`ReductionWindow.lean` reuses `Convolution.spatialInput?` by constructing a convolution plan with group factors fixed to one (lines 20–27). The sampled values enumerate all kernel positions in row-major logical order, keep invalid samples as the supplied padding value, and fold from an explicit initializer (lines 41–63). These are explicit semantic choices and matter for reassociation claims. The same module also contains an affine crop/stride gather (`affineInput?`/`gatherMap`, lines 77–103), a separate operator family from ordered window reduction. This is the clearest mixed-role boundary in this sample: both are bounded indexing semantics, but the affine gather does not use the window coordinate or dilation. A safe future separation could move the affine gather definitions to a focused module if a stable consumer boundary justifies it; no edit is proposed here because this audit did not inspect the full downstream dependency graph or measure module/API costs.

`PadWindow.lean` defines nonnegative padding and positive occupied spacing, then computes fused axis parameters. `PadWindowLemmas.lean` establishes sampler composition and output-extent equality, including empty input (`fused_output_extent`, lines 57–63); the familiar simplified high-padding formula is separately limited to nonempty input (`fused_high_nonempty`, lines 74–89). This distinction is important and is explicit rather than hidden. The model uses the same signed integer geometry as the convolution sampler. No source-level proof that a particular pass satisfies these premises is provided by these files.

## BroadcastAxes boundary

The relevant definition is in the imported `Pilot/IndexMaps.lean`, outside the 23 owned paths. Its structure stores one signed integer per input axis and proves only that each entry is in `[0, outputRank)` (`values` and `valid`, lines 16–20). `decode` turns each into an output axis (lines 22–25); `broadcastIndex` projects those selected output coordinates, with per-axis extent equalities (lines 27–32). There is no injectivity, uniqueness, or order condition. Repeated axes are therefore admitted by this abstraction; source ordering/uniqueness must be a separate source condition if required by the target API. The arithmetic Broadcast proofs and the `tensorright-v1/Broadcast.lean` packet consume exactly this range-only interface and shape equalities. These mathematical equalities do not establish that every admitted axis vector can arise from the source parser or that source validation is reproduced.

## Findings on role mixing and assumptions

The set is not uniformly generic. It separates into semantic models (`Convolution`, `ReductionFiber`, `ReductionWindow`, `PadWindow`, `SlicePad`, `ControlValues`, `OrderWord`, and `Remainder`), operation-specific/general helpers and coordinate lemmas, and target-family proof modules (`ArithmeticBroadcast`, numerical/order/remainder proofs, reduction algebra, and pad-window composition). Per-path classification, imports, explicit assumptions, and direct consumers are recorded in JSON.

No evidence in the inspected surfaces justified removing a target-specific assumption or refactoring a public interface. The one concrete cohesion concern is `ReductionWindow` housing both ordered window reduction and affine crop/gather; separation is only a proposal pending full consumer-graph review. The bounded, model-specific modules (`ConvolutionPointwise`, `PadWindow`, `ReductionFiber`) are appropriately premise-driven at the inspected declarations; their specialization is visible in names, comments, and signatures.

## Coverage and limits

- Frozen Theory paths inspected: 23/23; hash matches: 23/23.
- Theory rows emitted: 23.
- Unresolved assigned paths: 0.
- Builds/replays: none; this task was a read-only source audit.
- Not audited: the other 19 assigned Pilot paths, the other 67 modules outside the 42-path frozen unresolved set, every transitive consumer body, imported Mathlib code, C++ correspondence, and semantic equivalence between these models and production code. This is not a blanket cleanliness or source-correctness claim.
- Time: one coordinator pass; exact wall-clock start was not available in the recovered task context, so elapsed duration is not asserted. No worker/reviewer overlap occurred.
