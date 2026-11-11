# Exact scalar domains milestone

Four retained Log/Sqrt targets now have five explicit exact-real/principal-complex
profiles. The key result is that complex rewrites require branch/domain
partitions: log(exp z)=z iff −π<Im(z)≤π, while sqrt(z*z)=|z| iff Im(z)=0.
At2πi andi, respectively, Lean proves the unguarded statements false. Real
log/exp and sqrt-square are unrestricted; real log/sqrt requires positive input.
All five profiles have arbitrary-rank/extent tensor lifts.

Fourteen new declarations and eight separate symbolic controls pass kernel and
standard-axiom checks. New Lean is118 lines (H20/R79/A1/C18), giving4283 total.
Library reuse supplies real analysis, principal branches and norm identities;
new code derives complete complex domains and tensor lifts. The registered
theory/ledger totals are103/363, with four integration theorems separate.

The v1 fixture elaboration failure and an initial integration-test model-list
expectation are retained separately; the accepted v2 changes no mathematical
statement from v1. See `docs/scalar-domains.md`, the frozen v2 manifest and the
validation transcripts for exact conditions and scope. These14 declarations
await independent mathematical review; the earlier review covered the old89.
Rounded transcendental behavior, fast-math observations, complete scalar-control
coverage and the full-workload verdict remain open. Zero whole records closed.
Code correspondence remains user-deferred future work.
