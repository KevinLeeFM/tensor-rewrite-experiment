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
class ScaledNestedSliceReplay : public HloHardwareIndependentTestBase {};
class InitializedSliceVisitor : public AlgebraicSimplifierVisitor {
 public:
  using AlgebraicSimplifierVisitor::AlgebraicSimplifierVisitor;
  bool Initialize(HloComputation* computation,const AlgebraicSimplifierOptions& options,
                  AlgebraicSimplifier* simplifier) {
    const bool changed=Run(computation,options,simplifier);initializing_=false;return changed;
  }
  absl::Status HandleDynamicSlice(HloInstruction* slice) override {
    if (initializing_) return absl::OkStatus();
    return AlgebraicSimplifierVisitor::HandleDynamicSlice(slice);
  }
 private:
  bool initializing_=true;
};
struct Case {const char* name;int multiplier;int width;bool reversed;bool wide;
             bool direct;bool constants;bool disable_conversion;bool iota;};
TEST_F(ScaledNestedSliceReplay, FailedIotaProbeContinuation) {
  const Case cases[]={
    {"scaled",7,1,false,false,false,false,false,false},
    {"negative_multiplier",-3,1,false,false,false,false,false,false},
    {"one_multiplier",1,1,false,false,false,false,false,false},
    {"zero_multiplier",0,1,false,false,false,false,false,false},
    {"reversed",7,1,true,false,false,false,false,false},
    {"outer_two",7,2,false,false,false,false,false,false},
    {"s64_result",7,1,false,true,false,false,false,false},
    {"direct_nested",1,1,false,false,true,false,false,false},
    {"constant_starts",7,1,false,false,false,true,false,false},
    {"constant_starts_disabled",7,1,false,false,false,true,true,false},
    {"intended_iota",7,1,false,false,false,false,false,true},
  };
  for (const Case& test : cases)
  for (const std::string mode : {"control","handler","pass"}) {
    const std::string type=test.wide ? "s64" : "s32";
    const std::string istart=test.constants ? "ci" : "inner_start";
    const std::string ostart=test.constants ? "co" : "outer_start";
    const std::string inner_size=test.iota ? "10" : "6";
    std::string hlo="HloModule scaled_nested_slice\nENTRY main {\n"
        "data = "+type+"[10] parameter(0)\ninner_start = s32[] parameter(1)\n"
        "outer_start = s32[] parameter(2)\nmultiplier = "+type+"[] parameter(3)\n";
    if (test.constants) hlo+="ci = s32[] constant(1)\nco = s32[] constant(2)\n";
    if (test.iota) hlo+="inner = "+type+"[10] iota(), iota_dimension=0\n";
    else hlo+="inner = "+type+"[6] dynamic-slice(data,"+istart+"), dynamic_slice_sizes={6}\n";
    if (!test.direct) {
      hlo+="scale = "+type+"["+inner_size+"] broadcast(multiplier), dimensions={}\n";
      hlo+="product = "+type+"["+inner_size+"] multiply("+
          (test.reversed ? "scale,inner" : "inner,scale")+")\n";
    }
    hlo+="ROOT outer = "+type+"["+std::to_string(test.width)+"] dynamic-slice("+
        (test.direct ? "inner" : "product")+","+ostart+"), dynamic_slice_sizes={"+
        std::to_string(test.width)+"}\n}";
    ASSERT_OK_AND_ASSIGN(std::unique_ptr<HloModule> module,ParseAndReturnVerifiedModule(hlo));
    Literal data=test.wide ? LiteralUtil::CreateR1<int64_t>({1,2,3,4,5,6,7,8,9,10})
                           : LiteralUtil::CreateR1<int32_t>({1,2,3,4,5,6,7,8,9,10});
    Literal inner=LiteralUtil::CreateR0<int32_t>(1),outer=LiteralUtil::CreateR0<int32_t>(2);
    Literal multiplier=test.wide ? LiteralUtil::CreateR0<int64_t>(test.multiplier)
                                 : LiteralUtil::CreateR0<int32_t>(test.multiplier);
    std::vector<const Literal*> args{&data,&inner,&outer,&multiplier};
    HloEvaluator evaluator;evaluator.set_use_fast_path(false);
    ASSERT_OK_AND_ASSIGN(Literal before,evaluator.Evaluate(*module,args));
    const std::string original=module->ToString();bool changed=false;
    if (mode!="control") {
      AlgebraicSimplifierOptions options;options.set_is_layout_sensitive(true);
      options.set_run_to_fixed_point(false);options.set_enable_fast_math(false);
      options.set_disable_dynamic_slice_to_slice_conversion(test.disable_conversion);
      AlgebraicSimplifier simplifier(options);
      if (mode=="handler") {
        InitializedSliceVisitor visitor(options,&simplifier);
        ASSERT_FALSE(visitor.Initialize(module->entry_computation(),options,&simplifier));
        ASSERT_EQ(original,module->ToString());
        ASSERT_OK(visitor.HandleDynamicSlice(module->entry_computation()->root_instruction()));
        changed=visitor.changed();
      } else {ASSERT_OK_AND_ASSIGN(changed,simplifier.Run(module.get()));}
    }
    HloVerifier verifier(false,true);ASSERT_OK(verifier.Run(module.get()).status());
    HloEvaluator after_evaluator;after_evaluator.set_use_fast_path(false);
    ASSERT_OK_AND_ASSIGN(Literal after,after_evaluator.Evaluate(*module,args));
    const bool drops=!test.reversed && !test.wide && !test.direct && !test.iota &&
        test.width==1 && (!test.constants || test.disable_conversion);
    const bool active=mode!="control";
    const bool expected_change=active && (drops || test.direct || test.constants || test.iota);
    EXPECT_EQ(changed,expected_change);
    std::string bvalues,avalues;
    for (int i=0;i<test.width;++i) {
      const int64_t b=test.wide ? before.Get<int64_t>({i}) : before.Get<int32_t>({i});
      const int64_t a=test.wide ? after.Get<int64_t>({i}) : after.Get<int32_t>({i});
      const int64_t selected=(test.iota ? 2 : 4)+i;
      EXPECT_EQ(b,selected*(test.direct ? 1 : test.multiplier));
      EXPECT_EQ(a,active && drops ? selected : b);
      if (i) {bvalues+=",";avalues+=",";}
      bvalues+=std::to_string(b);avalues+=std::to_string(a);
    }
    if (active && drops) {
      auto* root=module->entry_computation()->root_instruction();
      EXPECT_EQ(root->opcode(),HloOpcode::kDynamicSlice);
      EXPECT_EQ(root->operand(0)->opcode(),HloOpcode::kParameter);
      EXPECT_EQ(root->operand(0)->parameter_number(),0);
      EXPECT_EQ(root->operand(1)->opcode(),HloOpcode::kAdd);
    }
    std::cout<<"SCALED_NESTED_RESULT case="<<test.name<<" mode="<<mode<<" changed="<<changed
             <<" before="<<bvalues<<" after="<<avalues<<" rewritten_verified=1\n"
             <<"ORIGINAL_HLO\n"<<original<<"\nREWRITTEN_HLO\n"<<module->ToString()<<"\n";
  }
}
}  // namespace
}  // namespace xla
