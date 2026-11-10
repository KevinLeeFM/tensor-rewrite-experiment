# Compiler-backed call and delegation evidence

Source: XLA e58e523b11f1fde802a493a776d158007486e1bf,
algebraic_simplifier.cc SHA256
1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f.
This strengthens discovery/correspondence evidence. It does not freeze semantic
obligations or accept source rewrites. Lean development remains1572 code lines.

## Actual compiler inputs, separate from the syntactic approximation

Bazel's cached CppCompile actions identify the real flags, feature definitions,
include paths and hermetic compiler. The archived selected action uses -fPIE;
the alternate -fPIC action is retained in the query. The AST run preserves the
selected preprocessing/type flags and omits object/dependency output generation,
adding syntax-only JSON AST output filtered by qualified-name substring xla::.
It compiles the unmodified original C++, rather than the byte-preserving macro
view used by the syntactic parser.

Clang22.1.8 (LLVM ca7933e47d3a3451d81e72ac174dcb5aa28b59d1) completes successfully.
Compiler identity, command, action, source hash and diagnostics are archived in
reports/typed-ast-v1. Its compressed AST preserves1506189952 raw bytes. The
extraction reads10269 concatenated JSON documents, retaining131 main-file roots
and56909 declaration identities. These are compiler representation counts, not
source obligations or proof coverage.

A preprocessing query records1745 dependency paths and content hashes. A later
live recheck confirms that every recorded dependency and the compiler binary
remain unchanged. This capture occurs after AST compilation; it is not a
hermetic pre-compilation snapshot or a materialized compiler-input closure.
The analysis covers this archived configuration, not every preprocessor setting.

## Source alignment and what typing resolves

Source definitions are matched by name and exact source-body endpoint/range.
Previous declaration identities connect header prototypes to definitions.
Template instantiations remain separate typed declarations of the same source
function. Calls align only on exact original source range and lexical owner;
macro expansion/spelling coordinates are retained separately. No approximate
containment match is silently accepted as a callee correspondence.

| Discovery property | Observed typed evidence |
| --- | ---: |
| Original source functions represented | 161/161 |
| Typed function definitions/instantiations | 206 |
| Original syntactic call sites | 7391 |
| Exact range/owner matches | 7105 |
| Remaining unmatched macro invocations | 286 |
| Previously ambiguous local-name candidate sets | 113 |
| Those selecting local definitions | 110 |
| Those selecting external members | 3 |
| Previously unnamed functor/lambda calls with selected operator() | 8 |
| Source sites retaining a dependent template variant | 25 |
| Local static declaration-dependency edges | 292 |
| Extracted schema delegations reconciled with typed targets | 35/35 |

The three external selections are IsAll member calls; name-only matching had
also offered local IsAll definitions. Keeping their receiver/selected declaration
prevents the wrong helper contract from being attached. The eight unnamed
expressions select four Shape::Equal functor calls and four immediate lambdas.
Thirteen syntactic static_cast expressions are now recognized as typed casts,
not unresolved function invocations.

All286 remaining unmatched syntactic invocations are macros: logging, checks
and status propagation. They remain present in the original inventory. Their
expanded/implicit expressions appear in the compiler AST, but the macro token
range is not equated to one ordinary callee. These macros can affect execution
or failure behavior, so they are not declared irrelevant or non-rewrites.

The25 dependent template sites also have concrete instantiated variants in this
AST. The dependent pattern is retained; observing some instantiations does not
prove every admissible type instantiation or runtime target. Member-declaration
selection does not close virtual dispatch. Typed constructors, casts and implicit
operators are retained as additional expressions, not added to the rewrite count.

## Caller/helper packets and semantic proof boundaries

census/typed-delegation-evidence.json reconciles every existing delegation schema
with its unique source call, compiler-selected local function and exact helper
body identity. It retains target-owned source schemas, relevant scoped model
theorems and recursive dependencies. For example, the empty-reduction caller now
has an explicit typed link to BroadcastReduce and its two pending model results.
This supplements the older replacement/mutation candidate packet surface, which
did not contain that delegated call.

The packets preserve null accepted proofs. They establish static declaration
dependencies in the recorded compilation, not complete guard composition,
failure propagation, alias effects, metadata/control behavior or source-to-Lean
correspondence. The current schemas are still agent-extracted and await
independent semantic reconciliation. No N/F denominator or whole-source
correctness result follows from compiler parsing or callee selection.

## Controls, size disclosure and replay

Controls exercise concatenated/large/escaped JSON documents and truncated input;
compile-flag preservation and dependency escaping; selected overload/prototype
identity versus same-name candidates; retention of dependent variants; indirect
value callees and foreign-header macro spelling; and omission/retargeting or
proof-scope promotion of delegation packets. The integrated checkpoint and45
tool/evidence tests pass. Existing Lean proofs and their1572-line accounting
are unchanged. Accepted source rewrites remain0.

The six new auxiliary Python analysis scripts contain559 physical lines and
30081 bytes, recorded separately in reports/typed-automation-sizes.json.
Modified checkpoint/test sources are retained in the integrated checkpoint's
file identities. These Python lines are analysis infrastructure, not Lean code
or kernel-checked proof burden; they do not disappear into a claimed proof-size
improvement.

snapshots/typed-call-census-v1.zip preserves compiler output, derived declarations,
source identities, syntactic/typed maps, delegation evidence and the six scripts.
reports/typed-call-clean-replay.json records reconstruction and validation in a
fresh directory without Bazel or Lean caches. This replays archived compiler
output; it does not rerun C++ compilation, Lean proofs or independent review.
The earlier complete Lean replay remains reports/reduction-clean-replay.json.

For new compiler output, recover a Bazel compile action, run
tools/run_typed_ast.py with --action-json and a new typed-ast-vN archive, then
tools/extract_typed_ast.py and tools/capture_typed_dependencies.py for that archive.
The current inventory tools consume the explicitly pinned v1 evidence. The
snapshot's REPLAY.md gives the three offline commands used for its replay.

Remaining work includes macro/path/failure composition, alias and implicit-effect
review, permitted configurations/type instantiations, typed source-to-theorem
statements and independent semantic census reconciliation. The diverse reviewed
pilot, full campaign, diagnosis and final research verdict remain unfinished.
