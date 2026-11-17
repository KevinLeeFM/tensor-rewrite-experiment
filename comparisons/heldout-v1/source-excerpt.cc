// Excerpt from pinned XLA e58e523b11f1fde802a493a776d158007486e1bf
// algebraic_simplifier.cc lines 7098-7141; see STATEMENT.md for restrictions.
  // reshape(iota) -> iota or a mixed radix calculation like
  // s32[2,3,4] reshape(s32[24] iota()) to
  // add(
  //    add(s32[2,3,4] iota() iota_dimension=2,
  //        4 * s32[2,3,4] iota() iota_dimension=1),
  //    12 * s32[2,3,4] iota() iota_dimension=0).
  if (operand->opcode() == HloOpcode::kIota) {
    auto* iota = Cast<HloIotaInstruction>(operand);
    auto common_factors = CommonFactors(operand->shape().dimensions(),
                                        reshape->shape().dimensions());
    auto iota_dim = absl::c_find_if(
        common_factors, [&](const std::pair<int64_t, int64_t>& dim_pair) {
          return dim_pair.first == iota->iota_dimension() &&
                 reshape->shape().dimensions(dim_pair.second) > 1;
        });
    auto next_dim = absl::c_find_if(
        common_factors, [&](const std::pair<int64_t, int64_t>& dim_pair) {
          return dim_pair.first == iota->iota_dimension() + 1;
        });
    if (iota_dim != common_factors.end() && next_dim != common_factors.end()) {
      int64_t multiplier = 1;
      HloInstruction* new_reshape = nullptr;

      for (int64_t dim = (iota_dim + 1)->second - 1; dim >= iota_dim->second;
           --dim) {
        HloInstruction* new_iota = iota->AddInstruction(
            HloInstruction::CreateIota(reshape->shape(), dim));
        if (new_reshape) {
          new_reshape = reshape->AddInstruction(HloInstruction::CreateBinary(
              reshape->shape(), HloOpcode::kAdd, new_reshape,
              reshape->AddInstruction(HloInstruction::CreateBinary(
                  reshape->shape(), HloOpcode::kMultiply, new_iota,
                  MakeScalarLike(reshape, multiplier)))));
        } else {
          new_reshape = new_iota;
        }
        multiplier *= reshape->shape().dimensions(dim);
      }
      return ReplaceInstruction(reshape, new_reshape);
    }
  }

  // Moves the reshape in reshape(dus(...), x, ...)) before dus so that it can
  // enable other optimizations, e.g., merging with broadcast, and sparse update
