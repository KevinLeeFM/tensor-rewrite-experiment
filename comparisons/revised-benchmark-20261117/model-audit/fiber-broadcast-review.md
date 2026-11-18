# Independently reviewed mathematical cases

- [reduce.reshape-reduced-axes — proved](../reduce-reshape-fibers/REVIEW.md)
- [reduce.reshape-surviving-axes — proved](../reduce-reshape-fibers/REVIEW.md)
- [reduce.broadcast-mapped-axes — proved](../reduce-broadcast-mapped/REVIEW.md)
- [broadcast.sink-mixed-elementwise — proved](../sink-mixed-broadcast/INDEPENDENT-REVIEW.md)
- [reduce.negate-signed-zero — disproved](../reduce-negate-zero/REVIEW.md)
- [precision.full-width-f32 — proved](../full-width-precision/INDEPENDENT-REVIEW.md)
- [scatter.empty-vector-equal-shapes — disproved](../scatter-empty-vector-map/REVIEW.md)
- [copy.compose-dense-layouts — proved](../copy-layout-chain/REVIEW.md)
- [reuse.reduce-constant-and — historical reuse](../model-audit/remaining-family-audit.md)
- [reuse.reduce-constant-or — historical reuse](../model-audit/remaining-family-audit.md)
- [reuse.reduce-constant-minimum — historical reuse](../model-audit/remaining-family-audit.md)
- [reuse.reduce-constant-maximum — historical reuse](../model-audit/remaining-family-audit.md)

The mapped-singleton client diagnostic is excluded from benchmark refutations. [Verifier and client review](../reduce-broadcast-base/INDEPENDENT-REVIEW.md).
