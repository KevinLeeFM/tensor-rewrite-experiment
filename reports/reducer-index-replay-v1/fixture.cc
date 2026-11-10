/* Copyright 2026 The OpenXLA Authors.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software is distributed
on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND. */
#include <algorithm>
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
class ReducerIndexReplay : public HloHardwareIndependentTestBase {};
class InitializedVisitor : public AlgebraicSimplifierVisitor {
 public:
  using AlgebraicSimplifierVisitor::AlgebraicSimplifierVisitor;
  bool Initialize(HloComputation* c,const AlgebraicSimplifierOptions& options,
                  AlgebraicSimplifier* simplifier) {
    const bool changed=Run(c,options,simplifier);initializing_=false;return changed;
  }
  absl::Status HandleAdd(HloInstruction* add) override {
    return initializing_ ? absl::OkStatus() : AlgebraicSimplifierVisitor::HandleAdd(add);
  }
  absl::Status HandleGather(HloInstruction* gather) override {
    return initializing_ ? absl::OkStatus() : AlgebraicSimplifierVisitor::HandleGather(gather);
  }
 private:
  bool initializing_=true;
};
std::string Values(const Literal& value) {
  std::string result;
  for (int i=0;i<value.shape().dimensions(0);++i) {
    if(i) result+=",";
    result+=std::to_string(value.Get<int32_t>({i}));
  }
  return result;
}
TEST_F(ReducerIndexReplay, ScatterParameterRoles) {
  for (const std::string roles : {"00","11","01","10"})
  for (const std::string side : {"rhs","lhs"})
  for (const bool layout : {false,true})
  for (const std::string mode : {"control","handler","pass"}) {
    const std::string first=roles[0]=='0' ? "old" : "update";
    const std::string second=roles[1]=='0' ? "old" : "update";
    const std::string hlo="HloModule scatter_roles\nreducer {\nold = s32[] parameter(0)\n"
        "update = s32[] parameter(1)\nROOT result = s32[] add("+first+","+second+")\n}\n"
        "ENTRY main {\na = s32[2] parameter(0)\nb = s32[2] parameter(1)\n"
        "index = s32[1,1] parameter(2)\nupdates = s32[1] parameter(3)\n"
        "sc = s32[2] scatter(b,index,updates), update_window_dims={}, inserted_window_dims={0}, "
        "scatter_dims_to_operand_dims={0}, index_vector_dim=1, to_apply=reducer, "
        "indices_are_sorted=true, unique_indices=true\nROOT result = s32[2] add("+
        (side=="rhs" ? "a,sc" : "sc,a")+")\n}";
    ASSERT_OK_AND_ASSIGN(std::unique_ptr<HloModule> module,ParseAndReturnVerifiedModule(hlo));
    Literal a=LiteralUtil::CreateR1<int32_t>({1,1}),b=LiteralUtil::CreateR1<int32_t>({3,3});
    Literal index=LiteralUtil::CreateR2<int32_t>({{0}}),update=LiteralUtil::CreateR1<int32_t>({5});
    std::vector<const Literal*> args{&a,&b,&index,&update};
    HloEvaluator evaluator;evaluator.set_use_fast_path(false);
    ASSERT_OK_AND_ASSIGN(Literal before,evaluator.Evaluate(*module,args));
    const std::string original=module->ToString();bool changed=false;
    if(mode!="control") {
      AlgebraicSimplifierOptions options;options.set_is_layout_sensitive(layout);
      options.set_run_to_fixed_point(false);options.set_enable_fast_math(false);
      AlgebraicSimplifier simplifier(options);
      if(mode=="handler") {
        InitializedVisitor visitor(options,&simplifier);
        ASSERT_FALSE(visitor.Initialize(module->entry_computation(),options,&simplifier));
        ASSERT_EQ(original,module->ToString());
        ASSERT_OK(visitor.HandleAdd(module->entry_computation()->root_instruction()));
        changed=visitor.changed();
      } else {ASSERT_OK_AND_ASSIGN(changed,simplifier.Run(module.get()));}
    }
    HloVerifier verifier(false,true);ASSERT_OK(verifier.Run(module.get()).status());
    HloEvaluator after_evaluator;after_evaluator.set_use_fast_path(false);
    ASSERT_OK_AND_ASSIGN(Literal after,after_evaluator.Evaluate(*module,args));
    const bool active=mode!="control" && !layout;
    EXPECT_EQ(changed,active);
    const int expected_before=roles=="00" ? 7 : roles=="11" ? 11 : 9;
    const int expected_after=active ? (roles=="00" ? 8 : roles=="11" ? 10 : 9) : expected_before;
    EXPECT_EQ(before.Get<int32_t>({0}),expected_before);EXPECT_EQ(after.Get<int32_t>({0}),expected_after);
    EXPECT_EQ(before.Get<int32_t>({1}),4);EXPECT_EQ(after.Get<int32_t>({1}),4);
    if(active) EXPECT_EQ(module->entry_computation()->root_instruction()->opcode(),HloOpcode::kScatter);
    std::cout<<"REDUCER_INDEX_RESULT family=scatter case=p"<<roles<<"_"<<side<<"_layout"<<layout
             <<" mode="<<mode<<" changed="<<changed<<" before="<<Values(before)<<" after="<<Values(after)
             <<" rewritten_verified=1\nORIGINAL_HLO\n"<<original<<"\nREWRITTEN_HLO\n"<<module->ToString()<<"\n";
  }
}
TEST_F(ReducerIndexReplay, GatherLiteralBoundary) {
  struct Case {const char* name;bool narrow;int extent;int threshold;int index;};
  const Case cases[]={
    {"s8_wrap_zero",true,129,129,0},{"s8_wrap_negative",true,129,129,-1},
    {"s8_wrap_max",true,129,129,127},{"s8_extent128",true,128,128,127},
    {"s8_threshold128",true,129,128,0},{"s8_default4",true,129,4,0},
    {"s32_zero",false,129,129,0},{"s32_high",false,129,129,200},
    {"s32_negative",false,129,129,-1}};
  for(const Case& test:cases)
  for(const std::string mode:{"control","handler","pass"}) {
    const std::string type=test.narrow ? "s8" : "s32";
    const std::string hlo="HloModule gather_boundary\nENTRY main {\ndata = s32["+
        std::to_string(test.extent)+"] parameter(0)\nindex = "+type+"[1] parameter(1)\n"
        "ROOT result = s32[1] gather(data,index), offset_dims={}, collapsed_slice_dims={0}, "
        "start_index_map={0}, index_vector_dim=1, slice_sizes={1}\n}";
    ASSERT_OK_AND_ASSIGN(std::unique_ptr<HloModule> module,ParseAndReturnVerifiedModule(hlo));
    Literal data(ShapeUtil::MakeShape(S32,{test.extent}));
    ASSERT_OK(data.Populate<int32_t>([](absl::Span<const int64_t> i){return int32_t(i[0]);}));
    Literal index=test.narrow ? LiteralUtil::CreateR1<int8_t>({int8_t(test.index)})
                             : LiteralUtil::CreateR1<int32_t>({test.index});
    std::vector<const Literal*> args{&data,&index};HloEvaluator evaluator;evaluator.set_use_fast_path(false);
    ASSERT_OK_AND_ASSIGN(Literal before,evaluator.Evaluate(*module,args));
    const std::string original=module->ToString();bool changed=false;
    if(mode!="control") {
      AlgebraicSimplifierOptions options;options.set_run_to_fixed_point(false);
      options.set_very_small_gather_size(test.threshold);
      AlgebraicSimplifier simplifier(options);
      if(mode=="handler") {
        InitializedVisitor visitor(options,&simplifier);
        ASSERT_FALSE(visitor.Initialize(module->entry_computation(),options,&simplifier));
        ASSERT_EQ(original,module->ToString());
        ASSERT_OK(visitor.HandleGather(module->entry_computation()->root_instruction()));changed=visitor.changed();
      } else {ASSERT_OK_AND_ASSIGN(changed,simplifier.Run(module.get()));}
    }
    HloVerifier verifier(false,true);ASSERT_OK(verifier.Run(module.get()).status());
    HloEvaluator after_evaluator;after_evaluator.set_use_fast_path(false);
    ASSERT_OK_AND_ASSIGN(Literal after,after_evaluator.Evaluate(*module,args));
    const bool active=mode!="control" && test.extent<=test.threshold;
    const int original_value=std::max(0,std::min(test.extent-1,test.index));
    const int replacement=active && test.narrow && test.extent==129 ? 128 : original_value;
    EXPECT_EQ(changed,active);EXPECT_EQ(before.Get<int32_t>({0}),original_value);
    EXPECT_EQ(after.Get<int32_t>({0}),replacement);
    if(active) EXPECT_EQ(module->entry_computation()->root_instruction()->opcode(),HloOpcode::kSelect);
    std::cout<<"REDUCER_INDEX_RESULT family=gather case="<<test.name<<" mode="<<mode<<" changed="<<changed
             <<" before="<<Values(before)<<" after="<<Values(after)<<" rewritten_verified=1\n"
             <<"ORIGINAL_HLO\n"<<original<<"\nREWRITTEN_HLO\n"<<module->ToString()<<"\n";
  }
  ASSERT_OK_AND_ASSIGN(Literal converted,LiteralUtil::CreateR0<int64_t>(128).Convert(S8));
  EXPECT_EQ(converted.GetFirstElement<int8_t>(),-128);
  std::cout<<"REDUCER_INDEX_CAST original=128 s8="<<int(converted.GetFirstElement<int8_t>())<<"\n";
}
}  // namespace
}  // namespace xla
