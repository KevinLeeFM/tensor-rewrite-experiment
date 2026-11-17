# Frozen-candidate statement review

Case: HandleReshape/iota-mixed-radix, rank-one to rank-three, mathematical Nat values only. This is a small smoke-test partition, not full branch closure or a representative productivity sample. No historical timing comparison.

Pinned XLA e58e523b11f1fde802a493a776d158007486e1bf, sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc lines 7098–7141. Input [a*b*c], output [a,b,c], a,b,c>1. CommonFactors (util.h 781–799) yields boundaries (0,0),(1,3). Source guard at iota axis 0 holds, loop dim=2,1,0; multipliers 1,c,c*b. Source is logical row-major reshape of rank-one Iota, replacement is k+c*j+(c*b)*i. Valid static shapes, pure HLO assumed. Integer-overflow, floating Iota, layout/code correspondence excluded; model-domain restriction explicit. Earlier reshape simplifications assumed not to intercept; no actual pass execution claimed.

Existing reusable library and 118 paper cases searched. Iota proofs cover broadcast/unit and remainder, reshape covers identity/composition/empty. No mixed-radix Iota statement located. This is evidence of novelty relative to this repository, not a claim about other projects. DynamicSlice/transpose candidate rejected because paper slice rule04 already covers labeled rewrite despite missing census evidence.

The statement uses bounded generic FiniteProduct.join to model element-order preserving reshape, rather than defining both sides as the same arithmetic expression. It still exposes a small algebraic identity and should be cheap. Wrong replacement omitting the outer-axis term must fail at shape [2,3,4], coordinate [1,2,3]. Nonempty guard witness [2,3,4] and all 24 coordinates will be checked. No rewrite equality is assumed.
