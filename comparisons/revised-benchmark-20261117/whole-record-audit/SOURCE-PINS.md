# Source bytes used for the Reverse recheck

In addition to the sources already tracked in this repository, the coordinator obtained three individual files from the official OpenXLA repository at the frozen revision. No repository or dependency build was needed. The independent reviewer hashed and inspected those bytes. These upstream links and hashes identify the missing portion of the earlier source packet.

| Source | Bytes | SHA-256 |
| --- | ---: | --- |
| [CommonFactors](https://raw.githubusercontent.com/openxla/xla/e58e523b11f1fde802a493a776d158007486e1bf/xla/util.cc) | 18,648 | ab845e9925330825efaae95b043fd4beccb4a9f29a6474ef711ef4d17d6d38c4 |
| [Reshape construction](https://raw.githubusercontent.com/openxla/xla/e58e523b11f1fde802a493a776d158007486e1bf/xla/service/hlo_creation_utils.cc) | 44,379 | ae3da9af029bf00c8eeaee3565f46ac068638d37c1df7a0a760072afb23061c0 |
| [Dynamic dimension inference](https://raw.githubusercontent.com/openxla/xla/e58e523b11f1fde802a493a776d158007486e1bf/xla/service/dynamic_dimension_inference.cc) | 123,829 | 7a1d5e88d18c9bc6d25dce0f9bef40056313ac67bb34982fcb16c4f949f204c9 |

From this directory, run `python3 check_common_factors.py /path/to/pinned/util.cc` to confirm the four concrete boundary vectors. The check compiles the exact CommonFactors function body against small standard-library substitutes for Abseil spans, equality and vectors, product and error streaming. All four inputs have equal products, with tiny integer dimensions. Compiling took 0.925 s and execution 0.002 s. This is an extracted helper check, not a new native XLA pass run. The separate `python3 reverse_runtime_probe.py` illustrates why stored bounds plus total realized element count alone are insufficient.
