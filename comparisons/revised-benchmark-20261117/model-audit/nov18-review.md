# Independent decisions for the November 18 mathematical cases

The packet reports below contain the independent decisions, exact statements and replay results. This index collects them for the ledger. Reviewers did not author their assigned proofs.

| Group | Cases | Independent report |
|---|---:|---|
| Signed rotation normalization | 1 | [Rotation review](../rotation-model/REVIEW.md) |
| Exact literal recognition and reconstruction | 3 | [Literal review](../literal-model/REVIEW.md) |
| Widen, operate, narrow | 4 | [Word arithmetic review](../widen-binop/REVIEW.md) |
| Singleton read of plain or scaled Iota | 2 | [Iota read review](../iota-dynamic-read/REVIEW.md) |
| Ordered gather and same-axis all-to-all with uniform operands | 2 | [Collective review](../uniform-exchange/REVIEW.md) |

Each identifier in nov18.json denotes one pair of original and replacement calculations under the recorded domain. Uniform collectives share one proof after evaluating their distinct input calculations. The two rotation returns implement a single normalization. Same-type and mixed-signedness reads are quantified in the same case. Three signed widening arithmetic laws came from prior work. Timing is shared across cases where work was shared.
