# Source and adoption

This directory contains the complete README and all 18 chapters of
[A Lean Style Guide for Software](https://github.com/saviorand/lean-style-guide),
by the saviorand/lean-style-guide contributors, at revision `5a1bab3990237788a8cb1f815644eceb0dc27b56`.
Adopted by the user on 9 November 2026 for Lean projects governed by this notebook.
The [canonical policy](../lean_style.md) states adoption, local supplements and
explicit project exceptions. No chapter is merely advisory by omission.

The guide text is reproduced under [CC BY 4.0](LICENSE). Its code examples are
under [Apache 2.0](LICENSE-CODE). These are the upstream licenses. Attribution,
examples, explanations, rule anchors and source citations are retained.
The only modifications to copied Markdown are that relative links to omitted
upstream research and tools point to that same pinned GitHub revision. Research
notes and analysis scripts are supporting sources, not additional style rules.

The copied `lean-toolchain` records the upstream example toolchain. It does not
change any project toolchain. The README's example-check command is run from an
upstream checkout at the pinned revision, where `tools/check_examples.py` exists;
that checker and its results are not supplied by this documentation adoption.

For an update, inspect the upstream diff, replace the entire guide at one new
revision, preserve both licenses, and review the local exception table and
naming supplement. Verify all chapter links and rule anchors and record the
new revision and decision in the notebook. Do not silently track upstream main.
