# Independent review of the three static Pad value goals

**Verdict.** Accept the declared static logical-value observations for
`HandlePad/unit-interior`, `HandlePad/empty-input` and `HandlePad/compatible`
at `03ee170dc079fe9a34b80d4b79bc522b6c0a9c94`. The review is independent
of authorship and includes fresh Lean 4.35.0 compilation. Credit these as
three model observations under their corresponding records. Complete
source-record dispositions and the overall benchmark gate remain open.

## Pinned source and mathematical scope

I checked the record identities against the pinned lexical sites in
[census/site-case-map.json](../../../census/site-case-map.json#L3475), and
checked the retained source bytes against the source manifest and the
dependency, indexing and dynamic-index supplements. The pin is XLA
`e58e523b11f1fde802a493a776d158007486e1bf`. The reviewed Pad model uses finite
extents, signed integer low/high edges and natural interiors. Per axis its
shape equation is `out = size + max(0, size - 1) * interior + low + high`.
The element domain is a single shared Lean `Type`, with arbitrary inputs and
fill. Its inverse sample succeeds precisely for a bounded input coordinate
`j` with `position = low + j * (interior+1)`. A tensor point gets the input
value when all axes sample successfully and the fill otherwise. This matches
the inspected static geometry: inference enforces scalar fill, matching ranks,
nonnegative interior and output extents, and the evaluator initializes with
fill then writes each in-range lattice point. The verifier calls inference.
Source-to-model translation is assumed. The shared type omits the source's
mixed-precision inference and conversions, and unbounded mathematical
integers omit fixed-width computation limits. Dynamic dimensions, physical
layout, metadata and graph mutation/ordering are outside these goals.
[Shape inference](../../../sources/xla/xla/service/shape_inference.cc#L742),
[verifier](../../../sources/xla/xla/service/hlo_verifier.cc#L2121),
[evaluator](../../../sources/xla/xla/hlo/evaluator/hlo_evaluator.cc#L6968)

| Record | Source check and exact result |
| --- | --- |
| `HandlePad/unit-interior` | After the empty return, the loop changes precisely positive interiors at extent one. The constructor preserves **both** signed edges and the original output dimensions, deriving the shape witness with `extent_unit`. `RevisedBenchmark.HandlePad.unit_interior` equates the original Pad to this constructed Pad for any nonempty input with at least one changed axis, including an output of extent zero. It applies historical `pad/rule02` using low-edge equality and the per-axis unchanged-spacing-or-unit disjunction. The retained `util.h:501–503` documents that the precheck tests for any nonzero interior. Its out-of-line implementation is absent from this snapshot. The retained `TrivialInteriorPadding` test at lines 6392–6427 corroborates the interpretation and was inspected as source. |
| `HandlePad/empty-input` | The first dispatch tests whether the input is an array with any zero dimension, then builds a scalar Broadcast with no mapped axes at the original output shape. `RevisedBenchmark.HandlePad.empty_input` equates the original Pad to that constant-fill tensor at every legal output index. A successful sample would supply an element of `Fin 0`; it is impossible, even when a valid signed shape equation has nonempty output. A rank-zero shape has no axis and fails the guard. |
| `HandlePad/compatible` | The `all_zero` loop checks **edge** padding only. Replacement also goes through `ReplaceInstructionIfCompatible`: the helper declines control predecessors, uses `SameShape`, and requests sharding/frontend-attribute preservation. `SameShape` uses `ShapeUtil::Equal` or `Compatible` depending on layout sensitivity; the latter ignores layout and dynamic flags. `RevisedBenchmark.CompatiblePad.correct` treats the equal-static-shape homogeneous logical subset. Zero edges reduce its per-axis extent equation to `max(0,s−1) * interior = 0`; an observed coordinate then either has zero index or has zero interior, so every sample is the original coordinate. Earlier returns exclude empty inputs and positive singleton interiors from this source site. The stronger model identity deliberately includes those instances: the positive-interior witness establishes the model's strength and cannot establish source reachability at the compatible site. Any reached positive static equal-shape zero-edge case has zero interior on every axis. |

Source anchors for the three branches are [6198–6251](../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc#L6198),
the [compatibility helper](../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc#L858),
[`SameShape`](../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc#L623)
and [its layout-insensitive predicate](../../../sources/xla/xla/shape_util.cc#L959).
The [later broadcast projection](../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc#L6253)
mutates the original Broadcast and has its own mapping/use-count guards. The
[negative-edge path](../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc#L6329)
has its own option, earlier-return conditions, clamped Pad, Slice and layout
checks. Signed edge parameters in the first two goals do not settle that
different replacement. Both later paths are outside this review.

## Freeze and fresh replay

The signed specification and checker match freeze
`8aae9c82049dfd84b886334c9e019081cea36497`. The compatible contract,
specification and hash list match freeze
`c3a96fa4c2c5d11914ef16f86b314c2a7d435428`. All 17 signed freeze entries and
all eight compatible hash entries matched. I re-stated the quantified equality
types independently in temporary Lean examples and assigned the three fully
qualified declarations at those types. The proof blob SHA256s are
`a4e5ec1db179200057a95b1971086e59eb2e8bace041a16b757301d0f0db8361` (signed)
and `5fdf602e6d75e9977271a1374fe8d328c5b7a87dc7460f19cf253caf1ee1c6a1`
(compatible).

I read the extracted ranges directly from Git baseline
`672928dbb90a7607c24a7d0281a7db117036608c`. The custom dependency graph for
each spec ends at `SignedPadHistorical → SignedPadLattice →
TensorRewrite.Pilot.Tensor → Std`. The extractor copies Tensor byte-for-byte,
replaces the original imports by these narrower imports, retains historical
namespaces `TensorRewrite.Theory.LatticeIndex` and
`TensorRewrite.PaperComparison.SignedPad`, and closes the same namespaces at
the end of each excerpt. It copies LatticeIndex lines 4–50 and 58–91, dropping
the convolution bridge, then SignedPad lines 6–97, ending with historical
`unit_interior`. The only retained proof-text edits qualify the integer
`add_zero` in lattice decoding and substitute Std integer identities in the
two simp lists in `sample_some` and `sample_unit`. The extent, shape, decode,
assemble, sample, selection and tensor definitions are unchanged. The new
goals use distinct `RevisedBenchmark` namespaces. Historical reuse is explicit
for unit-interior, and compatible reuses coordinate characterizations. This
does not rerun or update the Mathlib-based historical comparison. I found no
unchecked proof scaffolds, new axioms or `native_decide` in these packets or
their generated custom closure. Adding one byte to the generated historical
model in my scratch stage produced the expected frozen-source mismatch.

| Fully qualified theorem | Fresh transitive axiom report |
| --- | --- |
| `RevisedBenchmark.HandlePad.unit_interior` | `propext, Classical.choice, Quot.sound` |
| `RevisedBenchmark.HandlePad.empty_input` | `propext, Quot.sound` |
| `RevisedBenchmark.CompatiblePad.correct` | `propext, Classical.choice, Quot.sound` |

Re-run commands from the repository root. The per-module compiler commands
use a fresh temporary directory with only explicit custom modules and the
compiler's shipped standard-library artifacts. Normal Lean compilation checks
the proof bodies. No separate exported-proof checker or Std rebuild was run.

```sh
lean=/workspace/toolchains/lean-4.35.0-linux/bin/lean
root=$PWD
p=comparisons/revised-benchmark-20261117
python3 -B "$p/signed-pad/replay.py" --lean "$lean"
sha256sum -c "$p/pad-compatible/SHA256SUMS"
stage=$(mktemp -d)
python3 -B "$p/signed-pad/extract.py" "$stage"
PYTHONPATH="$root/$p/signed-pad" python3 -B -c 'import replay, sys; from pathlib import Path; replay.check_freeze(Path(sys.argv[1]))' "$stage"
cp "$p/pad-compatible/"Compatible{Spec,Proof,Controls}.lean "$stage/"
(
  cd "$stage"
  export LEAN_PATH="$stage"
  for name in TensorRewrite/Pilot/Tensor SignedPadLattice SignedPadHistorical CompatibleSpec CompatibleProof CompatibleControls; do
    "$lean" -o "$name.olean" "$name.lean" || exit
  done
)
```

## Discrimination and effort

- The signed controls replay the exact positive branch on shape `[1,2]` to
  `[2,3]`, with low/high pairs `(1,0)` and `(-1,1)`. The change clears
  interior 2 on the singleton axis while retaining interior 1 on the
  nonunit axis. Coordinate `(1,1)` gives 8, and hole `(1,0)` gives 99.
  Besides replaying the supplied guard/shape checks, I independently tested
  a well-typed wrong replacement with both interiors zero and the second
  high edge 2 to preserve output shape. It gives 8 at the hole, hence differs
  from the actual replacement. The supplied fully cropped output and
  rank-zero guard rejection also compile.
- The empty-input control uses shape `[0,2]` to `[2,2]`, with low/high
  `(-1,3)` and interior 4 on the zero axis. The actual output point `(1,0)`
  yields 42. An added kernel-checked discrimination test evaluates both sides
  there and rules out a constant-zero replacement at the same shape.
- The compatible controls cover shape `[1,3]` with both edges zero and
  interior `[4,0]`, rank zero, and a shifted same-shape negative control.
  The shift has low 1/high -1 on size 2 and changes the origin from 7 to fill
  99. I added a complementary kernel test with zero edges, size 2 to size 3
  and interior 1, where the middle point is a hole with value 99 and the
  dimensions differ. It isolates the need for the equal-shape guard.

The signed runner completed in **2.160 s** external wall (2.034 s summed
Lean invocations). Compatible six-module replay completed in **1.860 s**
including setup on the final pass, with **1.805 s** summed Lean invocations.
That pass also recompiled signed spec/proof and ran the two extended temporary
control files, taking **3.128 s** total for the combined command. Extra
signed/compatible controls took 0.387 s/0.314 s, and stale-hash and source
verification took 0.011 s. All final compiles exited 0 without warnings.
Earlier compatible runs returned clean base results (2.088 s and 2.352 s
including setup). My initial supplementary compatible control failed after
0.312 s because the dependent bound was open; reducing it to the closed
inequality `1 < 3` fixed the scratch-only control. An initial timing command
failed before Lean because `/usr/bin/time` was unavailable; shell timing
replaced it. These are review overhead, separate from author measurements in
[ATTEMPT.md](ATTEMPT.md). Review started at 22:21:32 UTC on 2026-11-17. The
22:24:56 UTC checkpoint was 204 s after start and covered source inspection, fresh checks and report drafting.
Exclusive active reasoning, token costs and original historical discovery
time are unknown. The reviewed results support no comparative speedup claim.
