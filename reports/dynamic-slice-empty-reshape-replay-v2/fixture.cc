/* Copyright 2026 The OpenXLA Authors.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software is distributed
on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND. */
#include <iostream>
#include <memory>
#include <string>
#include "gtest/gtest.h"
#include "xla/hlo/ir/hlo_module.h"
#include "xla/hlo/testlib/hlo_hardware_independent_test_base.h"
#include "xla/hlo/transforms/simplifiers/algebraic_simplifier.h"
#include "xla/service/hlo_verifier.h"
namespace xla {
namespace {
class DynamicSliceEmptyReshapeReplay : public HloHardwareIndependentTestBase {};
class InitializedDynamicSliceVisitor : public AlgebraicSimplifierVisitor {
 public:
  using AlgebraicSimplifierVisitor::AlgebraicSimplifierVisitor;
  bool Initialize(HloComputation* c,const AlgebraicSimplifierOptions& o,AlgebraicSimplifier* s) {
    const bool changed=Run(c,o,s);initializing_=false;return changed;
  }
  absl::Status HandleDynamicSlice(HloInstruction* node) override {
    return initializing_ ? absl::OkStatus() : AlgebraicSimplifierVisitor::HandleDynamicSlice(node);
  }
  absl::Status HandleReshape(HloInstruction* node) override {
    return initializing_ ? absl::OkStatus() : AlgebraicSimplifierVisitor::HandleReshape(node);
  }
 private:
  bool initializing_=true;
};
TEST_F(DynamicSliceEmptyReshapeReplay, InsertedEmptyAxisAndControls) {
  std::cout<<std::unitbuf;
  struct Case {const char* name;int first;int second;bool layout;bool constants;};
  const Case cases[]={{"empty_inserted",0,1,false,false},
    {"nonempty",1,1,false,false},{"empty_retained",1,0,false,false},
    {"both_empty",0,0,false,false},{"layout_sensitive",0,1,true,false},
    {"constant_conversion",0,1,false,true}};
  for(const Case& test:cases)
  for(const std::string mode:{"control","handler","pass"}) {
    SCOPED_TRACE(std::string(test.name)+mode);
    const std::string sizes=std::to_string(test.first)+","+std::to_string(test.second);
    const std::string hlo="HloModule ds_empty_reshape\nENTRY main {\n"
      "data = s32[2] parameter(0)\nindex = s32[] parameter(1)\nzero = s32[] constant(0)\n"
      "reshaped = s32[1,2] reshape(data)\nROOT result = s32["+sizes+
      "] dynamic-slice(reshaped,zero,"+(test.constants ? "zero" : "index")+
      "), dynamic_slice_sizes={"+sizes+"}\n}";
    ASSERT_OK_AND_ASSIGN(std::unique_ptr<HloModule> module,ParseAndReturnUnverifiedModule(hlo));
    HloVerifier input_verifier(false,true);ASSERT_OK(input_verifier.Run(module.get()).status());
    const std::string original=module->ToString();
    auto* computation=module->entry_computation();auto* root=computation->root_instruction();
    AlgebraicSimplifierOptions options;options.set_run_to_fixed_point(false);
    options.set_is_layout_sensitive(test.layout);
    AlgebraicSimplifier simplifier(options);
    InitializedDynamicSliceVisitor visitor(options,&simplifier);
    if(mode=="handler") {
      ASSERT_FALSE(visitor.Initialize(computation,options,&simplifier));
      ASSERT_EQ(original,module->ToString());
    }
    const bool fatal=std::string(test.name)=="empty_inserted" && mode!="control";
    bool changed=false;
    if(fatal) {
      if(mode=="handler") {
        ASSERT_DEATH({const auto status=visitor.HandleDynamicSlice(root);(void)status;},
                     "StaticExtentProduct");
      } else {
        ASSERT_DEATH({const auto status=simplifier.Run(module.get());(void)status;},
                     "StaticExtentProduct");
      }
      ASSERT_EQ(original,module->ToString());
    } else if(mode=="handler") {
      ASSERT_OK(visitor.HandleDynamicSlice(root));changed=visitor.changed();
    } else if(mode=="pass") {ASSERT_OK_AND_ASSIGN(changed,simplifier.Run(module.get()));}
    if(!fatal) {
      HloVerifier verifier(false,true);ASSERT_OK(verifier.Run(module.get()).status());
      EXPECT_EQ(changed,mode!="control" && (!test.layout || mode=="pass"));
      if(test.layout) {
        EXPECT_EQ(computation->root_instruction(),root);
        if(mode=="pass") EXPECT_EQ(root->operand(0)->opcode(),HloOpcode::kBitcast);
      }
    }
    std::cout<<"DS_EMPTY_RESHAPE_RESULT case="<<test.name<<" mode="<<mode
      <<" original_verified=1 outcome="<<(fatal ? "checked_fatal" : "valid")
      <<" changed="<<(fatal ? "unreturned" : changed ? "1" : "0")
      <<"\nORIGINAL_HLO\n"<<original<<"\nPARENT_HLO\n"<<module->ToString()<<"\n";
  }
}
}  // namespace
}  // namespace xla
