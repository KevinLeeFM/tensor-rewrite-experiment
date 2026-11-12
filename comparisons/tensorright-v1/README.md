# Paper-era comparison: 108 proofs and one model counterexample

This is a comparison checkpoint, not a full experiment or a fresh proof
search trial. The 118 rows in `cases.json` and `cases.md` correspond to the paper
artifact's executed main-suite rules. `build_cases.py` checks the recovered
inventory against each source file's actual `main` call order, aligns the 118
archived result blocks, and checks printed labels. One label (`reduce/rule03`)
had shell wildcard expansion in the archived output; its position is used and
that exception is explicit in the script. The archive reports 115 successes and
three failures, described in the paper as
timeouts. We independently rebuilt the frozen sources in the authors' Docker
image and reran all 118 cases; the per-case outcomes matched the archive, with
the same three failures. See `artifact-rerun.json`, the raw `.stdout`/`.stderr`
logs and `rerun_tensorright.sh` for details and reproduction. The archived
success for `dot/rule03` is
especially misleading: although its label and locally constructed `rhs` describe
Dot associativity, its verifier call passes `lhs` twice. That result establishes
only a reflexive identity, not the labeled associativity rewrite. Our Lean
comparison now proves the intended associativity on bounded coordinate groups. Every row preserves the exact rule declaration,
source identity/hash, archived result block hash, types and current outcome.

Four Addition, three Subtraction and seven Multiplication rules have checked Lean
proofs over all finite tensor shapes, integers and exact reals. Each specializes
`ArithmeticFamily.rewrite_sound`; some paper operands are constant tensors while
the Lean results permit arbitrary same-shape tensor operands. Three Broadcast
rules and the remaining Multiplication rule use actual bounded Broadcast or
Reverse coordinate maps. One of the three Broadcast rules covers Boolean tensors
as well as the two numeric types. Eight Boolean And/Or rules and two double-negation
rules reuse the Boolean and exact-arithmetic theories. Six self-comparisons, three
order comparisons and three Clamp cases use the exact linear-order theory. Four
Select cases and four Reverse cases use actual tensor functions and coordinates.
The added Concat, Slice and Pad cases retain complete shapes and bounded indices.
Additional cases cover exact division, absolute values, exponentiation, Iota,
composed Broadcast, dynamic updates, relabeling, integer remainder, and explicit
positive/negative infinity in Min/Max.
Paper numeric input tensors are introduced via `linearMemory` as `nonInf` symbolic
integer/real values; constants in these numeric rules are also finite. Thus these
checks match that input scope, without claiming IEEE floating-point results or
proving correspondence to C++. Later rules can involve special numeric values;
do not extrapolate this observation to all 118 rules.

| Paper case | Lean result | Existing rule constructor |
| --- | --- | --- |
| `add/rule01` | reassociate | `addAssoc false false` |
| `add/rule02` | zero_right | `addZeroRight` |
| `add/rule03` | zero_left | `addZeroLeft` |
| `add/rule04` | commute | `addComm` |
| `sub/rule00–02` | subtract zero; subtract negation; self-subtract | `subZero`, `subNeg`, `subSelf` |
| `mul/rule01–06,08` | unit, zero, regrouping and factoring | `mulOne`, `mulZero`, `fourFactors`, `mulAssoc`, `factor` |
| `mul/rule07` | move a scalar factor through Broadcast | `broadcast_uniform_factor` |
| `broadcast/rule01,02` | Add and Multiply commute with Broadcast | actual Broadcast index projection |
| `broadcast/rule04` | reverse a constant tensor | actual Reverse index map |
| `logical/rule01–08` | Boolean identities with true/false | typed Boolean logical family |
| `not/rule01,02` | Boolean and exact-numeric double negation | Boolean and commutative-ring families |
| `compare/rule01–06` | six self-comparisons | linear-order graph theorem |
| `logical/rule09–11` | comparison with Min/Max | linear-order graph theorem |
| `clamp/rule01–03` | Clamp identities; ordered bounds where required | linear-order graph theorem and `paperClamp_eq` |
| `select/rule01–04` | Select identities | existing pure Select theory |
| `reverse/rule01–04` | unit axes, reversal composition, constant addition | bounded Reverse maps |
| `concat/rule01–07`, `slice/rule08` | grouping, Slice merging, edge Pad and segment extraction | actual Concat/Slice/Pad model |
| `divmod/rule00–03` | divide by one, reciprocal and nested real division | exact totalized integer/real arithmetic |
| `mul/rule09,10` | absolute-value square and real exponential addition | exact number theory |
| `iota/rule01`, `broadcast/rule07,08` | unit-axis Iota and Broadcast Iota/composition | bounded integer coordinates and derived axis maps |
| `slice/rule01,03,04,06,07,09–11` | full, Broadcast, Pad, nested and partial-concatenation Slice | bounded coordinates and output-shape reasoning |
| `slice/rule02`, `broadcast/rule05,06` | constant Slice and DynamicSlice | output-size and index reasoning |
| `max/rule01,02` | Max with −∞ and Min with +∞ | extended orders for finite inputs |
| `dyslice/rule01–05` | static, full, Broadcast, relabeled and nested DynamicSlice | actual valid starts and bounded projections |
| `dyupslice/rule01–04` | add to an update; update-to-Pad; full and nested update | actual DynamicUpdateSlice and Pad coordinates |
| `relabel/rule01,02`, `broadcast/rule03` | relabel composition, identity and constant | bounded axis bijections |
| `divmod/rule04–07` | idempotent, bounded-Iota and guarded integer remainder | truncating remainder including zero divisor |
| `dot/rule01–06` | paired Concat, swap, intended associativity, no contraction, zero dimension, broadcast/reduce | bounded contraction, grouping and actual Concat coordinates |
| `reduce/rule01,03–06` | products, scalar factor, relabel, nested reduction and Dot reduction | bounded coordinate groups and exact finite sums |
| `reduce/rule07,08` | remove unit axes, with or without relabeling | reshape and singleton-fiber coordinate identity |
| `pad/rule01` | zero padding is identity | bounded edge Pad and inferred shape |
| `slice/rule13` | model counterexample: valid original, invalid replacement | Lean certificate and fixed-input TensorRight diagnostic |

Reproduce from the repository root:

```sh
python3 comparisons/tensorright-v1/build_cases.py
lake env lean comparisons/tensorright-v1/Add.lean
lake env lean comparisons/tensorright-v1/ScalarArithmetic.lean
lake env lean comparisons/tensorright-v1/Broadcast.lean
lake env lean comparisons/tensorright-v1/Logical.lean
lake env lean comparisons/tensorright-v1/Comparisons.lean
lake env lean comparisons/tensorright-v1/Select.lean
lake env lean comparisons/tensorright-v1/Reverse.lean
lake env lean comparisons/tensorright-v1/Concatenate.lean
lake env lean comparisons/tensorright-v1/Numerical.lean
lake env lean comparisons/tensorright-v1/Iota.lean
lake env lean comparisons/tensorright-v1/Slices.lean
lake env lean comparisons/tensorright-v1/Extremes.lean
lake env lean comparisons/tensorright-v1/Dynamic.lean
lake env lean comparisons/tensorright-v1/Relabel.lean
lake env lean comparisons/tensorright-v1/Remainder.lean
lake env lean comparisons/tensorright-v1/SliceGeometry.lean
lake env lean comparisons/tensorright-v1/Dot.lean
lake env lean comparisons/tensorright-v1/Reduction.lean
lake env lean comparisons/tensorright-v1/Pad.lean
lake env lean comparisons/tensorright-v1/ReverseSliceFailure.lean
lake env lean comparisons/tensorright-v1/SliceBroadcast.lean
lake env lean comparisons/tensorright-v1/UpdatePad.lean
lake env lean comparisons/tensorright-v1/PadSlice.lean
lake env lean comparisons/tensorright-v1/InteriorSlice.lean
lake env lean comparisons/tensorright-v1/GroupedSums.lean
python3 tools/lean_size.py comparisons/tensorright-v1/*.lean
python3 comparisons/tensorright-v1/measure_dependencies.py
```

All twenty-five Lean commands passed with either no axioms or only the standard
`propext`, `Quot.sound` and `Classical.choice`; outputs are in the twenty-five
`*-check.log` files. The comparison modules have 1639 code lines total, including
139 axiom-print commands. They reuse the existing mathematical development and
Mathlib; 1639 is not the independent cost of these proofs. The earlier 12,341
custom Lean lines include unrelated work and are not attributed wholesale to
these cases. The whole-module transitive import closure comprises 6,170 custom Lean code
lines: 1,639 in comparison modules, 988 under `TensorRewrite/Pilot`, and 3,543
under `TensorRewrite/Theory`. These are overlapping module-level dependencies,
not necessarily minimal proof dependencies or fresh agent output. External
libraries such as Mathlib are excluded. `dependency-costs.json` records the
per-module hashes and per-case import closures; per-case totals overlap and
must not be added together. No
correspondence proof or new compiler pass investigation was performed. These
results reuse historical proofs and do not measure a fresh LLM discovery rate.
One rule is disproved in the model, and the other 9 rows are unresolved. Their specific missing model or proof
connections are recorded in `triage.md`; dependency triage does not claim that a
timed proof attempt was made for each case.

Of the 108 Lean-proved cases, 106 are among the paper archive's 115 successes,
and two (`divmod/rule06,07`) are among its three reported timeouts. These Lean
proofs use the conditions written in the artifact and the previously available
Lean libraries; the independent rerun also reported these two failures.
The remaining archived timeout, `slice/rule13`, has a concrete model
counterexample described in `reverse-slice-witness.md`. This is evidence that the
Lean approach can resolve these two modeled statements, not that an XLA bug was
found or that a controlled head-to-head timing comparison was performed.

For `clamp/rule02`, the original strict inequality between bounds implies the
non-strict order needed by the proof; no extra restriction is imposed. The paper
Clamp computes `min upper (max value lower)`, while the existing Lean graph uses
the opposite Min operand order; `paperClamp_eq` proves these equal for exact
linear orders. For `select/rule04`, the original condition is the constant false;
the Lean proof applies to every predicate. For `reverse/rule03`, the three paper
aggregated-axis groups are disjoint; the Lean theorem explicitly takes that
well-formedness condition and proves the output axis mask, rather than assuming
that the masks coincide. These proofs do not apply the exact-order results to IEEE
NaNs, and do not establish implementation correspondence.

The Concat list model follows the artifact's nonempty, right-recursive list
implementation, and its flat-graph agreement is separately proved. For touching
Slices, `unit_stride_adjacent` derives coordinate adjacency from the paper's
unit stride, valid Slice and shared boundary; the proof handles empty slices.
The Slice size lemmas derive the paper's output count from its positive stride
and bounds, including zero length. `Iota.broadcast_composition` constructs and
checks the composed signed axis map rather than assuming the two maps are equal.
The real division model and paper's finite real division both return zero at a
zero denominator; integer division is only used with denominator one here.
The two Min/Max proofs use `WithBot` or `WithTop` to model the actual infinity
constant against a finite input; they do not claim a general IEEE semantics.

The DynamicSlice and DynamicUpdateSlice proofs derive that the project's clamp
returns the paper's start when the paper's bounds hold. For nested operations,
`compose_eq_added` proves that the actual two starts add as the artifact states.
Relabel uses lawful bijections on bounded axes; the result applies to the paper's
label renamings and more general permutations. The integer-remainder proofs use
Lean `Int.tmod` (truncation toward zero, dividend returned for divisor zero).
TensorRight calls Grisette `remOr` with the dividend as its default; the exact
[Grisette revision](https://github.com/lsrcz/grisette/blob/d1a6c6d016cb341a026aa9b05dda3dc8080ee25b/src/Grisette/Internal/Core/Data/Class/SafeDiv.hs)
used by the artifact defines it as Haskell `rem` with that default. The Lean
`unguarded_shift_refuted` theorem also demonstrates why the paper's sign guard
for `divmod/rule07` matters: shifting −2 by 3 changes its remainder modulo 3.

The full and nested Slice results separately derive their output shapes from the
paper’s start, limit and unit-stride attributes, then prove equality of all bounded
coordinates. They handle zero extents as well as nonempty shapes.

The no-contraction Dot result uses the actual batch/free coordinate projections
of the existing Dot model, including arbitrary axis permutations. The reduction
proof distributes a scalar constant over the paper's exact zero-initialized sum,
including empty fibers. Neither result covers IEEE rounded arithmetic.

For zero-dimension Dot, `grouped_empty` connects zero batch/free/contract
axes to an empty output or contraction; the latter yields a zero sum. Reduction
of unit axes is tied to the actual reshape coordinates and element count; the
relabel variant uses the identity value-axis map because the renamed axis is
subsequently reduced. The all-zero Pad proof uses a bounded edge-Pad model with
zero interior padding and explicit shape transport.

The partial-concatenation Slice cases derive the unit-stride interval length and
second-operand offset, then reuse the checked contiguous-segment theorem. The
dynamic-Slice relabel case represents a label rename by the identity value-axis
map and retains the unchanged, valid dynamic start.

The independent TensorRight run used the pinned image digest documented in
`artifact-rerun.json`, but rebuilt the frozen `rules` and `src` trees because
the image's bundled sources differ from the frozen artifact. The frozen and
bundled source hashes are preserved separately. The run used the artifact's
`stack build` and `runall.sh`, without container network access; the only
printed-label mismatch was a known shell wildcard expansion in `reduce/rule03`.
`record_artifact_rerun.py` checks the 118 per-case outcomes against the archive.
As in the archive, the success for `dot/rule03` verifies `lhs = lhs`, not the
associativity statement its label names.

For `slice/rule13`, a length-10 input and Slice bounds `[2,8)` with stride 2
are valid, but the paper formula yields replacement start −3. Its own Slice
semantics requires a nonnegative start. Lean checks the arithmetic and validity,
and TensorRight itself confirms the fixed example for Bool, Int and Real after
adding only a precondition fixing those inputs. See `reverse-slice-witness.md`
for the patch, full logs and reproduction script. This refutes the artifact's
model rule; it does not demonstrate an XLA compiler bug.

The Slice/Broadcast cases compare actual coordinate projections and derive
matching retained-axis sizes from equal Slice attributes. The full-retained
case also proves the paper's piecewise quotient/remainder ceiling formula for
added axes. The DynamicSlice/Broadcast case uses the same projections and shows
that clamping leaves each paper-valid start unchanged.

The new padding cases compare actual bounded update, Pad and Slice coordinates,
including empty inputs. `paper_shape`, `translated_valid` and `paper_pad_extent`
derive the paper's shapes and transformed Slice validity rather than assuming
the resulting coordinates agree. The grouped-sum cases use bounded coordinate
groups for every named axis; `dot_coordinate_sum` and `reduce_coordinate_sum`
connect these to the existing tensor models, `sum_coordinate_groups` proves
combined-group enumeration, and `concat_pair_coordinate` connects actual Concat
segments. The Dot associativity theorem proves the paper's intended statement;
the independently rerun artifact still checked `lhs = lhs` for that case.
