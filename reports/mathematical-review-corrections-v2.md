# Mathematical foundation: remaining profile correction

The independent recheck of commit `1f559e2` resolved MF-02 and confirmed all349
registered declarations and unchanged frozen mathematical sources, but found
MF-01-R1: two exact-integer Select contraction witnesses had a false floating-point
profile description. Their statements and proofs were valid throughout.

The fallback override for `algebraic_refutation` is removed. Both witness rows now
use the retained pilot manifest's exact profile: mathematical integer contraction
with unit filter and uniform Boolean Select, with branch scalars2 and3. No new
benchmark labels or closure status are assigned. A regression check compares the
witness metadata directly with that profile and retains its certificate kind and
empty candidate-label set. The original review and first correction recheck are
preserved unchanged.

This correction commit isolates the inventory tool, two generated metadata rows,
and that regression check from the separate uncommitted scalar-domain extension.
Its frozen registered baseline remains349 declarations/89 theory statements/4165
custom lines; the moving worktree may contain later mathematical work. A further
independent recheck of MF-01-R1 is pending. No claim about all349 statements,
benchmark correspondence, source correspondence or the full workload is implied.
