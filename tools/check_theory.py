"""Check mathematical theory only; never invoke source extraction or native pass replay."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
from lean_size import count_source

ROOT = Path(__file__).resolve().parents[1]
ALLOWED = {'propext', 'Classical.choice', 'Quot.sound'}
THEOREMS = {
    'ConvolutionDot': ['lhs_index_row', 'lhs_index_channel', 'rhs_index_feature', 'rhs_index_channel', 'matrix_output_row', 'matrix_output_feature', 'convolution_output_dot_output', 'dot_output_convolution_output', 'sum_contract_positions', 'dot_eq_channel_sum', 'convolve_eq_dot', 'dot_eq_convolve'],
    'ConvolutionPointwise': ['dilatedExtent_one', 'output_extent_eq', 'output_shape_eq', 'elementCount_unit', 'kernel_count_eq_one', 'kernel_index_unique', 'base_position_eq', 'axis_inputIndex_eq', 'spatial_input_eq', 'term_pointwise', 'sum_kernel_positions', 'convolve_eq_channelSum', 'convolve_single_channel'],
    'FloatNegation': ['scalar_involution', 'tensor_involution', 'reindex_neg', 'reverse_neg'],
    'FiniteSum': ['foldl_add_eq_sum', 'reduce_add_eq_fiber_sum', 'reshapeEquiv_apply',
                  'sum_reshape', 'sum_swap', 'sum_add'],
    'ContractionAlgebra': ['dot_add_left', 'dot_add_right'],
    'LogicalFamily': ['rewrite_sound', 'allRules_complete', 'allRules_nodup',
                      'word_keys_uniform', 'predicate_count', 'word_count'],
    'Convolution': ['inputIndex?_negative', 'basePosition_reverse', 'inputIndex?_position', 'term_zero_kernel', 'term_zero_input', 'convolve_zero_kernel', 'convolve_zero_input', 'convolve_empty_fiber', 'spatialInput?_empty', 'term_empty_spatial_input', 'convolve_empty_spatial_input', 'convolve_empty_kernel', 'convolve_no_channels', 'term_kernel_add', 'term_input_add', 'term_kernel_scale', 'convolve_kernel_add', 'convolve_input_add', 'convolve_kernel_scale', 'convolve_bias_scale'],
}


def main():
    build = subprocess.run(['lake', 'build'], cwd=ROOT, text=True, capture_output=True)
    (ROOT / 'reports/theory-build.log').write_text(build.stdout + build.stderr)
    if build.returncode:
        print((build.stdout + build.stderr)[-6000:]); raise SystemExit(build.returncode)
    audit = subprocess.run(['lake', 'env', 'lean', 'tests/fixtures/TheoryAudit.lean'],
                           cwd=ROOT, text=True, capture_output=True)
    assert audit.returncode == 0, audit.stdout + audit.stderr
    dependencies = {}
    for group, names in THEOREMS.items():
        for name in names:
            full_name = 'TensorRewrite.Theory.' + group + '.' + name
            match = re.search(re.escape(full_name) + r"' depends on axioms: \[([^\]]*)\]",
                              audit.stdout)
            if match:
                axioms = {a.strip() for a in match[1].split(',') if a.strip()}
            else:
                assert full_name + "' does not depend on any axioms" in audit.stdout, audit.stdout
                axioms = set()
            assert axioms <= ALLOWED, (full_name, axioms)
            dependencies[full_name] = sorted(axioms)
    categories = {'TensorRewrite/Theory/FloatNegation.lean': 'R',
                  'TensorRewrite/Theory/FiniteSum.lean': 'H',
                  'TensorRewrite/Theory/ContractionAlgebra.lean': 'R',
                  'TensorRewrite/Theory/LogicalFamily.lean': 'S',
                  'TensorRewrite/Theory/LogicalFamilyProof.lean': 'R',
                  'TensorRewrite/Theory/Convolution.lean': 'S',
                  'TensorRewrite/Theory/ConvolutionLemmas.lean': 'H',
                  'TensorRewrite/Theory/ConvolutionAlgebra.lean': 'R',
                  'TensorRewrite/Theory/ConvolutionPointwise.lean': 'S',
                  'TensorRewrite/Theory/ConvolutionPointwiseLemmas.lean': 'H',
                  'TensorRewrite/Theory/ConvolutionPointwiseAlgebra.lean': 'R',
                  'TensorRewrite/Theory/ConvolutionDot.lean': 'S',
                  'TensorRewrite/Theory/ConvolutionDotLemmas.lean': 'H',
                  'TensorRewrite/Theory/ConvolutionDotProof.lean': 'R',
                  'TensorRewriteTheory.lean': 'A'}
    rows = []
    for name, category in categories.items():
        path = ROOT / name
        rows.append(dict(path=name, category=category,
                         sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
                         **count_source(path.read_text())))
    integration = json.loads((ROOT / 'reports/library-setup.json').read_text())
    count = sum(r['code_lines'] for r in rows)
    report = dict(status='kernel_checked_mathematical_theory', new_theorem_count=len(dependencies),
                  code_correspondence_performed=False, code_correspondence_future_work=True,
                  source_rewrite_acceptance_claimed=False, mathematical_workload_denominator=None,
                  independently_reviewed_statements=False, build_exit_code=build.returncode,
                  audit_exit_code=audit.returncode, axiom_dependencies=dependencies,
                  files=rows, new_theory_lines=count, previous_custom_lean_lines=2796,
                  total_custom_lean_lines=2796+count, dependency_packages=integration['packages'],
                  proof_reuse={'FloatNegation.scalar_involution': 'FloatLib Model.neg_neg',
                               'FiniteSum.sum_reshape': 'Mathlib Equiv.sum_comp plus existing index theory',
                               'ConvolutionPointwise.convolve_eq_channelSum':
                                   'Mathlib Fin.sum_univ_def and Equiv.sum_comp; derived window geometry',
                               'ConvolutionDot.convolve_eq_dot':
                                   'existing contraction/index inverses, channel reduction, Mathlib sums',
                               'FiniteSum.sum_swap': 'Mathlib Finset.sum_comm',
                               'FiniteSum.sum_add': 'Mathlib Finset.sum_add_distrib'},
                  scope='format-general floating negation; exact finite sums and semiring '
                        'contraction/convolution exact algebra and typed logical family; '
                        'no IEEE reassociation/distributivity claim',
                  theorem_profiles={
                      name: ('all supported FloatLib value formats; bit-exact negation; '
                             'flags not observed' if '.FloatNegation.' in name else
                             'pure predicate/word tensor values; all ranks/extents/word widths; '
                             'equal-input xor requires value equality' if '.LogicalFamily.' in name else
                             'exact finite sums and ordered reductions under explicitly stated '
                             'AddMonoid/AddCommMonoid and equal-count premises' if '.FiniteSum.' in name
                             else 'pointwise convolution as per-group matrix Dot; batch/spatial row '
                                  'flattening with inverse coordinate maps; exact Semiring and identity '
                                  'finish; arbitrary ranks, extents, groups and channels; no IEEE/layout'
                             if '.ConvolutionDot.' in name
                             else 'unit spatial kernel/stride/base dilation; zero padding; arbitrary '
                                  'kernel dilation/reversal, rank, extents, groups and channel counts; '
                                  'exact semiring; channel reduction and single-channel product'
                             if '.ConvolutionPointwise.' in name
                             else 'factored static convolution; positive stride/dilations; signed padding; '
                                  'bounded grouping/sampling; Semiring for algebra; no IEEE contract'
                             if '.Convolution.' in name or '.ConvolutionPointwise.' in name
                             else 'arbitrary static contraction plans; Semiring; identity finish; '
                                  'no rounded floating-point algebra instance')
                      for name in dependencies},
                  audit_stdout=audit.stdout)
    (ROOT / 'reports/theory-progress.json').write_text(json.dumps(report, indent=2)+'\n')
    print('Mathematical theory passed: '+str(len(dependencies))+' theorems; '+str(count)+
          ' new Lean lines; code correspondence deferred.')


if __name__ == '__main__':
    main()
