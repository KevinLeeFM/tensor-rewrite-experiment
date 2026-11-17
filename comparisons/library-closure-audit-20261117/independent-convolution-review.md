# Independent convolution and reduction review

Fresh Luna reviewer; read-only, no children or builds, approximately five minutes focused effort. Scope: `Theory/ConvolutionPointwiseLemmas.lean`, `ConvolutionPointwise.lean`, `ReductionFiberLemmas.lean`, `ReductionFiber.lean` and selected callers.

`IsPointwiseAxis` states unit kernel/stride/base dilation and zero padding, not shape equality. `ConvolutionPointwiseLemmas.lean:29,79` derives output-shape equality and the sampled input coordinate. `ConvolutionPointwiseAlgebra.lean:27` and `ConvolutionOrderedLemmas.lean:56` consume the coordinate fact. These are useful pointwise-window domain lemmas, not unrestricted convolution assumptions.

`ReductionFiberLemmas.lean:52–71` derives split/merge inverses and an equivalence, including zero extents. `fiberValues_sum` at line 139 relates an ordered fiber to a finite sum under an `AddCommMonoid`; `foldl_map_hom` at line 171 takes an explicit homomorphism premise. `ReductionAlgebra.lean:97,110,122` and `WindowTransportLemmas.lean:46` are representative consumers. Surrounding reductions include their required algebraic or nonempty restrictions.

No target equality is assumed in the inspected statements; no specific defect or cleanup emerged. These selected paths are not the full 109-module closure, and source correspondence was not checked. The reviewer's narrative initially mentioned four direct imports for both modules and also seven for the convolution module; the coordinator independently checked the lexical inventory and found seven direct maintained importers for `ConvolutionPointwiseLemmas` and four for `ReductionFiberLemmas`.
