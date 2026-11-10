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
#include "xla/hlo/ir/hlo_module.h"
#include "xla/hlo/testlib/hlo_hardware_independent_test_base.h"
#include "xla/hlo/transforms/simplifiers/algebraic_simplifier.h"
#include "xla/literal.h"
#include "xla/literal_util.h"
#include "xla/service/hlo_verifier.h"

namespace xla {
namespace {
class ReshapeReplay : public HloHardwareIndependentTestBase {};

TEST_F(ReshapeReplay, LogicalOrderAcrossLayoutsAndRanks) {
  struct Case {
    const char* name;
    const char* body;
    int elements;
    int first;
    HloOpcode rewritten_opcode;
  };
  const Case cases[] = {
      {"compose_default", "data = s32[2,3]{1,0} parameter(0)\n"
       "middle = s32[3,2]{1,0} reshape(data)\nROOT result = s32[6]{0} reshape(middle)\n", 6, 0, HloOpcode::kReshape},
      {"compose_column", "data = s32[2,3]{0,1} parameter(0)\n"
       "middle = s32[3,2]{0,1} reshape(data)\nROOT result = s32[6]{0} reshape(middle)\n", 6, 0, HloOpcode::kReshape},
      {"identity", "data = s32[2,3]{1,0} parameter(0)\n"
       "ROOT result = s32[2,3]{1,0} reshape(data)\n", 6, 0, HloOpcode::kParameter},
      {"scalar_chain", "data = s32[1,1]{1,0} parameter(0)\n"
       "middle = s32[] reshape(data)\nROOT result = s32[1]{0} reshape(middle)\n", 1, 42, HloOpcode::kReshape},
      {"empty", "data = s32[2,0,3]{2,1,0} parameter(0)\n"
       "ROOT result = s32[0,6]{1,0} reshape(data)\n", 0, 0, HloOpcode::kConstant},
  };
  for (const Case& test : cases) {
    for (int mode : {0, 1, 2}) {
      SCOPED_TRACE(test.name);
      SCOPED_TRACE(mode);
      const std::string hlo = "HloModule reshape_replay\nENTRY main {\n" +
          std::string(test.body) + "}\n";
      ASSERT_OK_AND_ASSIGN(std::unique_ptr<HloModule> module, ParseAndReturnVerifiedModule(hlo));
      const Shape& input_shape = module->entry_computation()->parameter_instruction(0)->shape();
      Literal data = test.elements == 0 ? Literal::CreateFromShape(input_shape)
          : test.elements == 1 ? LiteralUtil::CreateR2<int32_t>({{42}})
          : LiteralUtil::CreateR2<int32_t>({{0, 1, 2}, {3, 4, 5}});
      data = data.Relayout(input_shape);
      std::vector<const Literal*> args{&data};
      HloEvaluator before_evaluator;
      ASSERT_OK_AND_ASSIGN(Literal before, before_evaluator.Evaluate(*module, args));
      const std::string original = module->ToString();
      bool changed = false;
      if (mode != 0) {
        AlgebraicSimplifierOptions options;
        options.set_is_layout_sensitive(true);
        options.set_run_to_fixed_point(false);
        AlgebraicSimplifier simplifier(options);
        if (mode == 1) {
          AlgebraicSimplifierVisitor visitor(options, &simplifier);
          ASSERT_OK(visitor.HandleReshape(module->entry_computation()->root_instruction()));
          changed = visitor.changed();
        } else {
          ASSERT_OK_AND_ASSIGN(changed, simplifier.Run(module.get()));
        }
        ASSERT_TRUE(changed);
        const HloInstruction* root = module->entry_computation()->root_instruction();
        const bool full_bitcast = mode == 2 &&
            (std::string(test.name) == "compose_default" || std::string(test.name) == "scalar_chain");
        EXPECT_EQ(root->opcode(), full_bitcast ? HloOpcode::kBitcast : test.rewritten_opcode);
        if (root->opcode() == HloOpcode::kReshape) {
          EXPECT_EQ(root->operand(0)->opcode(), HloOpcode::kParameter);
        }
      } else {
        EXPECT_EQ(module->ToString(), original);
      }
      HloVerifier verifier(/*layout_sensitive=*/false, /*allow_mixed_precision=*/true);
      ASSERT_OK(verifier.Run(module.get()).status());
      HloEvaluator after_evaluator;
      ASSERT_OK_AND_ASSIGN(Literal after, after_evaluator.Evaluate(*module, args));
      ASSERT_OK_AND_ASSIGN(Literal before_flat, before.Reshape({test.elements}));
      ASSERT_OK_AND_ASSIGN(Literal after_flat, after.Reshape({test.elements}));
      std::string values;
      for (int i = 0; i < test.elements; ++i) {
        const int expected = test.first + i;
        EXPECT_EQ(before_flat.Get<int32_t>({i}), expected);
        EXPECT_EQ(after_flat.Get<int32_t>({i}), expected);
        values += (i ? "," : "") + std::to_string(after_flat.Get<int32_t>({i}));
      }
      std::cout << "RESHAPE_RESULT case=" << test.name << " mode=" << (mode == 0 ? "control" : mode == 1 ? "handler" : "pass")
                << " changed=" << changed << " elements=" << test.elements
                << " values=" << (values.empty() ? "empty" : values)
                << " rewritten_verified=1\nORIGINAL_HLO\n" << original
                << "REWRITTEN_HLO\n" << module->ToString();
    }
  }
}
}  // namespace
}  // namespace xla
