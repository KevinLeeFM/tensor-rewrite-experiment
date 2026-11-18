# Convolution, window and update results

- [singleton-window-crop](../singleton-window-crop/INDEPENDENT.md)
- [conv-select-scale](../conv-select-scale/REVIEW.md)
- [conv-bias-distribute](../conv-bias-distribute/REVIEW.md)
- [partial-add-zero](../partial-add-zero/REVIEW.md)
- [nested-update-word](../nested-update-word/ADJUDICATION.md)
- [window-historical-reuse](../model-audit/window-reuse-review.md)

All native and source-correspondence claims remain separate. The two convolution replays used Lean Std and the prior binary32 rounder. The wider convolution sum library still requires the five pinned external roots described in the [cache preflight](convolution-cache-preflight.md).
