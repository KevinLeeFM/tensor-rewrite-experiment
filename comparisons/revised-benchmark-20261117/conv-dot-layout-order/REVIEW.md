# Independent review: convolution-to-dot layout order

**Verdict: accepted as a counterexample to unconditional row-order preservation in the frozen source-shaped model.** Different input/output batch-versus-spatial dimension numbers are allowed by the pinned shape verifier even when the input and output have equal descending physical layouts. In that allowed swapped case, the `SimplifyConvToDot` input bitcast enumerates rows in input order `b*S+s`, while the final output bitcast interprets them in output order `s*B+b`. For `B,S > 1`, those generally differ. Matching dimension numbers and degenerate singleton cases pass; the swapped nontrivial control fails.

## Source guard and dnum admissibility

I inspected the frozen packet, `algebraic_simplifier.cc`, and `shape_inference.cc`. The simplifier requires layout-sensitive mode, convolution simplification enabled, equal input/output layouts, input and output feature axes both most minor, and the filter input-feature axis more major than its output-feature axis (`algebraic_simplifier.cc:10981–11050`, especially `:10983–11003` and `:11022–11050`). It does **not** require the input and output batch axes or spatial axes to have the same dimension numbers.

That omission is not rejected by the verifier's shape inference. For rank three with one spatial axis, `InferConvolveShape` separately checks that each input, kernel, and output set of dimension numbers is a permutation of `{0,1,2}` (`shape_inference.cc:2503–2554`). Forward inference puts input batch extent at `output_batch_dimension`, kernel output features at output feature, and inferred spatial extent at output spatial (`:2193–2250`). Thus input dnums `batch=0, spatial=1, feature=2` and output dnums `spatial=0, batch=1, feature=2` are both valid and yield input shape `[B,S,1]` and output shape `[S,B,1]`. Dnums are semantic axis selectors; they are independent of the layout vector. Both shapes can carry the same default descending layout `[2,1,0]`.

The frozen filter is `[space=1,input-feature=1,output-feature=1]`, also descending layout `[2,1,0]`. Feature dimension 2 is the minor axis for both input and output. Filter input-feature axis 1 is more major than output-feature axis 2, satisfying the source positional guard (`:11034–11044`). The groups are both one, avoiding the other explicit source rejection (`:11048–11050`); kernel spatial extent one and unit stride/no padding/base dilation satisfy `:11005–11019`. For the chosen U32-representable values the element counts are nonzero. `HandleConvolution` skips its zero-operand early replacement in this case and, with the frozen simplification options, attempts dot conversion (`:11223–11271`). Layout-sensitive mode also disables the operand-swap helper (`:10887–10900`).

## Linear row calculation

For input `[B,S,1]` with descending layout, the input bitcast to `[B*S,1]` preserves the physical linear row order `b*S+s`. This is exactly how `SimplifyConvToDot` constructs `conv_width` from every non-feature input dimension and creates the row-major `{conv_width,input_channels}` shape (`algebraic_simplifier.cc:11059–11089`). Here one input/output channel makes each dot row just `x[row] * w`.

The dot produces rows in that same input physical order. The final bitcast reinterprets the rows as the declared convolution shape (`:11084–11099`). With matching output dnums `[batch,spatial,feature]` and the same descending layout, output coordinate `(b,s,0)` has physical row `b*S+s`, so it agrees. With swapped output dnums `[spatial,batch,feature]`, the same physical layout gives output coordinate `(b,s,0)` row `s*B+b`; the corresponding dot value is `x[s*B+b] * w`, not generally the convolution value `x[b*S+s] * w`.

The Lean `criterion` states the exact all-data result for this model: the two computations agree for all coordinates and data iff the axes match or `B ≤ 1` or `S ≤ 1`. The proof's necessity direction selects `b=0,s=1` when both extents exceed one. The concrete control `B=2,S=3,b=0,s=1,x=id,w=1` gives convolution value 1 and swapped dot value 2. Controls separately show matching layouts/dnums and a singleton spatial axis agree, and zero batch is vacuous. These cover the key row-address distinctions requested. The model is exact Nat arithmetic; the mismatch witness values (1 and 2) are representable in U32. This is sufficient to refute the universal equality without relying on overflow or layout guessing.

## Fresh replay and scope

Fresh targeted replay command:

```sh
LEAN=/workspace/toolchains/lean-4.35.0-linux/bin/lean python3 replay.py
```

It passed on 2026-11-18 with Lean 4.35.0, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. The pinned packet and source hashes verified, and the three modules compiled in fresh temporary outputs: `LayoutSpec` 0.397 s, `LayoutProof` 0.362 s, `LayoutControls` 0.293 s (1.052 s summed compiler time; about 1.3 s total replay wall). `criterion` and `refuted` report only `[propext, Quot.sound]`. The retained `failed-std.log` shows an earlier unsuccessful proof attempt with unsolved goals and `sorryAx` in that failed compilation; it is not used by the current proof or fresh replay. The current modules contain no `sorry`, `admit`, `native_decide`, or project axiom.

This accepts a mathematical/source-shaped mismatch for the guarded dot rewrite under the chosen layouts/dnums; it does not claim that a particular optimizer run or backend executes the candidate rewrite, nor does it prove C++–Lean correspondence. Empty output cases are mathematical vacuities; `HandleConvolution` has an earlier zero-input/filter shortcut, so those cases do not demonstrate entry into `SimplifyConvToDot`. `UpdateLayout` is invoked on the temporary row-major shapes; its base implementation only updates subbyte element packing (`hlo_pass_interface.h:127–135`), which does not alter the chosen U32 witness. This latter header is outside this packet's `SHA256SUMS`, so this source detail is directly inspected but not hash-bound by the packet.

## Timing

This review began at 2026-11-18 03:03:24 UTC. The fresh replay started at 03:06:02 UTC and completed in about 1.3 s wall (1.052 s summed compiler time). Source/model inspection and report preparation finished at 03:07:50 UTC: 4 min 26 s total elapsed. No build, dependency setup, network operation, worker, or native test was run. Active reasoning time and token usage were not measured.
