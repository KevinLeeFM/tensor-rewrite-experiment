# Tensor rewrite verification experiment

This is an independent Git/Lake project. Do not apply the unrelated sibling
SeaTypist project's language contracts to this experiment.

Read README.md, docs/theory-scope.md, docs/dependencies.md and
docs/experiment-plan.md before work. The 2026-11-12 plan supersedes older scope
rules. Ask whether each unclear requirement is required or assumed by TensorRight: verify requirements,
adopt disclosed assumptions. C++ correspondence is assumed with high confidence,
not proved. Source reading and targeted native runs for counterexamples are allowed.
Prioritize the paper's 118 implemented model rules, reuse and bounded attempts;
optional IEEE/layout/general-framework work must not block the primary comparison.
The original research notebook is maintained separately at ../notes/ when present;
its TODO.md remains the current research queue. Core build/replay must work
without that sibling notebook. Archived planning copies are in docs/.

Keep source pins, exact guards, observation contracts and proof assumptions explicit.
Do not equate source discovery, local normalization or theorem counts with verified
source-rewrite coverage. Use separate model-proof and runnable-bug outcomes.
Independent review is selective, not a universal gate. Support tasks must name
terminal cases and follow the plan's effort limits. Preserve immutable packets
and native archives.
Record library reuse and all new adapters/extension lines separately from imported
library code. Preserve the historical Std-only baseline in Git and snapshots.

Lean code follows docs/lean-style-guide/README.md. Use module/public imports,
autoImplicit false and documented declarations. No sorry, admit, new project axioms
or native_decide in accepted proofs. Inspect transitive axiom dependencies.

Never commit .lake/, external checkouts or build caches. Pin dependencies in
lakefile.toml and lake-manifest.json. Run lake build and
python3 tools/check_libraries.py for dependency changes. Use tools/checkpoint.py
for historical evidence only when that is in scope. For active mathematical
work use targeted Lean builds and relevant checks; run python3 tools/check_theory.py
at integration points. Do not launch code-correspondence proofs. Do not run a full
historical replay or generate a new review packet for every small lemma.
