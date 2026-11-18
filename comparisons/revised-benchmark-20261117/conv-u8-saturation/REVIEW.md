# Independent review: `conv-u8-saturation`

**Verdict: accepted as a counterexample to the frozen strict U8 evaluator-profile equality.** The source-shaped model's universal all-output equality is false: one valid output channel saturates in the original convolution model but wraps in the replacement U8 multiply. This is a typed finite-width model outcome for the pinned evaluator arithmetic, not a refutation of the exact-Nat pointwise theorem, not a claim about every XLA numerical contract, and not native execution or proof of an optimizer defect.

## Source path and arithmetic

I inspected the frozen packet, `algebraic_simplifier.cc`, `shape_inference.cc`, `hlo_evaluator.cc`, and `hlo_evaluator_typed_visitor.h`. The packet's source SHA checks passed against the checked-out files. The selected dimensions are rank three with identity axes: input `[1,g,1]`, kernel `[1,g,1]` ordered `[kernel-input-feature,kernel-output-feature,spatial]`, and output `[1,g,1]`. `g > 1` is a valid feature-group count: input and output feature sizes are `g`, kernel input feature size is one, kernel output feature size is `g`, and batch group count is one. The input batch and the kernel output feature size are divisible by that batch-group count. Shape inference therefore admits the setup; there are no empty operands.

The `HandleConvolution` path invokes `SimplifyConvToDot` before `SimplifyConvToMultiply` (`algebraic_simplifier.cc:11264–11271`). The dot helper explicitly rejects feature-group counts other than one (`:11048–11050`), so `g > 1` bypasses that candidate. The optional `ScalarMultiplyReduction` called earlier only handles BF16/F32 (`:673–679`), so it does not rewrite this U8 convolution. The multiply simplifier accepts the frozen pointwise geometry and feature guards (`:11102–11147`), builds identity input/kernel permutations for these dimension numbers (`:11150–11179`), has no reversal or reduction axis for the unit spatial kernel (`:11164–11178`), and emits `Multiply(input, broadcast(kernel))` (`:11200–11217`). Same-type U8 inputs need no conversion. Both operands are parameters, so this packet does not rely on a constant/scalar operand simplification.

For the original evaluator calculation, `GetElementwisePrimitiveType(U8)` selects U64 (`hlo_evaluator.cc:5767–5778`). `HandleConvolution` converts the same-type U8 operands to that elementwise type before computing, dispatches `ElementwiseT` as U64, then converts the evaluated result back to U8 (`:6558–6569`, `:6630–6670`). The one tap and one input channel initialize a U64 result to zero and add exactly one U64 product (`:5986`, `:6040–6065`). Since any U8 product is at most 65025, this product and addition fit U64 exactly. The evaluator then clamps to the U8 `ReturnT` range, 0 through 255 (`:5926–5944`, `:6080–6085`), stores the widened result and converts it to U8. This is saturating multiplication for this one-product convolution domain.

The replacement HLO `Multiply` also selects U64 as its internal elementwise type, but its typed visitor writes the result with `static_cast<ReturnT>` (`hlo_evaluator_typed_visitor.h:484–489`, `:1194–1218`; the explicit `HloEvaluatorTypedVisitor<uint8_t,uint64_t>` instantiation is declared at `:1288`). For U8, that final C++ narrowing keeps the low eight bits; there is no convolution clamp in this path. The frozen Lean `Byte := BitVec 8` product represents this modular U8 result. In this range, the U64 intermediate itself cannot overflow, so the only difference is clamp-versus-narrow.

## Counterexample, controls, and replay

`Goal` universally quantifies `g > 1`, both arbitrary U8 channel arrays, and every output channel. `refuted` instantiates `g=2`, input `[15,16]`, and kernel `[16,16]`. Both models produce 240 on channel zero. On channel one, the original computes `16 * 16 = 256` in U64 and clamps to 255; the replacement narrows 256 to U8, yielding zero. Thus complete vectors are `[240,255]` versus `[240,0]`, and the equality fails at a valid output coordinate. The witness has legal grouped shapes and distinct values on separate channels; it is not an invalid-shape or off-domain artifact.

Controls cover a no-overflow equality (`255*1 = 255`), a product above 255 where clamp and wrap happen to agree (`7*73 = 511`, both yield 255), and an overflow where they differ (`255*255`, clamp gives 255 while U8 multiplication gives 1). These controls make clear that “overflow occurred” alone is not the distinguishing property; the two output functions have different results for the selected witness.

Fresh targeted replay:

```sh
LEAN=/workspace/toolchains/lean-4.35.0-linux/bin/lean python3 replay.py
```

It passed on 2026-11-18 with Lean 4.35.0, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. The replay rechecked all source/spec hash entries and compiled the three packet modules in fresh temporary outputs: `U8Spec` 0.341 s, `U8Proof` 0.281 s, `U8Controls` 0.323 s (0.945 s summed Lean command time; 1.003 s total command wall). The only reported axiom for `refuted` is `propext`; there is no project axiom. Inspection found no `sorry`, `admit`, or `native_decide` in the three Lean modules. No native HLO evaluator run, XLA build, or broad dependency build was performed. The source audit supports the selected evaluator arithmetic path, while the formal proof itself is the small Lean model.

This continues the frozen candidate introduced in commit `faae169`; the current packet's proof, counterexample, controls, and replay script were added in `64ccef0`. The earlier rank-three Nat-exact `conv-pointwise-axes` case concerns a different value contract and is not contradicted: its exact Nat product cannot express U8 saturation or modular narrowing.

## Scope and timing

This refutes the universal equality only for the stated strict U8 evaluator-profile case: rank three, identity dimension numbers, one batch, unit spatial and kernel extents, `g > 1` feature groups, no conversions, padding, stride, dilation, reversal, or sparse data. It does not establish what a native backend executes, whether an optimization is reached in a particular build/configuration, or whether another source contract observes the same arithmetic. It is not a counterexample for other pointwise types, non-pointwise convolutions, or the Nat-exact model.

Review began at 2026-11-18 02:47:24 UTC and completed at 02:50:12 UTC (2 min 48 s wall). The first checksum command used the packet directory despite repository-root-relative manifest paths and therefore failed before reading any listed file; the corrected repository-root checksum verification passed. Replay/compiler time is reported above. Source and model inspection made up the remaining wall time; active reasoning time and token use were not measured. No worker, setup, network access, or native test was used.
