# Draft mathematical statement for independent review

**Status: provisional; no rewrite proof attempted or accepted.** This is a candidate statement of the unit-stride slice/concatenate construction, with mathematical operator interpretations assumed. It is not a Lean theorem or a frozen final experiment goal. Source extraction and C++ correspondence remain assumptions. The reviewer must determine whether this states the intended source branch without accidental strengthening.

Let `n` be an arbitrary natural rank, `X : Tensor x α` for an arbitrary value type α and input shape `x : Fin n → Nat`, and `u : Fin (n+1) → Nat` be the inner reshape shape. Let `p` be a permutation of `Fin (n+1)`, in output-to-input axis order, and let `z : Fin m → Nat` be the outer reshape shape for arbitrary `m`. Require the original reshape/transpose/reshape to be well formed: element counts `product(x)=product(u)=product(z)`, with the scalar empty-product convention, and with the modeled integer size products and indices representable in the source's signed dimension arithmetic. To interpret the source's unchecked indexing of the first `n` output dimensions, the present draft additionally requires `m ≥ n`. **This is a model-domain precondition, not a guard checked in the shown source.** Review whether legal HLO and earlier branches imply it; do not call this full source-branch coverage until that is established. Output axes after the first `n` remain arbitrary subject to the element-count equality; no fixed rank is assumed.

There are `s : Fin n` and `t : Fin (n+1)` such that:

1. For every `j < s`, `u[j]=x[j]`; `u[s] ≠ x[s]`; `x[s]=u[s]*u[s+1]`; and for every `j > s`, `u[j+1]=x[j]`. Set `k=u[s]`, `c=u[s+1]`. The source requires `k≤5`. In unbounded Nat arithmetic `k>0` follows from the mismatch/product conditions, including when other axes have size zero; do not add a hidden blanket nonempty-tensor premise.
2. `p[t]=s`, `t ≠ s` and `t ≠ s+1`; for every output axis `d ≠ t`, `p[d]=d-(1 if d>t else 0)+(1 if d>s else 0)`. Here the subtraction corresponds to the source signed offset, with defined nonnegative axis indices. Permutation injectivity plus these conditions implies `t<s`; `ShapeBridge.moved_axis_before_split` checks this abstract implication with finite axes. In particular `t<n`, so concatenation axis `t` is legal. The proof of the rewrite must not assume that the two sides' coordinate maps coincide.
3. For each `j<n`, source output-shape precedence is: if `t>0` and `j+1=t`, `z[j]=x[j]*k`; else if `j=s`, `z[j]=x[j]/k`; else `z[j]=x[j]`. Because `k>0` follows, division is defined in the mathematical domain. Source-relevant products must be represented without signed overflow. No positivity condition is placed on the other extents.

Define the left side by the actual logical operators, with their shape and valid-index witnesses derived from the conditions, not by defining its coordinate map as the desired answer:

`L = Reshape_z(Transpose_p(Reshape_u(X)))`.

For each `i=0,…,k−1`, define `S_i` as the actual unit-stride slice of `X` at input axis `s`, interval `[i*c,(i+1)*c)`, leaving all other axes unchanged. Derive legality from `x[s]=k*c`. Let `Q` be their input-rank concatenation in **increasing i order** along axis `t`, using the actual concatenate operand-selection semantics. Each `S_i` has shape `x[s↦c]`, and `Q` has shape `x[s↦c][t↦x[t]*k]` because `t<s`; derive equality with the frame expected by the existing concatenate model. Its element count equals `product(x)` without assuming `X` has an element. Define the right side using the actual logical reshape:

`R = Reshape_z(Q)`.

**Draft goal:** `∀ α n m x u p z s t X,` under exactly the shape, source-loop and well-formedness conditions above, `L = R` as `Tensor z α` (all legal output coordinates, including the vacuous equality when `z` is empty). No tensor equality, coordinate commutation or theorem-shaped conclusion is a premise. This is a mathematical interpretation of the graph transformation; user-count, layout-option, visitor ordering, source mapping, side effects, HLO attributes, and C++ execution are assumptions/outside the theorem. No full-branch or independent-novelty claim is made.

The first nonempty diagnostic is `[3,4,6] → [3,4,2,3] → transpose [0,2,1,3] → [6,4,3]`, with `s=2`, `t=1`, `k=2`; slice/concat shape is `[3,8,3]`. A retained-zero input `[0,4,6]` has valid zero-element analogues; a one-chunk case `[3,4,3] → [3,4,1,3]` is also represented. `shape_examples.py` checks these and rejects wrong permutation, output and split-product examples. On the nonempty example, a wrong concat axis 0 disagrees at flattened coordinate 12 (3 versus 24). These finite host checks do not replace a well-formed Lean false-replacement refutation or the source admission/reachability proof.

## Review questions before freeze/proof

- Does `m≥n` follow from accepted HLO/visitor invariants or is it a narrower partition? Is unchecked source indexing material for a source-level diagnosis?
- Does the generic `Frame.slice` to distinct `Frame.concatenate` bridge preserve *actual* slice coordinate selection and source ordering without relying on equality of the final tensors? `ShapeBridge.setExtent_commute` proves shape updates commute but does not yet build this typed tensor transport.
- Are the int64 no-overflow and logical reshape/transpose assumptions the right disclosed mathematical profile? Do earlier return paths, empty dimensions and scalar cases have distinct coverage implications?
- Are source-compatible `num_chunks=1` and empty-input examples retained? Is zero chunks correctly excluded by the actual detected-split mismatch rather than by a guessed premise?
- Independently inspect each proposed generic module and all its declarations; assess overlap against all relevant prior proofs, not just text search. `ALLOWED-IMPORTS.json` is a proposed local audit, not independent certification.

Only after review and approval of a Lean-elaborated exact statement, generic baseline and hashes may one bounded rewrite proof begin. Freeze the exact source/goal/controls in Git first. Keep development, compilation, statement review, proof review and replay time separate; no comparable discovery baseline or speedup is available.
