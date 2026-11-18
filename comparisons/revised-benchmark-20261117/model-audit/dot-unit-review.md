# Independent mathematical-case reviews

- [dot.drop-unit-axes — proved](../dot-drop-unit/REVIEW.md)
- [scalar-concat-slice.start-only — proved](../scalar-concat-slice/REVIEW.md)
- [reduce.transpose-int-order — proved](../reduce-transpose-orders/REVIEW.md)
- [reduce.transpose-rounded-order — disproved](../reduce-transpose-orders/REVIEW.md)
- [reuse.dynamic-slice-broadcast — historical reuse](../dynamic-slice-broadcast/REVIEW.md)
- [maximum.cbrt-mixed-precision — disproved](../max-cbrt-precision/REVIEW.md)
- [constant.expand-nested-tuple — proved](../tuple-constant-expand/REVIEW.md)
- [convert.integer-f32-roundtrip — proved](../convert-f32-roundtrip/REVIEW.md)
- [reuse.reduce-dot-batch-identity — historical reuse](../reduce-dot-seed/REVIEW.md)
- [reduce.dot-residual-seed — proved](../reduce-dot-seed/REVIEW.md)

Two historical identities supply three source links. The nonidentity-seeded direct-dot diagnostic is excluded from benchmark refutations. The transpose-reduction refutation is restricted to the declared sequential rounding order.
