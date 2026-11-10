/* Copyright 2026 The OpenXLA Authors.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software is distributed
on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND. */
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
class ConcatenateStatusReplay : public HloHardwareIndependentTestBase {};
class InitializedConcatVisitor : public AlgebraicSimplifierVisitor {
 public:
  using AlgebraicSimplifierVisitor::AlgebraicSimplifierVisitor;
  bool Initialize(HloComputation* c,const AlgebraicSimplifierOptions& o,AlgebraicSimplifier* s) {
    const bool changed=Run(c,o,s);initializing_=false;return changed;
  }
  absl::Status HandleConcatenate(HloInstruction* node) override {
    return initializing_ ? absl::OkStatus() : AlgebraicSimplifierVisitor::HandleConcatenate(node);
  }
  absl::Status HandleSlice(HloInstruction* node) override {
    return initializing_ ? absl::OkStatus() : AlgebraicSimplifierVisitor::HandleSlice(node);
  }
 private:
  bool initializing_=true;
};
std::string Values(const Literal& value) {
  std::string result;
  for(int64_t i=0;i<value.shape().dimensions(0);++i) {
    if(i) result+=",";
    result+=std::to_string(value.Get<int32_t>({i}));
  }
  return result.empty() ? "empty" : result;
}
TEST_F(ConcatenateStatusReplay, AllocationBeforeCompatibilitySkip) {
  std::cout<<std::unitbuf;
  struct Case {const char* name;const char* operands;int size;int allocations;};
  const Case cases[]={{"filter_many","data,empty,other",4,1},
    {"filter_one","data,empty",2,0},{"filter_all","empty,empty",0,0},
    {"unary","data",2,0},{"adjacent","left,right",2,2}};
  for(const Case& test:cases)
  for(const bool layout:{false,true})
  for(const std::string profile:{"plain","predecessor","successor"})
  for(const std::string mode:{"control","handler","pass","fixedpoint"}) {
    if(profile=="plain" && mode=="fixedpoint") continue;
    SCOPED_TRACE(std::string(test.name)+profile+mode+std::to_string(layout));
    const std::string hlo="HloModule concat_status\nENTRY main {\n"
      "data = s32[2] parameter(0)\nempty = s32[0] parameter(1)\n"
      "other = s32[2] parameter(2)\nmarker = s32[] constant(1)\n"
      "left = s32[1] slice(data), slice={[0:1]}\n"
      "right = s32[1] slice(data), slice={[1:2]}\nROOT result = s32["+
      std::to_string(test.size)+"] concatenate("+test.operands+"), dimensions={0}\n}";
    ASSERT_OK_AND_ASSIGN(std::unique_ptr<HloModule> module,ParseAndReturnVerifiedModule(hlo));
    auto* computation=module->entry_computation();auto* original_root=computation->root_instruction();
    HloInstruction* marker=nullptr;
    for(auto* node:computation->instructions()) if(node->name()=="marker") marker=node;
    ASSERT_NE(marker,nullptr);
    if(profile=="predecessor") ASSERT_OK(marker->AddControlDependencyTo(original_root));
    if(profile=="successor") ASSERT_OK(original_root->AddControlDependencyTo(marker));
    HloVerifier input_verifier(false,true);ASSERT_OK(input_verifier.Run(module.get()).status());
    Literal data=LiteralUtil::CreateR1<int32_t>({3,7});
    Literal empty(ShapeUtil::MakeShape(S32,{0}));
    Literal other=LiteralUtil::CreateR1<int32_t>({11,13});
    std::vector<const Literal*> args{&data,&empty,&other};
    HloEvaluator before_evaluator;before_evaluator.set_use_fast_path(false);
    ASSERT_OK_AND_ASSIGN(Literal before,before_evaluator.Evaluate(*module,args));
    const bool controlled=profile!="plain";
    const int steps=controlled && mode=="handler" ? 3 : 1;
    for(int step=1;step<=steps;++step) {
      const std::string original=module->ToString();
      const int64_t count=computation->instruction_count();bool changed=false;
      if(mode!="control") {
        AlgebraicSimplifierOptions options;options.set_is_layout_sensitive(layout);
        options.set_run_to_fixed_point(mode=="fixedpoint");
        AlgebraicSimplifier simplifier(options);
        if(mode=="handler") {
          InitializedConcatVisitor visitor(options,&simplifier);
          ASSERT_FALSE(visitor.Initialize(computation,options,&simplifier));
          ASSERT_EQ(original,module->ToString());
          ASSERT_OK(visitor.HandleConcatenate(original_root));changed=visitor.changed();
        } else {ASSERT_OK_AND_ASSIGN(changed,simplifier.Run(module.get()));}
      }
      const bool active=mode!="control";
      const int delta=active && (!layout || std::string(test.name)!="adjacent") ?
        (controlled ? test.allocations : test.allocations-1) : 0;
      const bool replaced=active && !controlled && (!layout || std::string(test.name)!="adjacent");
      EXPECT_EQ(changed,replaced);
      EXPECT_EQ(computation->root_instruction()==original_root,!replaced);
      EXPECT_EQ(computation->instruction_count()-count,delta);
      HloVerifier verifier(false,true);ASSERT_OK(verifier.Run(module.get()).status());
      HloEvaluator evaluator;evaluator.set_use_fast_path(false);
      ASSERT_OK_AND_ASSIGN(Literal after,evaluator.Evaluate(*module,args));
      EXPECT_EQ(Values(before),Values(after));
      std::cout<<"CONCAT_STATUS_RESULT case="<<test.name<<" layout="<<layout<<" profile="<<profile
        <<" mode="<<mode<<" step="<<step<<" changed="<<changed<<" delta="
        <<computation->instruction_count()-count<<" root_retained="
        <<(computation->root_instruction()==original_root)<<" before="<<Values(before)
        <<" after="<<Values(after)<<" verified=1\nORIGINAL_HLO\n"<<original
        <<"\nREWRITTEN_HLO\n"<<module->ToString()<<"\n";
    }
  }
}
}  // namespace
}  // namespace xla
