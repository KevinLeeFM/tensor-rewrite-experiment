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
#include "xla/hlo/transforms/simplifiers/algebraic_simplifier.h"
#include "xla/literal.h"
#include "xla/literal_util.h"
#include "xla/service/hlo_verifier.h"
#include "xla/xla.pb.h"

namespace xla {
namespace {

class NestedDynamicSliceReplay : public HloHardwareIndependentTestBase {
 protected:
  DebugOptions GetDebugOptionsForTest() const override {
    DebugOptions options = HloHardwareIndependentTestBase::GetDebugOptionsForTest();
    options.set_xla_hlo_evaluator_use_fast_path(false);
    return options;
  }
};

Literal IndexLiteral(const std::string& type, uint64_t unsigned_value,
                     int32_t signed_value) {
  if (type == "s32") return LiteralUtil::CreateR0<int32_t>(signed_value);
  if (type == "u32") {
    return LiteralUtil::CreateR0<uint32_t>(static_cast<uint32_t>(unsigned_value));
  }
  return LiteralUtil::CreateR0<uint64_t>(unsigned_value);
}

TEST_F(NestedDynamicSliceReplay, TypedClampVersusEvaluatorConversion) {
  struct Case {
    const char* name;
    const char* inner_type;
    const char* outer_type;
    uint64_t inner_unsigned;
    uint64_t outer_unsigned;
    int32_t inner_signed;
    int32_t outer_signed;
    int32_t before;
    int32_t rewritten;
  };
  const uint64_t high = uint64_t{1} << 63;
  const Case cases[] = {
      {"inner_high", "u64", "u64", high, 1, 0, 0, 1, 5},
      {"outer_high", "u64", "u64", 1, high, 0, 0, 1, 5},
      {"both_high", "u64", "u64", high, high, 0, 0, 0, 8},
      {"max_signed", "u64", "u64", high - 1, high - 1, 0, 0, 8, 8},
      {"signed_bounds", "s32", "s32", 0, 0, -99, 99, 4, 4},
      {"inner_high_mixed", "u64", "s32", high, 0, 0, 1, 1, 5},
      {"outer_high_mixed", "s32", "u64", 0, high, -99, 0, 0, 4},
      {"u32_max", "u32", "u32", std::numeric_limits<uint32_t>::max(),
       std::numeric_limits<uint32_t>::max(), 0, 0, 8, 8},
  };
  for (const Case& test : cases) {
    for (bool run_pass : {false, true}) {
      SCOPED_TRACE(test.name);
      SCOPED_TRACE(run_pass);
      const std::string hlo =
          "HloModule nested_dynamic_slice\nENTRY main {\n"
          "data = s32[10] parameter(0)\ninner_start = " +
          std::string(test.inner_type) + "[] parameter(1)\nouter_start = " +
          test.outer_type + "[] parameter(2)\n"
          "inner = s32[6] dynamic-slice(data,inner_start), dynamic_slice_sizes={6}\n"
          "ROOT outer = s32[2] dynamic-slice(inner,outer_start), dynamic_slice_sizes={2}\n}\n";
      ASSERT_OK_AND_ASSIGN(std::unique_ptr<HloModule> module,
                           ParseAndReturnVerifiedModule(hlo));
      ASSERT_FALSE(module->config().debug_options().xla_hlo_evaluator_use_fast_path());
      Literal data = LiteralUtil::CreateR1<int32_t>({0, 1, 2, 3, 4, 5, 6, 7, 8, 9});
      Literal inner = IndexLiteral(test.inner_type, test.inner_unsigned, test.inner_signed);
      Literal outer = IndexLiteral(test.outer_type, test.outer_unsigned, test.outer_signed);
      std::vector<const Literal*> args{&data, &inner, &outer};
      HloEvaluator before_evaluator;
      ASSERT_OK_AND_ASSIGN(Literal before, before_evaluator.Evaluate(*module, args));
      const std::string original_hlo = module->ToString();
      bool changed = false;
      if (run_pass) {
        AlgebraicSimplifierOptions options;
        options.set_is_layout_sensitive(true);
        options.set_run_to_fixed_point(false);
        AlgebraicSimplifier simplifier(options);
        ASSERT_OK_AND_ASSIGN(changed, simplifier.Run(module.get()));
        ASSERT_TRUE(changed);
        const HloInstruction* root = module->entry_computation()->root_instruction();
        ASSERT_EQ(root->opcode(), HloOpcode::kDynamicSlice);
        EXPECT_EQ(root->operand(0)->opcode(), HloOpcode::kParameter);
        EXPECT_EQ(root->operand(1)->opcode(), HloOpcode::kAdd);
      } else {
        EXPECT_EQ(module->ToString(), original_hlo);
      }
      HloVerifier verifier(/*layout_sensitive=*/false, /*allow_mixed_precision=*/true);
      ASSERT_OK(verifier.Run(module.get()).status());
      HloEvaluator after_evaluator;
      ASSERT_OK_AND_ASSIGN(Literal after, after_evaluator.Evaluate(*module, args));
      EXPECT_EQ(before.Get<int32_t>({0}), test.before);
      EXPECT_EQ(before.Get<int32_t>({1}), test.before + 1);
      const int32_t expected_after = run_pass ? test.rewritten : test.before;
      EXPECT_EQ(after.Get<int32_t>({0}), expected_after);
      EXPECT_EQ(after.Get<int32_t>({1}), expected_after + 1);
      std::cout << "NESTED_SLICE_RESULT case=" << test.name
                << " run_pass=" << run_pass << " changed=" << changed
                << " before=" << before.Get<int32_t>({0})
                << " after=" << after.Get<int32_t>({0}) << " rewritten_verified=1\n"
                << "ORIGINAL_HLO\n" << original_hlo
                << "REWRITTEN_HLO\n" << module->ToString();
    }
  }
}

}  // namespace
}  // namespace xla
