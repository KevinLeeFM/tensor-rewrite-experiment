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

#include <iostream>
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

class ScalarSelectReplay : public HloHardwareIndependentTestBase {
 protected:
  DebugOptions GetDebugOptionsForTest() const override {
    DebugOptions options =
        HloHardwareIndependentTestBase::GetDebugOptionsForTest();
    options.set_xla_cpu_enable_fast_math(false);
    options.set_xla_cpu_fast_math_honor_nans(true);
    options.set_xla_cpu_fast_math_honor_infs(true);
    options.set_xla_hlo_evaluator_use_fast_path(false);
    return options;
  }
};

TEST_F(ScalarSelectReplay, BranchSpecificScalarMovement) {
  for (bool enabled : {false, true}) {
    for (bool predicate_value : {false, true}) {
      SCOPED_TRACE(enabled);
      SCOPED_TRACE(predicate_value);
      const char* hlo = R"hlo(
HloModule scalar_select
ENTRY main {
  predicate = pred[1,4,1] parameter(0)
  input = f32[1,4,1] parameter(1)
  filter = f32[4,1,1] parameter(2)
  two = f32[] constant(2)
  three = f32[] constant(3)
  twos = f32[1,4,1] broadcast(two), dimensions={}
  threes = f32[1,4,1] broadcast(three), dimensions={}
  left = f32[1,4,1] multiply(input, twos)
  right = f32[1,4,1] multiply(input, threes)
  selected = f32[1,4,1] select(predicate, left, right)
  ROOT conv = f32[1,1,1] convolution(selected, filter), window={size=4}, dim_labels=b0f_0io->b0f
})hlo";
      ASSERT_OK_AND_ASSIGN(std::unique_ptr<HloModule> module,
                           ParseAndReturnVerifiedModule(hlo));
      const DebugOptions& debug = module->config().debug_options();
      ASSERT_FALSE(debug.xla_cpu_enable_fast_math());
      ASSERT_TRUE(debug.xla_cpu_fast_math_honor_nans());
      ASSERT_TRUE(debug.xla_cpu_fast_math_honor_infs());
      ASSERT_FALSE(debug.xla_hlo_evaluator_use_fast_path());
      Literal predicate = LiteralUtil::CreateR3<bool>(
          {{{predicate_value}, {predicate_value}, {predicate_value},
            {predicate_value}}});
      Literal input = LiteralUtil::CreateR3<float>(
          {{{1.0f}, {1.0f}, {1.0f}, {1.0f}}});
      Literal filter = LiteralUtil::CreateR3<float>(
          {{{1.0f}}, {{1.0f}}, {{1.0f}}, {{1.0f}}});
      std::vector<const Literal*> args{&predicate, &input, &filter};
      HloEvaluator before_evaluator;
      ASSERT_OK_AND_ASSIGN(Literal before,
                           before_evaluator.Evaluate(*module, args));
      const std::string before_hlo = module->ToString();
      AlgebraicSimplifierOptions options;
      options.set_enable_fast_math(false);
      options.set_enable_scalar_multiply_reduction(enabled);
      options.set_enable_conv_simplification(false);
      options.set_enable_conv_operand_swap(false);
      options.set_enable_folding_pad_into_convolution(false);
      options.set_enable_onednn_support(false);
      options.set_run_to_fixed_point(false);
      AlgebraicSimplifier simplifier(options);
      ASSERT_OK_AND_ASSIGN(bool changed, simplifier.Run(module.get()));
      EXPECT_EQ(changed, enabled);
      HloVerifier verifier(/*layout_sensitive=*/false,
                           /*allow_mixed_precision=*/true);
      ASSERT_OK(verifier.Run(module.get()).status());
      HloEvaluator after_evaluator;
      ASSERT_OK_AND_ASSIGN(Literal after,
                           after_evaluator.Evaluate(*module, args));
      const float expected_before = predicate_value ? 8.0f : 12.0f;
      const float expected_after = enabled ? 24.0f : expected_before;
      EXPECT_EQ(before.GetFirstElement<float>(), expected_before);
      EXPECT_EQ(after.GetFirstElement<float>(), expected_after);
      std::cout << "SCALAR_SELECT_RESULT enabled=" << enabled
                << " predicate=" << predicate_value
                << " before=" << before.GetFirstElement<float>()
                << " after=" << after.GetFirstElement<float>()
                << " rewritten_verified=1 fast_math=0\nORIGINAL_HLO\n"
                << before_hlo << "REWRITTEN_HLO\n"
                << module->ToString();
    }
  }
}

}  // namespace
}  // namespace xla
