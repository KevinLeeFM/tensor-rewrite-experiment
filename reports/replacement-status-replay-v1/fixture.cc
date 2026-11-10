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
class ReplacementStatusReplay : public HloHardwareIndependentTestBase {};

TEST_F(ReplacementStatusReplay, DefaultRelaySkipRetainsNewNodes) {
  std::cout << std::unitbuf;
  for (const std::string profile : {"plain","predecessor","successor"}) {
    for (const std::string mode : {"control","handler","pass","fixedpoint"}) {
      SCOPED_TRACE(profile);
      SCOPED_TRACE(mode);
      const std::string hlo =
          "HloModule replacement_status\nENTRY main {\n"
          "data = s32[] parameter(0)\nconstant = s32[] constant(2)\n"
          "marker = s32[] constant(1)\nROOT result = s32[] add(constant,data)\n}\n";
      ASSERT_OK_AND_ASSIGN(std::unique_ptr<HloModule> module,ParseAndReturnVerifiedModule(hlo));
      HloComputation* computation = module->entry_computation();
      HloInstruction* original_root = computation->root_instruction();
      HloInstruction* marker = nullptr;
      for (HloInstruction* node : computation->instructions())
        if (node->name() == "marker") marker = node;
      ASSERT_NE(marker,nullptr);
      if (profile == "predecessor") ASSERT_OK(marker->AddControlDependencyTo(original_root));
      if (profile == "successor") ASSERT_OK(original_root->AddControlDependencyTo(marker));
      const int64_t baseline_count = computation->instruction_count();
      Literal input = LiteralUtil::CreateR0<int32_t>(5);
      std::vector<const Literal*> args{&input};
      const int steps = mode == "fixedpoint" ? 1 : 3;
      for (int step = 1; step <= steps; ++step) {
        SCOPED_TRACE(step);
        HloInstruction* before_root = computation->root_instruction();
        const int64_t before_count = computation->instruction_count();
        bool changed = false;
        if (mode != "control") {
          AlgebraicSimplifierOptions options;options.set_run_to_fixed_point(mode == "fixedpoint");
          AlgebraicSimplifier simplifier(options);
          if (mode == "handler") {
            AlgebraicSimplifierVisitor visitor(options,&simplifier);
            ASSERT_OK(visitor.HandleAdd(before_root));changed = visitor.changed();
          } else {
            ASSERT_OK_AND_ASSIGN(changed,simplifier.Run(module.get()));
          }
        }
        const bool controlled = profile != "plain";
        const bool expected_changed = mode != "control" && (controlled || step == 1);
        const int64_t expected_delta = mode == "control" || !controlled ? 0 :
            mode == "fixedpoint" ? kAlgSimpRerunLimit : 1;
        const bool retained = computation->root_instruction() == before_root;
        EXPECT_EQ(changed,expected_changed);
        EXPECT_EQ(retained,mode == "control" || controlled || step != 1);
        EXPECT_EQ(computation->instruction_count()-before_count,expected_delta);
        HloVerifier verifier(false,true);
        ASSERT_OK(verifier.Run(module.get()).status());
        HloEvaluator evaluator;
        ASSERT_OK_AND_ASSIGN(Literal value,evaluator.Evaluate(*module,args));
        EXPECT_EQ(value.GetFirstElement<int32_t>(),7);
        std::cout << "REPLACEMENT_STATUS_RESULT profile=" << profile << " mode=" << mode
                  << " step=" << step << " changed=" << changed << " delta="
                  << computation->instruction_count()-before_count << " cumulative="
                  << computation->instruction_count()-baseline_count << " root_retained=" << retained
                  << " selected=" << value.GetFirstElement<int32_t>() << " verified=1 cap="
                  << kAlgSimpRerunLimit << "\n";
      }
      std::cout << "FINAL_HLO\n" << module->ToString();
    }
  }
}
}  // namespace
}  // namespace xla
