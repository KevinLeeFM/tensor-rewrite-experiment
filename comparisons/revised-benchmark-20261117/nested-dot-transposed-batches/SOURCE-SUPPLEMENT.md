# Pinned nested-dot cost calculation

After the initial review, retrieved the official implementation at XLA e58e523b, Git blob edf6656a3d795698200b798249ed940b25ffedb6. GetDotFlops multiplies the product of LHS contracting extents by the result element count and kFmaFlops. The pinned retained header defines that constant to be 2. For AB followed by (AB)C the costs sum to 2XZ(mkn+mnp); for BC followed by A(BC) the sum is 2XZ(knp+mkp). Passing the old outer result shape during cost estimation preserves its element count across the two nonidentity permutations. With X=Z=3 and the two frozen matrix profiles, the source arithmetic gives 576 versus 144. This verifies the missing helper formula; pass admission, actual backend reduction order and native output remain untested.

[GetDotFlops implementation](https://github.com/openxla/xla/blob/e58e523b/xla/service/hlo_cost_analysis.cc#L484-L494) · [FMA factor](https://github.com/openxla/xla/blob/e58e523b/xla/service/hlo_cost_analysis.h#L683)
