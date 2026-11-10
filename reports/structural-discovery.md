# Structural C++ discovery and lexical reconciliation

Source revision: e58e523b11f1fde802a493a776d158007486e1bf.
Packages: tree-sitter 0.25.2 and tree-sitter-cpp 0.23.4; package download provenance
is in parser-install.json. Local binaries live in ignored .parser-deps/.

The structural inventory records candidate call expressions, enclosing functions,
if-branch positions, short-circuit prerequisites, loop/lambda/case context and
parse-error overlap/owner flags. The initial whole-file pass finds 952 candidate
calls and 84 explicit error/missing nodes. These are discovery measurements,
not rewrite counts or successful C++ verification.

For example, the compatibility call at line 1513 is evaluated inside an if
condition after IsAll(rhs,1) has succeeded. It cannot itself be treated as proof
that replacement succeeded. The enclosing PRED-type branch is recorded separately.
Prior early exits and helper effects still require semantic/control-flow analysis.

Multiline receiver expressions initially put structural calls one line before
the lexical method-name location. Recording the field-name location reconciled
those differences. The structural scan now adds no calls absent from the lexical
scan, while 19 lexical sites have no structural call match. Fifteen are recognized
function declarators, rather than invocations.

The four remaining discrepancies were inspected in source:

- mutable_operand calls at lines 5021 and 5022 occur inside a macro invocation
  with an auto declaration. The grammar recovery does not retain those calls.
- RemoveRedundantStride at line 7616 is a function definition whose annotated
  parameter confuses recovery; it is not another invocation.
- SwapConvOperands at line 11248 is an invocation inside ABSL_ASSIGN_OR_RETURN;
  it remains an actual helper path requiring tracing.

All four remain explicit unresolved records in the generated artifact rather
than being silently deleted. Macro expansion, annotations and source recovery
must be addressed before treating structural coverage as exhaustive. The existing
lexical inventory and all mapped/residual sites remain authoritative discovery
inputs alongside this independent parsing mechanism.

Controls check &&/|| prerequisites, condition evaluation versus then/else,
function declarations versus calls, and explicit malformed-source reporting.
Independent parsing is not independent semantic review: one primary agent
constructed both tools, and no proof of extraction correctness is claimed.

## Subsequent syntax-only macro view

The normalized inventory is `census/normalized-structural-sites.json`. A byte-
and newline-preserving adapter masks the assignment macro wrapper and turns its
two arguments into an assignment for parsing. Parenthesized declarations and
pointer annotations are handled explicitly. Original macro text/offsets and
unmodeled status-check/early-return behavior remain in the syntax-rewrite ledger.
Unsupported argument forms remain unmodified and are flagged, not guessed.

On the pinned file, this view has 959 candidate calls and no grammar errors.
All 12 unmatched lexical sites are function declarators. The earlier raw tree's
15-declarator classification was unreliable in error-recovery regions; three
actual helper invocations were within recovered declarator spans. Use the
normalized reconciliation for syntax discovery, and retain the raw report as
evidence of the initial parser failure. Do not promote raw recovery guesses
to semantic facts.

The missing macro-contained calls at 5021, 5022 and 11248 are recovered with
the same original source positions. RemoveRedundantStride at 7616 is recognized
as a declaration after masking its pointer annotation. Neither a grammar-clean
view nor this reconciliation proves source reachability, successful status
propagation, correct type interpretation or complete mutation discovery.

The adapter's transformations are syntax aids only. A call's enclosing syntax-
rewrite entries must be carried into any downstream guard/obligation extraction.
Controls cover Unicode before macros, exact byte/line preservation, parenthesized
types, macro text in comments and unsupported third arguments. The integrated
checkpoint requires a clean normalized parse and explicit classification of
every lexical-only site for this pinned snapshot.
