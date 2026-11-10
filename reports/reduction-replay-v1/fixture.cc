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

namespace xla {
namespace {
class ReductionReplay : public HloHardwareIndependentTestBase {};

TEST_F(ReductionReplay, InitializerLawAndStaticFibers) {
  struct Case {
    const char* name;
    const char* input_shape;
    const char* output_shape;
    const char* dimensions;
    bool initial;
    bool expected_changed;
    HloOpcode rewritten_opcode;
    const char* before;
    const char* after;
  };
  const Case cases[] = {
      {"unit_axes", "pred[1,3,1]{2,1,0}", "pred[3]{0}", "0,2", true, true,
       HloOpcode::kReshape, "0,1,0", "0,1,0"},
      {"no_axes", "pred[2,3]{1,0}", "pred[2,3]{1,0}", "", true, true,
       HloOpcode::kReshape, "1,0,1,0,1,0", "1,0,1,0,1,0"},
      {"empty_reduced", "pred[2,0,3]{2,1,0}", "pred[2,3]{1,0}", "1", true, true,
       HloOpcode::kBroadcast, "1,1,1,1,1,1", "1,1,1,1,1,1"},
      {"empty_kept", "pred[0,2]{1,0}", "pred[0]{0}", "1", true, true,
       HloOpcode::kBroadcast, "empty", "empty"},
      {"scalar", "pred[]", "pred[]", "", true, true,
       HloOpcode::kReshape, "0", "0"},
      {"nontrivial_axes", "pred[2,3,2]{2,1,0}", "pred[3]{0}", "0,2", true, false,
       HloOpcode::kReduce, "0,0,1", "0,0,1"},
      {"nonidentity_control", "pred[1,3,1]{2,1,0}", "pred[3]{0}", "0,2", false, true,
       HloOpcode::kReshape, "0,0,0", "0,1,0"},
  };
  for (const Case& test : cases) {
    for (int mode : {0, 1, 2}) {
      SCOPED_TRACE(test.name);
      SCOPED_TRACE(mode);
      const std::string hlo =
          "HloModule reduction_replay\ncombine {\nleft = pred[] parameter(0)\n"
          "right = pred[] parameter(1)\nROOT combined = pred[] and(left,right)\n}\n"
          "ENTRY main {\ndata = " + std::string(test.input_shape) +
          " parameter(0)\ninitial = pred[] constant(" + (test.initial ? "true" : "false") +
          ")\nROOT result = " + test.output_shape + " reduce(data,initial), dimensions={" +
          test.dimensions + "}, to_apply=combine\n}\n";
      ASSERT_OK_AND_ASSIGN(std::unique_ptr<HloModule> module, ParseAndReturnVerifiedModule(hlo));
      const Shape& shape = module->entry_computation()->parameter_instruction(0)->shape();
      const std::string name = test.name;
      Literal data = name == "scalar" ? LiteralUtil::CreateR0<bool>(false)
          : name == "no_axes" ? LiteralUtil::CreateR2<bool>({{true,false,true},{false,true,false}})
          : name == "unit_axes" || name == "nonidentity_control"
              ? LiteralUtil::CreateR3<bool>({{{false},{true},{false}}})
          : name == "nontrivial_axes"
              ? LiteralUtil::CreateR3<bool>({{{true,true},{true,false},{true,true}},
                                            {{true,false},{true,true},{true,true}}})
              : Literal::CreateFromShape(shape);
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
          ASSERT_OK(visitor.HandleReduce(module->entry_computation()->root_instruction()));
          changed = visitor.changed();
        } else {
          ASSERT_OK_AND_ASSIGN(changed, simplifier.Run(module.get()));
        }
        EXPECT_EQ(changed, test.expected_changed);
        EXPECT_EQ(module->entry_computation()->root_instruction()->opcode(), test.rewritten_opcode);
      } else {
        EXPECT_EQ(module->ToString(), original);
      }
      HloVerifier verifier(/*layout_sensitive=*/false, /*allow_mixed_precision=*/true);
      ASSERT_OK(verifier.Run(module.get()).status());
      HloEvaluator after_evaluator;
      ASSERT_OK_AND_ASSIGN(Literal after, after_evaluator.Evaluate(*module, args));
      const auto labels = [](const Literal& value) {
        std::string result;
        const auto append = [&result](bool bit) {
          result += (result.empty() ? "" : ",");
          result += bit ? "1" : "0";
        };
        const auto dimensions = value.shape().dimensions();
        if (dimensions.empty()) append(value.Get<bool>({}));
        else if (dimensions.size() == 1) {
          for (int i = 0; i < dimensions[0]; ++i) append(value.Get<bool>({i}));
        } else {
          for (int i = 0; i < dimensions[0]; ++i)
            for (int j = 0; j < dimensions[1]; ++j) append(value.Get<bool>({i,j}));
        }
        return result.empty() ? std::string("empty") : result;
      };
      const std::string before_labels = labels(before);
      const std::string after_labels = labels(after);
      EXPECT_EQ(before_labels, test.before);
      EXPECT_EQ(after_labels, mode == 0 ? test.before : test.after);
      std::cout << "REDUCTION_RESULT case=" << name
                << " mode=" << (mode == 0 ? "control" : mode == 1 ? "handler" : "pass")
                << " changed=" << changed << " identity_law=" << test.initial
                << " before=" << before_labels << " after=" << after_labels
                << " rewritten_verified=1\nORIGINAL_HLO\n" << original
                << "REWRITTEN_HLO\n" << module->ToString();
    }
  }
}
}  // namespace
}  // namespace xla
