# Current scope: TensorRight-level model verification and runnable bug witnesses

The user's 2026-11-12 instruction supersedes the 2026-11-10 scope amendment.
Follow [the updated experiment plan](experiment-plan.md). Planning has been updated;
the proof campaign resumed on 2026-11-12.

For every uncertain requirement ask: **Is this required or assumed by the XLA
rewrite paper we are comparing against?** Verify what it requires. Record and
adopt what it assumes. Work beyond that is a separately labelled optional extension.

## Primary task

Prove the paper's mathematical rewrite rules in Lean under the same conditions,
or disprove the real implementation with a runnable counterexample. Start with
the 118 implemented paper-artifact rules and compare to its 115 successes; retain
unsupported/unimplemented cases and the newer 488 candidate entries separately.
Maximize resolved cases with little new code and effort. Reuse existing proofs.
A bounded campaign with explicit residuals can finish the comparison report.

The translation from C++ to the mathematical rule is an explicit, permitted
assumption. Establish high confidence through a short source/artifact explanation
and targeted checks when useful. Independent review is selective, not a mandatory
acceptance gate for every rule. Do not prove the translation, callers, graph
mutation, machine code, or the correctness of Lean/imported libraries.

The mathematical statement itself still needs proof: shapes, valid accesses and
values agree for every input admitted by the modeled rule. Do not assume the
rewrite equality, silently narrow its conditions, or replace arbitrary dimensions
with tests. Model Boolean/integer/real rules first. Machine-word, IEEE, layout,
effects and unsupported-operator extensions must not delay those results.

## Implementation counterexamples

The former blanket deferral of native pass investigation is superseded for
runnable counterexamples. Source reading and targeted XLA runs are in scope to
understand a translation or confirm a suspected bug. Confirm valid original input,
actual rewrite, observed wrong result/invalid output, and the relevant expected
behavior. Archive a reproducer with exact version/options/command/output.
A model-only refutation, timeout, harness failure or permitted numerical difference
is not an established implementation bug. A Lean counterexample certificate is
optional when a runnable compiler failure is already decisive.

## Acceptance and effort

Use the plan's separate model/implementation outcome columns and bounded work
blocks. Add support only for named terminal cases. Do not gate success on all dtype,
layout or effect variants absent from the paper's model. Keep legacy frozen
reports intact; their zero whole-record counters do not define current acceptance.
Build a small successor case table instead of rewriting the entire old machinery.

Positive results mean model proofs with correspondence assumed, not verified C++.
Report proved cases, counterexamples, remaining failures, code burden and assistance.
Retain evidence of prior work without relabelling it as fresh LLM discovery.
