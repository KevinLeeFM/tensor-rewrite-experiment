# Independent reviews of the Gather and dot batch

| Mathematical case | Source records | Evidence |
|---|---:|---|
| Effective-scalar Gather from rank zero or a unit array | 2 | [Gather review](../effective-gather/REVIEW.md) |
| Dot with a concatenated contraction axis and sliced constant | 2 | [Block-dot review](../dot-concat/REVIEW.md) |
| Transfer of contracting-axis reversals across a dot | 2 | [Dot reversal review](../dot-reverse/REVIEW.md) |
| Standalone extremum as sibling arg-extremum value projection | 2 | [Sibling reduction review](../concat-normalize/REVIEW.md) |
| Bounded dynamic prefix roundtrip with raw or clamped size | 2 | [Dynamic size review](../dynamic-roundtrip/REVIEW.md) |
| Transpose of a batched dot by swapping operands | 2 | [Dot transpose review](../dot-transpose/REVIEW.md) |

Four reviews were performed independently of authorship. Two reviewers each checked two packets, and two reviewers each checked one packet. This index links their findings. The three dot calculations are different terminal equalities. The block-dot result extends the historical two-segment identity to cumulative slicing of a single constant matrix. It also proves that the constant accessor observes only the legal prefix. The earlier proof remains in the historical ledger with its original effort classification.
