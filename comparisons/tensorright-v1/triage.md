# Unresolved paper cases

Read the paper declaration and inspect existing models for a matching complete proof. These entries identify missing connections; they do not claim a timed proof attempt or establish impossibility.

| Case | Archived result | Missing connection |
| --- | --- | --- |
| conv/rule00 | proved | Connect the paper's input Pad parameters and convolution dilation/edge formulas to the existing PadWindow and convolution models, including all feature and spatial reductions. |
| conv/rule01 | proved | Connect interior padding of the kernel to the paper's right-dilation convention, including zero-filled kernel positions, complete output shapes and reduction-index mapping. |
| conv/rule03 | proved | Extend the existing pointwise-convolution/Dot connection to the paper's mixed case: some spatial axes are contracted and others have unit kernel extent and remain as Dot batch axes. |
| pad/rule02 | proved | Add or connect an interior-spacing Pad model that handles the unchanged other-axis padding and proves the spacing is irrelevant on an input axis of extent one. |
| pad/rule03 | proved | Connect multidimensional signed edge Pad through Broadcast when all padding on the newly broadcast axis is zero, preserving the shapes and arbitrary input tensor values. |
| pad/rule04 | proved | Model the paper's negative edge padding and prove that cropping by its specified Slice matches it, while retaining positive padding on the other axes. |
| reduce/rule02 | proved | Connect concatenated bounded tensors and their piecewise reduction indices to the two separately reduced tensors and their outer two-element reduction. |
| slice/rule05 | proved | Prove the requested static Slice selects only padding values for all paper-admitted signed edge padding and interior spacing, with its computed output shape. |
| slice/rule12 | proved | Generalize the existing unit-stride selected-Concat-segment proof to the paper's arbitrary positive stride, deriving both shifted bounds and output count. |
