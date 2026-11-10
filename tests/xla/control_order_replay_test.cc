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
#include <iostream>
#include <map>
#include <memory>
#include <set>
#include <string>
#include <vector>

#include "absl/container/flat_hash_map.h"
#include "gtest/gtest.h"
#include "xla/hlo/evaluator/hlo_evaluator.h"
#include "xla/hlo/ir/hlo_module.h"
#include "xla/hlo/ir/hlo_schedule.h"
#include "xla/hlo/testlib/hlo_hardware_independent_test_base.h"
#include "xla/hlo/transforms/simplifiers/algebraic_simplifier.h"
#include "xla/literal.h"
#include "xla/literal_util.h"
#include "xla/service/hlo_verifier.h"
#include "xla/status_macros.h"

namespace xla {
namespace {
class ControlOrderReplay : public HloHardwareIndependentTestBase {};

bool Reaches(const HloInstruction* start, const HloInstruction* target) {
  std::vector<const HloInstruction*> pending{start};
  std::set<const HloInstruction*> visited;
  while (!pending.empty()) {
    const HloInstruction* node = pending.back();pending.pop_back();
    if (!visited.insert(node).second) continue;
    if (node == target) return true;
    for (const HloInstruction* user : node->users()) pending.push_back(user);
    for (const HloInstruction* next : node->control_successors()) pending.push_back(next);
  }
  return false;
}

std::vector<HloInstruction*> Order(HloModule* module, bool reverse) {
  HloComputation* computation = module->entry_computation();
  std::vector<HloInstruction*> order;
  for (HloInstruction* node : computation->instructions()) order.push_back(node);
  const auto priority = [&](HloInstruction* node) {
    if (node == computation->root_instruction()) return 4;
    if (node->opcode() == HloOpcode::kConstant) return 0;
    if (node->opcode() == HloOpcode::kCustomCall) {
      if (node->custom_call_target() == "A") return reverse ? 2 : 1;
      return reverse ? 1 : 3;
    }
    return reverse ? 3 : 2;
  };
  std::stable_sort(order.begin(),order.end(),[&](auto* left,auto* right) {
    return priority(left) < priority(right);
  });
  return order;
}

absl::Status VerifyOrder(HloModule* module, const std::vector<HloInstruction*>& order) {
  HloSchedule schedule(module);
  schedule.set_sequence(module->entry_computation(),order);
  return schedule.Verify();
}

struct ScheduledResult {
  Literal value;
  std::string trace;
};

absl::StatusOr<ScheduledResult> RunOrder(HloModule* module,
                                      const std::vector<HloInstruction*>& order) {
  TF_RETURN_IF_ERROR(VerifyOrder(module,order));
  std::map<const HloInstruction*,Literal> values;
  std::string trace;
  HloEvaluator evaluator;
  evaluator.set_custom_call_handler([&](const HloInstruction* call,
      absl::Span<const Literal*> operands) -> absl::StatusOr<Literal> {
    if (!trace.empty()) trace += ",";
    trace += call->custom_call_target();
    return LiteralUtil::CreateR0<bool>(call->custom_call_target() == "A");
  });
  for (HloInstruction* node : order) {
    absl::flat_hash_map<const HloInstruction*,const LiteralBase*> substitutions;
    for (const auto& item : values) substitutions[item.first] = &item.second;
    TF_ASSIGN_OR_RETURN(Literal value,evaluator.Evaluate(node,{},false,substitutions));
    values.emplace(node,std::move(value));
  }
  return ScheduledResult{values.at(module->entry_computation()->root_instruction()).Clone(),trace};
}

TEST_F(ControlOrderReplay, DiscardedEffectOperandAndControlSuccessor) {
  struct Case {const char* name;bool identity;bool predecessor;bool successor;};
  const Case cases[] = {
      {"annihilator_successor",false,false,true},
      {"annihilator_predecessor",false,true,true},
      {"identity_successor",true,false,true},
      {"annihilator_unordered",false,false,false},
  };
  for (const Case& test : cases) {
    for (int mode : {0,1,2}) {
      SCOPED_TRACE(test.name);
      SCOPED_TRACE(mode);
      const std::string hlo =
          "HloModule control_order\nENTRY main {\n"
          "effect_b = pred[] custom-call(), custom_call_target=\"B\", custom_call_has_side_effect=true\n"
          "effect_a = pred[] custom-call(), custom_call_target=\"A\", custom_call_has_side_effect=true\n"
          "flag = pred[] constant(" + std::string(test.identity ? "true" : "false") + ")\n"
          "combined = pred[] and(effect_a,flag)\n"
          "ROOT result = (pred[],pred[]) tuple(combined,effect_b)\n}\n";
      ASSERT_OK_AND_ASSIGN(std::unique_ptr<HloModule> module,ParseAndReturnVerifiedModule(hlo));
      HloInstruction* root = module->entry_computation()->root_instruction();
      HloInstruction* combined = root->mutable_operand(0);
      HloInstruction* effect_a = combined->mutable_operand(0);
      HloInstruction* effect_b = root->mutable_operand(1);
      ASSERT_TRUE(effect_a->HasSideEffect());ASSERT_TRUE(effect_b->HasSideEffect());
      if (test.predecessor) ASSERT_OK(effect_a->AddControlDependencyTo(combined));
      if (test.successor) ASSERT_OK(combined->AddControlDependencyTo(effect_b));
      HloVerifier verifier_before(false,true);
      ASSERT_OK(verifier_before.Run(module.get()).status());
      const std::string original = module->ToString();
      const bool before_path = Reaches(effect_a,effect_b);
      const bool before_reverse = VerifyOrder(module.get(),Order(module.get(),true)).ok();
      EXPECT_EQ(before_path,test.successor);
      EXPECT_EQ(before_reverse,!test.successor);
      ASSERT_OK_AND_ASSIGN(ScheduledResult before,RunOrder(module.get(),Order(module.get(),false)));
      EXPECT_EQ(before.trace,"A,B");
      bool changed = false;
      if (mode != 0) {
        AlgebraicSimplifierOptions options;options.set_run_to_fixed_point(false);
        AlgebraicSimplifier simplifier(options);
        if (mode == 1) {
          AlgebraicSimplifierVisitor visitor(options,&simplifier);
          ASSERT_OK(visitor.HandleAnd(combined));changed = visitor.changed();
        } else {
          ASSERT_OK_AND_ASSIGN(changed,simplifier.Run(module.get()));
        }
      }
      EXPECT_EQ(changed,mode != 0 && !test.predecessor);
      bool retained_a = false;bool retained_b = false;
      for (const HloInstruction* node : module->entry_computation()->instructions()) {
        retained_a |= node == effect_a;retained_b |= node == effect_b;
      }
      ASSERT_TRUE(retained_a);ASSERT_TRUE(retained_b);
      HloVerifier verifier_after(false,true);
      ASSERT_OK(verifier_after.Run(module.get()).status());
      const bool after_path = Reaches(effect_a,effect_b);
      const bool expected_path = test.successor && !(changed && !test.identity);
      EXPECT_EQ(after_path,expected_path);
      auto reverse_order = Order(module.get(),true);
      const bool after_reverse = VerifyOrder(module.get(),reverse_order).ok();
      EXPECT_EQ(after_reverse,!expected_path);
      ASSERT_OK_AND_ASSIGN(ScheduledResult after,RunOrder(module.get(),Order(module.get(),false)));
      EXPECT_EQ(before.value.ToString(),after.value.ToString());EXPECT_EQ(after.trace,"A,B");
      std::string reverse_trace = "invalid";
      if (after_reverse) {
        ASSERT_OK_AND_ASSIGN(ScheduledResult reversed,RunOrder(module.get(),reverse_order));
        EXPECT_EQ(reversed.value.ToString(),after.value.ToString());
        reverse_trace = reversed.trace;EXPECT_EQ(reverse_trace,"B,A");
      }
      std::cout << "CONTROL_ORDER_RESULT case=" << test.name
                << " mode=" << (mode == 0 ? "control" : mode == 1 ? "handler" : "pass")
                << " changed=" << changed << " reachable_before=" << before_path
                << " reachable_after=" << after_path << " reverse_before=" << before_reverse
                << " reverse_after=" << after_reverse << " forward_trace=" << after.trace
                << " reverse_trace=" << reverse_trace << " actors_retained=1 verified=1\n"
                << "ORIGINAL_HLO\n" << original << "REWRITTEN_HLO\n" << module->ToString();
    }
  }
}
}  // namespace
}  // namespace xla
