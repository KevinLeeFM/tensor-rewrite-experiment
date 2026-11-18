int64_t HloCostAnalysis::GetDotFlops(const Shape& lhs_shape,
                                     const Shape& result_shape,
                                     const DotDimensionNumbers& dnums) {
  // Count of elements along the reduction dimensions.
  int64_t reduction_width = 1;
  for (auto dim : dnums.lhs_contracting_dimensions()) {
    reduction_width *= lhs_shape.dimensions(dim);
  }
  // Each output element requires reduction_width FMA operations.
  return kFmaFlops * ShapeUtil::ElementsIn(result_shape) * reduction_width;
}
