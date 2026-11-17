# Exact static slice-axis classification proof candidate

Freeze commit `49caa1d`. For both source-shaped transformations, a legal
original axis retains its original declared output extent and has legal
transformed bounds exactly when its stride is one or its start precedes its
limit. Four declarations compile on Lean 4.35.0. The two auxiliary
declarations prove equality of logical input coordinates on that domain, with
a mirrored output index on reversed axes. Independent review remains pending.

The proof treats truncation at the empty endpoint explicitly. With stride one
the reverse step count is −1 and the transformed interval is empty. With
greater stride it is zero and the transformed interval has unit length, which
violates the retained zero-count declaration. It can also cross the original
extent boundary. For a positive span and positive stride the floor step count
selects a valid last point; both the old interval and adjusted interval have one
plus that step count many elements. A selected redundant nonempty stride has
only one selectable point. The unchanged branch retains the original bounds.

The logical lookup equations are per-axis. Graph dispatch, cross-axis and
whole-tensor integration, layout, dynamic extents, signed machine overflow, and
C++–Lean correspondence remain outside this packet. No source-record completion
or new implementation witness is claimed by these theorems.

The historical XLA e58e523b11f1fde802a493a776d158007486e1bf archive records
successful original verification, rejected rewritten verification for both
cases, and a successful nonempty control. The retained source file and six
files listed in its result manifest match the archive hashes. It was inspected
without rerunning the native pass. The historical Lean witness was rebuilt and
reused. New Lean controls cover zero-extent and positive-extent unit-stride
empty endpoints, non-unit out-of-bounds endpoints, selected and unselected
nonempty stride cases, a wrong reverse lookup, and the difference between
Euclidean and truncating division.

## Timing

- Setup and freeze started at 22:33:51 UTC. The first complete freeze
  compilation passed at approximately 22:35 UTC in 0.407, 0.396 and 0.283 s
  for the semantic dependency, historical certificate and frozen statement.
  The first runner call encountered a missing GNU time binary and was adjusted
  to Bash timing. A sed command failed during that one-line repair; the next
  edit fixed the harness. Two symbol probes reported unavailable guessed names;
  the usable checks supplied the actual Int floor and tdiv lemma names.
- Proof compilation attempts reached the final module for 0.417, 0.437 and
  0.531 s before success. The first reported a residual numeral equality and
  unavailable tactics/lemma. The second reported the specification wrapper
  obscuring the guard split and a nonnegativity obligation after distributing
  multiplication. The third compiled the reverse classification but left a
  short linear simplification and a consumed hypothesis in the stride proof.
  Those unsuccessful compiler invocations reported temporary error-recovery
  axiom output. The source included no bypass and the successful output
  reports only the permitted axioms.
- First successful full replay finished at 22:37:02 UTC, 191 s after setup
  started. The current replay log reports 0.391, 0.293, 0.297 and 0.630 s
  for the dependency, certificate, specification and proof/control module.
  The archive hash check finished by 22:37:22 UTC. Reviewer time is separate
  and pending. Active reasoning and token costs are unavailable.
