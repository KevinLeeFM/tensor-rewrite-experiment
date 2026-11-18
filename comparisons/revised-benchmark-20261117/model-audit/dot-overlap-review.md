# Independent decisions on dot overlap and follow-up cases

- [dot.remove-common-input-transposes — proved](../dot-remove-transposes/REVIEW.md)
- [bitcast-convert.concat-raw-words — proved](../bitcast-concat-pack/REVIEW.md)
- [convolution.filter-pad-integer — proved](../conv-filter-exact/REVIEW.md)
- [convolution.input-pad-strict-exceptional — disproved](../conv-pad-exceptional/REVIEW.md)
- [convolution.filter-pad-strict-exceptional — disproved](../conv-pad-exceptional/REVIEW.md)
- [dot.nested-rounded-direct — disproved](../nested-dot-round/REVIEW.md)
- [gather.batch-and-passthrough-pad — proved](../gather-pad-hoist/REVIEW.md)
- [bitcast-convert.concat-added-lane-shape — disproved](../bitcast-concat-lane/REVIEW.md)

Dot transpose removal is one additional source expression with no new normalized dot law. The bitcast shared-axis proof and added-lane shape refutation apply to disjoint typing domains. The two filter-pad outcomes share a transformation and differ in arithmetic. Caller aliases and opposite orientations are not separate results.
