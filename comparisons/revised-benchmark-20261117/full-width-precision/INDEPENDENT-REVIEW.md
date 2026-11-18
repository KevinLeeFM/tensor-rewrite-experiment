# Independent review: full-width precision

**Verdict: accepted as a complete binary32 full-width no-op model case.** The
frozen guard is exponent width 8 and explicit mantissa width 23, which is the
full binary32 significand width minus its implicit bit. Under this guard the
Lean goal proves pointwise preservation of every `BitVec 32` input, then
function equality for any index type and operand. The proof uses no
floating-point approximation or source implementation fact to establish the
identity.

I checked the freeze and pinned source locations: `HandleReducePrecision`
returns the original operand when exponent width equals the primitive width
and `mantissa_bits + 1` equals the significand width. The evaluator has a
corresponding exact-precision fast path. Its later rounding implementation is
only context for the model's lower-precision controls; this packet does not
prove general reduced-precision behavior or backend implementation.

The theorem's universal bit-vector domain includes both signed zeros,
subnormals, both infinities, and every NaN sign/payload encoding. In
particular, the negative-zero, subnormal, and negative-NaN-payload controls
remain exact. Those are model-level bit-preservation observations; no native
execution was performed. Lower-precision tie controls are boundary probes,
not additional completed rewrite cases. A failed intermediate Lean goal in
`author.log` is proof-development diagnostics, not a counterexample; the
retained `clean.log` and fresh replay compile the final proof successfully.

Fresh replay with Lean 4.35.0 verified all four hashes and compiled
`WidthSpec`, `WidthProof`, and `WidthControls` in 0.391 s, 0.362 s, and
0.357 s (1.110 s total reported compiler wall). The theorem's axiom closure
was `[propext, Quot.sound]`. No build, download, native test, or benchmark was
run. Independent review time was not instrumented separately.

This accepts the exact-width mathematical case under the adopted
C++-to-model translation assumption. It is not an independent proof of the
source translation, compiler mutation, or machine behavior.
