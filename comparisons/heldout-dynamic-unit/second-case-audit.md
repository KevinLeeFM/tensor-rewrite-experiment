# Bounded batch: additional candidate audit

A scoped independent read-only auditor checked two further corpus candidates after the unit-insertion DynamicSlice selection. Neither was selected or proved.

- `HandleSlice/compose-unstrided`, pinned `algebraic_simplifier.cc:7786–7802`, is a static-slice specialization of the already covered `comparisons/tensorright-v1/Dynamic.lean:nested_slice`; generic window composition also appears as `TensorRewrite/Theory/DynamicUpdateProof.lean:slice_compose`. Source int64/no-overflow interpretation would still need disclosure. This is high-overlap, not a worthwhile fresh mathematical proof without a precise unmet distinction.
- `HandleReshape/compose`, pinned `algebraic_simplifier.cc:6939–6948`, already has arbitrary-rank equal-count tensor equality, including empty shapes, in `TensorRewrite/Pilot/ReshapeRules.lean:reshapeTensor_compose`. A newer source-action mapping might be bookkeeping, but the mathematical terminal theorem is not new.

The parallel earlier audit `pad-alternative-audit.md` also rejected singleton-axis interior Pad as covered by the paper-comparison theorem `SignedPad.unit_interior` (`pad/rule02`). This bounded screen therefore identified no additional eligible new case. No builds or proof work were performed for these three alternatives. The two later candidates took approximately seven minutes of auditor wall time, overlapping the current proof/final-review phase. Existing unsuccessful space-depth work remains recorded separately and must remain in aggregate accounting.
