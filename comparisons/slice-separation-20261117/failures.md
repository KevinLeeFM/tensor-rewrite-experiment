# Prototype integration failures

The first fresh replay failed while compiling the prototype facade: a module documentation comment before `public import` caused Lean 4.35.0 to reject the import as not at the beginning of the module. Moved the import above the documentation comment; no declarations or assumptions changed. Retained this failure rather than counting it as proof failure.

The second replay reached the core-only negative test and correctly rejected the missing transform, but the harness expected the text `unknown constant`; Lean reported `Unknown identifier`. Updated the expected diagnostic marker. This was a harness assertion failure, not a passed or failed semantic theorem.
