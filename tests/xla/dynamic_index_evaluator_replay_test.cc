/* Copyright 2026 The OpenXLA Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
==============================================================================*/

#include <algorithm>
#include <cstdint>
#include <iostream>
#include <limits>
#include <memory>
#include <string>
#include <vector>

#include "gtest/gtest.h"
#include "xla/hlo/evaluator/hlo_evaluator.h"
#include "xla/hlo/ir/hlo_module.h"
#include "xla/hlo/testlib/hlo_hardware_independent_test_base.h"
#include "xla/literal.h"
#include "xla/literal_util.h"

namespace xla {
namespace {

class DynamicIndexEvaluatorReplay : public HloHardwareIndependentTestBase {};

TEST_F(DynamicIndexEvaluatorReplay, SignedAndUnsignedBoundaryProfiles) {
  struct Case {
    const char* type;
    const char* name;
    int64_t signed_value;
    uint64_t unsigned_value;
    bool is_unsigned;
    int32_t expected_native;
  };
  const Case cases[] = {
      {"s32", "negative99", -99, 0, false, 0},
      {"s32", "negative1", -1, 0, false, 0},
      {"s32", "zero", 0, 0, false, 0},
      {"s32", "one", 1, 0, false, 1},
      {"s32", "three", 3, 0, false, 3},
      {"s32", "four", 4, 0, false, 3},
      {"s32", "large99", 99, 0, false, 3},
      {"s64", "minimum", std::numeric_limits<int64_t>::min(), 0, false, 0},
      {"s64", "negative1", -1, 0, false, 0},
      {"s64", "zero", 0, 0, false, 0},
      {"s64", "one", 1, 0, false, 1},
      {"s64", "maximum", std::numeric_limits<int64_t>::max(), 0, false, 3},
      {"u32", "zero", 0, 0, true, 0},
      {"u32", "one", 0, 1, true, 1},
      {"u32", "maximum", 0, std::numeric_limits<uint32_t>::max(), true, 3},
      {"u64", "zero", 0, 0, true, 0},
      {"u64", "one", 0, 1, true, 1},
      {"u64", "max_signed", 0, (uint64_t{1} << 63) - 1, true, 3},
      {"u64", "high_bit", 0, uint64_t{1} << 63, true, 0},
      {"u64", "maximum", 0, std::numeric_limits<uint64_t>::max(), true, 0},
  };
  for (const Case& test : cases) {
    SCOPED_TRACE(test.type);
    SCOPED_TRACE(test.name);
    const std::string type = test.type;
    const std::string hlo =
        "HloModule dynamic_index\nENTRY main {\n"
        "operand = s32[5] parameter(0)\nstart = " + type +
        "[] parameter(1)\nROOT result = s32[2] dynamic-slice(operand,start), "
        "dynamic_slice_sizes={2}\n}\n";
    ASSERT_OK_AND_ASSIGN(std::unique_ptr<HloModule> module,
                         ParseAndReturnVerifiedModule(hlo));
    Literal operand = LiteralUtil::CreateR1<int32_t>({0, 1, 2, 3, 4});
    Literal start = type == "s32"
        ? LiteralUtil::CreateR0<int32_t>(static_cast<int32_t>(test.signed_value))
        : type == "s64" ? LiteralUtil::CreateR0<int64_t>(test.signed_value)
        : type == "u32" ? LiteralUtil::CreateR0<uint32_t>(
                              static_cast<uint32_t>(test.unsigned_value))
                        : LiteralUtil::CreateR0<uint64_t>(test.unsigned_value);
    std::vector<const Literal*> args{&operand, &start};
    HloEvaluator evaluator;
    ASSERT_OK_AND_ASSIGN(Literal output, evaluator.Evaluate(*module, args));
    const int32_t first = output.Get<int32_t>({0});
    EXPECT_EQ(first, test.expected_native);
    EXPECT_EQ(output.Get<int32_t>({1}), first + 1);
    const int32_t mathematical = test.is_unsigned
        ? static_cast<int32_t>(std::min<uint64_t>(test.unsigned_value, 3))
        : static_cast<int32_t>(std::clamp<int64_t>(test.signed_value, 0, 3));
    std::cout << "DYNAMIC_INDEX_RESULT type=" << type << " case=" << test.name
              << " native=" << first << " mathematical=" << mathematical
              << " agree=" << (first == mathematical) << "\n";
  }
}

}  // namespace
}  // namespace xla
