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
#include <memory>
#include <string>
#include <vector>

#include "gtest/gtest.h"
#include "xla/hlo/evaluator/hlo_evaluator.h"
#include "xla/hlo/ir/hlo_computation.h"
#include "xla/hlo/ir/hlo_instruction.h"
#include "xla/hlo/ir/hlo_module.h"
#include "xla/hlo/testlib/hlo_hardware_independent_test_base.h"
#include "xla/hlo/transforms/simplifiers/algebraic_simplifier.h"
#include "xla/literal.h"
#include "xla/literal_util.h"
#include "xla/service/hlo_verifier.h"

namespace xla {
namespace {

class PredConstantGuardReplay : public HloHardwareIndependentTestBase {};

TEST_F(PredConstantGuardReplay, ActualHandlerRecognizesOnlySupportedViews) {
  struct Case {
    const char* name;
    const char* instructions;
    bool expected_changed;
  };
  const Case cases[] = {
      {"literal", "rhs = pred[2,2] constant({{true,true},{true,true}})\n", true},
      {"broadcast", "base = pred[] constant(true)\n"
                    "rhs = pred[2,2] broadcast(base), dimensions={}\n", true},
      {"copy", "base = pred[2,2] constant({{true,true},{true,true}})\n"
               "rhs = pred[2,2] copy(base)\n", true},
      {"dynamic_slice", "base = pred[3,3] constant({{true,true,true},{true,true,true},{true,true,true}})\n"
                        "rhs = pred[2,2] dynamic-slice(base,index,index), dynamic_slice_sizes={2,2}\n", true},
      {"reshape", "base = pred[1,4] constant({{true,true,true,true}})\n"
                  "rhs = pred[2,2] reshape(base)\n", true},
      {"reverse", "base = pred[2,2] constant({{true,true},{true,true}})\n"
                  "rhs = pred[2,2] reverse(base), dimensions={0,1}\n", true},
      {"slice", "base = pred[3,3] constant({{true,true,true},{true,true,true},{true,true,true}})\n"
                "rhs = pred[2,2] slice(base), slice={[1:3],[0:2]}\n", true},
      {"transpose", "base = pred[2,2] constant({{true,true},{true,true}})\n"
                    "rhs = pred[2,2] transpose(base), dimensions={1,0}\n", true},
      {"opaque_not", "base = pred[2,2] constant({{false,false},{false,false}})\n"
                     "rhs = pred[2,2] not(base)\n", false},
      {"nonuniform", "rhs = pred[2,2] constant({{true,false},{true,true}})\n", false},
  };
  for (const Case& test : cases) {
    SCOPED_TRACE(test.name);
    std::string hlo = "HloModule pred_guard\nENTRY main {\n"
                      "lhs = pred[2,2] parameter(0)\n"
                      "index = s32[] parameter(1)\n";
    hlo += test.instructions;
    hlo += "ROOT result = pred[2,2] and(lhs,rhs)\n}\n";
    ASSERT_OK_AND_ASSIGN(std::unique_ptr<HloModule> module,
                         ParseAndReturnVerifiedModule(hlo));
    const std::string before_hlo = module->ToString();
    Literal input = LiteralUtil::CreateR2<bool>({{false, true}, {true, false}});
    Literal index = LiteralUtil::CreateR0<int32_t>(99);
    std::vector<const Literal*> args{&input, &index};
    HloEvaluator before_evaluator;
    ASSERT_OK_AND_ASSIGN(Literal before, before_evaluator.Evaluate(*module, args));
    HloInstruction* lhs = module->entry_computation()->parameter_instruction(0);
    AlgebraicSimplifierOptions options;
    AlgebraicSimplifier simplifier(options);
    AlgebraicSimplifierVisitor visitor(options, &simplifier);
    // Invoke the real public handler directly so producer simplifications do
    // not erase the wrapper being tested. This is not a full traversal run.
    ASSERT_OK(visitor.HandleAnd(module->entry_computation()->root_instruction()));
    EXPECT_EQ(visitor.changed(), test.expected_changed);
    const bool root_parameter =
        module->entry_computation()->root_instruction() == lhs;
    EXPECT_EQ(root_parameter, test.expected_changed);
    HloVerifier verifier(/*layout_sensitive=*/false,
                         /*allow_mixed_precision=*/true);
    ASSERT_OK(verifier.Run(module.get()).status());
    HloEvaluator after_evaluator;
    ASSERT_OK_AND_ASSIGN(Literal after, after_evaluator.Evaluate(*module, args));
    for (int64_t row = 0; row < 2; ++row) {
      for (int64_t col = 0; col < 2; ++col) {
        EXPECT_EQ(before.Get<bool>({row, col}), after.Get<bool>({row, col}));
      }
    }
    std::cout << "PRED_GUARD_RESULT wrapper=" << test.name
              << " expected_changed=" << test.expected_changed
              << " changed=" << visitor.changed()
              << " before_after_equal=1 root_parameter=" << root_parameter
              << "\nORIGINAL_HLO\n" << before_hlo << "REWRITTEN_HLO\n"
              << module->ToString();
  }
}

TEST_F(PredConstantGuardReplay, LiteralStorageBoundaries) {
  const Literal empty = LiteralUtil::CreateR1<bool>({});
  EXPECT_TRUE(empty.IsAll(0));
  EXPECT_TRUE(empty.IsAll(1));
  const Literal mixed = LiteralUtil::CreateR1<bool>({true, false});
  EXPECT_FALSE(mixed.IsAll(0));
  EXPECT_FALSE(mixed.IsAll(1));
  const Literal ones = LiteralUtil::CreateR1<bool>({true, true});
  EXPECT_FALSE(ones.IsAll(0));
  EXPECT_TRUE(ones.IsAll(1));
  EXPECT_FALSE(ones.IsAll(2));
  std::cout << "PRED_GUARD_LITERAL empty_matches_both=1 mixed_matches_neither=1"
               " ones_only_one=1 value_two_rejected=1\n";
}

}  // namespace
}  // namespace xla
