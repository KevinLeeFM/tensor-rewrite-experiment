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
class BooleanControlFamilyReplay : public HloHardwareIndependentTestBase {};

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

// Construct the desired actor order while satisfying every other prerequisite.
// If that actor order is impossible, force its first actor; native Verify then
// rejects the resulting candidate. Pure instructions may precede either actor.
std::vector<HloInstruction*> Order(HloModule* module, bool reverse) {
  HloComputation* computation = module->entry_computation();
  std::vector<HloInstruction*> pending;
  std::vector<HloInstruction*> order;
  std::set<const HloInstruction*> emitted;
  HloInstruction* first_actor = nullptr;
  HloInstruction* second_actor = nullptr;
  for (HloInstruction* node : computation->instructions()) {
    pending.push_back(node);
    if (node->opcode() != HloOpcode::kCustomCall) continue;
    if (node->custom_call_target() == (reverse ? "B" : "A")) first_actor = node;
    if (node->custom_call_target() == (reverse ? "A" : "B")) second_actor = node;
  }
  while (!pending.empty()) {
    auto ready = [&](HloInstruction* node) {
      if (node == second_actor && !emitted.contains(first_actor)) return false;
      for (const HloInstruction* operand : node->operands())
        if (!emitted.contains(operand)) return false;
      for (const HloInstruction* pred : node->control_predecessors())
        if (!emitted.contains(pred)) return false;
      return true;
    };
    auto next = std::find_if(pending.begin(),pending.end(),ready);
    if (next == pending.end()) next = std::find(pending.begin(),pending.end(),first_actor);
    CHECK(next != pending.end());
    HloInstruction* node = *next;
    order.push_back(node);emitted.insert(node);pending.erase(next);
  }
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
    if (call->custom_call_target() != "Value") {
      if (!trace.empty()) trace += ",";
      trace += call->custom_call_target();
    }
    return LiteralUtil::CreateR0<bool>(call->custom_call_target() != "B");
  });
  for (HloInstruction* node : order) {
    absl::flat_hash_map<const HloInstruction*,const LiteralBase*> substitutions;
    for (const auto& item : values) substitutions[item.first] = &item.second;
    TF_ASSIGN_OR_RETURN(Literal value,evaluator.Evaluate(node,{},false,substitutions));
    values.emplace(node,std::move(value));
  }
  return ScheduledResult{values.at(module->entry_computation()->root_instruction()).Clone(),trace};
}

TEST_F(BooleanControlFamilyReplay, DiscardedOperandPrerequisites) {
  struct Rule {
    const char* name;
    HloOpcode opcode;
    bool flag;
    bool flag_lhs;
    bool forwards_flag;
  };
  const Rule rules[] = {
      {"and_rhs_true",HloOpcode::kAnd,true,false,false},
      {"and_lhs_true",HloOpcode::kAnd,true,true,false},
      {"and_rhs_false",HloOpcode::kAnd,false,false,true},
      {"and_lhs_false",HloOpcode::kAnd,false,true,true},
      {"or_rhs_true",HloOpcode::kOr,true,false,true},
      {"or_lhs_true",HloOpcode::kOr,true,true,true},
      {"or_rhs_false",HloOpcode::kOr,false,false,false},
      {"or_lhs_false",HloOpcode::kOr,false,true,false},
      {"xor_rhs_false",HloOpcode::kXor,false,false,false},
      {"xor_lhs_false",HloOpcode::kXor,false,true,false},
      {"xor_self",HloOpcode::kXor,false,false,false},
      {"not_not",HloOpcode::kNot,false,false,false},
  };
  for (const Rule& rule : rules) {
    for (const std::string profile : {"discarded_control","old_control","no_successor"}) {
      for (const std::string mode : {"control","handler","pass","repair"}) {
        SCOPED_TRACE(rule.name);
        SCOPED_TRACE(profile);
        SCOPED_TRACE(mode);
        const bool self = std::string(rule.name) == "xor_self";
        const bool twice = rule.opcode == HloOpcode::kNot;
        const bool successor = profile != "no_successor";
        std::string expression;
        if (twice) {
          expression = "inner = pred[] not(value)\ncombined = pred[] not(inner)\n";
        } else if (self) {
          expression = "combined = pred[] xor(value,value)\n";
        } else {
          expression = "flag = pred[] constant(" + std::string(rule.flag ? "true" : "false") + ")\n";
          expression += std::string("combined = pred[] ") + std::string(HloOpcodeString(rule.opcode)) +
              (rule.flag_lhs ? "(flag,value)\n" : "(value,flag)\n");
        }
        const std::string hlo =
            "HloModule boolean_control_family\nENTRY main {\n"
            "effect_b = pred[] custom-call(), custom_call_target=\"B\", custom_call_has_side_effect=true\n"
            "effect_a = pred[] custom-call(), custom_call_target=\"A\", custom_call_has_side_effect=true\n"
            "value = pred[] custom-call(), custom_call_target=\"Value\"\n" + expression +
            "ROOT result = (pred[],pred[]) tuple(combined,effect_b)\n}\n";
        ASSERT_OK_AND_ASSIGN(std::unique_ptr<HloModule> module,ParseAndReturnVerifiedModule(hlo));
        HloComputation* computation = module->entry_computation();
        HloInstruction* root = computation->root_instruction();
        HloInstruction* combined = root->mutable_operand(0);
        HloInstruction* effect_b = root->mutable_operand(1);
        HloInstruction* effect_a = nullptr;
        HloInstruction* value = nullptr;
        for (HloInstruction* node : computation->instructions()) {
          if (node->opcode() != HloOpcode::kCustomCall) continue;
          if (node->custom_call_target() == "A") effect_a = node;
          if (node->custom_call_target() == "Value") value = node;
        }
        ASSERT_NE(effect_a,nullptr);ASSERT_NE(value,nullptr);
        HloInstruction* discarded = nullptr;
        if (twice) discarded = combined->mutable_operand(0);
        else if (self || rule.forwards_flag) discarded = value;
        else discarded = combined->mutable_operand(rule.flag_lhs ? 0 : 1);
        ASSERT_OK(effect_a->AddControlDependencyTo(profile == "old_control" ? combined : discarded));
        if (successor) ASSERT_OK(combined->AddControlDependencyTo(effect_b));
        HloVerifier verifier_before(false,true);
        ASSERT_OK(verifier_before.Run(module.get()).status());
        const std::string original = module->ToString();
        ASSERT_EQ(Reaches(effect_a,effect_b),successor);
        ASSERT_EQ(VerifyOrder(module.get(),Order(module.get(),true)).ok(),!successor);
        ASSERT_OK_AND_ASSIGN(ScheduledResult before,RunOrder(module.get(),Order(module.get(),false)));
        EXPECT_EQ(before.trace,"A,B");
        bool changed = false;
        if (mode != "control") {
          AlgebraicSimplifierOptions options;options.set_run_to_fixed_point(false);
          AlgebraicSimplifier simplifier(options);
          if (mode == "handler") {
            AlgebraicSimplifierVisitor visitor(options,&simplifier);
            switch (rule.opcode) {
              case HloOpcode::kAnd: ASSERT_OK(visitor.HandleAnd(combined));break;
              case HloOpcode::kOr: ASSERT_OK(visitor.HandleOr(combined));break;
              case HloOpcode::kXor: ASSERT_OK(visitor.HandleXor(combined));break;
              case HloOpcode::kNot: ASSERT_OK(visitor.HandleNot(combined));break;
              default: FAIL() << "unsupported rule";
            }
            changed = visitor.changed();
          } else {
            ASSERT_OK_AND_ASSIGN(changed,simplifier.Run(module.get()));
          }
        }
        const bool expected_change = mode != "control" && (profile != "old_control" || self);
        EXPECT_EQ(changed,expected_change);
        bool repaired = false;
        if (mode == "repair" && successor && !Reaches(effect_a,effect_b)) {
          ASSERT_OK(effect_a->AddControlDependencyTo(effect_b));repaired = true;
        }
        const bool after_path = successor && (!changed || profile == "old_control" || mode == "repair");
        EXPECT_EQ(Reaches(effect_a,effect_b),after_path);
        bool retained_a = false;bool retained_b = false;
        for (HloInstruction* node : computation->instructions()) {
          retained_a |= node == effect_a;retained_b |= node == effect_b;
        }
        ASSERT_TRUE(retained_a);ASSERT_TRUE(retained_b);
        HloVerifier verifier_after(false,true);
        ASSERT_OK(verifier_after.Run(module.get()).status());
        ASSERT_OK_AND_ASSIGN(ScheduledResult after,RunOrder(module.get(),Order(module.get(),false)));
        EXPECT_EQ(after.trace,"A,B");EXPECT_EQ(before.value.ToString(),after.value.ToString());
        const bool reverse_after = VerifyOrder(module.get(),Order(module.get(),true)).ok();
        EXPECT_EQ(reverse_after,!after_path);
        std::string reverse_trace = "invalid";
        if (reverse_after) {
          ASSERT_OK_AND_ASSIGN(ScheduledResult reverse,RunOrder(module.get(),Order(module.get(),true)));
          EXPECT_EQ(reverse.value.ToString(),after.value.ToString());
          reverse_trace = reverse.trace;EXPECT_EQ(reverse_trace,"B,A");
        }
        std::cout << "BOOLEAN_CONTROL_RESULT rule=" << rule.name << " profile=" << profile
                  << " mode=" << mode << " changed=" << changed << " reachable_before=" << successor
                  << " reachable_after=" << after_path << " reverse_before=" << !successor
                  << " reverse_after=" << reverse_after << " repaired=" << repaired
                  << " forward_trace=" << after.trace << " reverse_trace=" << reverse_trace
                  << " actors_retained=1 verified=1\n"
                  << "ORIGINAL_HLO\n" << original << "REWRITTEN_HLO\n" << module->ToString();
      }
    }
  }
}
}  // namespace
}  // namespace xla
