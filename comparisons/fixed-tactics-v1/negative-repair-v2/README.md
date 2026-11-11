# Control repair only

The original eight negative trials in ../results/ failed to parse because the
runner emitted `unfold` on raw proposition expressions. Those failures are
infrastructure errors, not evidence that the fixed policies rejected false goals.
The original sources, diagnostics, summary, first analysis and first validator
are retained unchanged. The original analysis's validated status is superseded
by the corrected acceptance check in tools/check_fixed_tactics.py.

This repair removes only that invalid unfolding command. It leaves all 176
measured target/policy trials, all policies, imported basis and selected statements
unchanged. Refutations.lean kernel-checks that the two propositions are false.
All eight corrected, well-formed policy trials fail normally, with the clean-
environment guard executed. No corrected trial is accepted. See manifest.json,
results.json and the individual sources/logs. These are development controls,
not an independent held-out audit.
