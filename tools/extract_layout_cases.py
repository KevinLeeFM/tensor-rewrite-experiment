"""Inspected layout/constant/barrier branches, with explicit continuing stages."""
import hashlib
import json
from pathlib import Path
from extract_scalar_control_cases import validate_batch
from extract_arithmetic_cases import validate_helpers

ROOT = Path(__file__).resolve().parents[1]


def validate_effect_evidence(batch, source, structural):
    required=['operand edge mutation','shape assignment','barrier metadata remap',
              'operand metadata remap','each user GTE index mutation']
    for case in batch['cases']:
        if case['handler']!='HandleOptimizationBarrier':continue
        effects=case['effect_evidence']
        if [effect['role'] for effect in effects]!=required:
            raise ValueError('barrier graph effect omission or order mismatch')
        for effect in effects:
            if not case['line']<=effect['line']<=case['end_line'] or effect['anchor'] not in source[effect['line']-1]:
                raise ValueError('barrier effect source identity mismatch')
        shape=effects[1]
        if not any(a['line']==shape['line'] and a['source']==shape['anchor'].removesuffix(';')
                   and not a['overlapping_syntax_rewrites'] for a in structural['assignment_expressions']):
            raise ValueError('actual barrier shape assignment not discovered')


def main():
    inventory = json.loads((ROOT / 'census/source-sites.json').read_text())
    structural = json.loads((ROOT / 'census/normalized-structural-sites.json').read_text())
    source = (ROOT / 'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_text().splitlines()
    definitions = {d['name']: d for d in inventory['definitions']}
    cases = []

    def add(owner, slug, ordinal, lhs, rhs, guard, deps, helpers=(), continuation='return after successful branch'):
        definition = definitions[owner]
        body = '\n'.join(source[definition['line'] - 1:definition['end_line']])
        row = dict(id=owner + '/' + slug, handler=owner, line=definition['line'],
                   end_line=definition['end_line'], lhs=lhs, rhs=rhs, guard=guard,
                   source_body_sha256=hashlib.sha256(body.encode()).hexdigest(),
                   status='source_extracted_pending_independent_review', proof=None,
                   unit_kind='branch_or_rewrite_stage_pending_complete_path_composition',
                   path_condition='legal input HLO; source-order early exits and current local pointer bindings apply; earlier stages may already have rewritten',
                   continuation=continuation, dependencies=deps, helper_contract_ids=list(helpers),
                   type_partition_status='datatype/layout/memory-space profiles not fully split')
        if isinstance(ordinal, int):
            sites = [s for s in inventory['sites'] if s['owner'] == owner and s['kind'] == 'replacement']
            site = sites[ordinal]
            row.update(replacement_ordinals=[ordinal], replacement_site_id=site['id'],
                       replacement_line=site['line'], replacement_call=site['call'],
                       replacement_source=source[site['line'] - 1])
        else:
            target, anchor = ordinal
            assert anchor in body
            row.update(delegation_target=target, delegation_line=definition['line'] + body[:body.index(anchor)].count('\n'))
        cases.append(row)
        return row

    bitcast_guard = 'initial bitcast has no control dependencies; '
    add('HandleBitcast', 'unary-sandwich', 0, 'Bitcast(Unary(Bitcast(x)))', 'Bitcast(cloned Unary(x))',
        bitcast_guard + 'Unary elementwise, not Fusion, one operand and one user; same element types through all four endpoints; inner bitcast and x have no tiles or no layout',
        ['CloneWithNewOperands at x shape', 'physical indexing versus logical elementwise behavior', 'layout and byte-size legality'])
    add('HandleBitcast', 'compose-stage', 1, 'Bitcast(Bitcast(x))', 'Bitcast(x)',
        bitcast_guard + 'nested Bitcast matcher after recursive simplification of inner operand',
        ['recursive HandleBitcast may already change inner graph', 'new_bitcast_ptr survives replacement', 'control and metadata propagation'],
        continuation='rebind local bitcast to new node; continue type check, compatible elimination and later helper calls')
    add('HandleBitcast', 'compatible-stage', 2, 'current Bitcast(x)', 'current operand x',
        bitcast_guard + 'current output and operand same element type; ReplaceInstructionIfCompatible succeeds',
        ['SameShape depends on layout sensitivity', 'control predecessors and sharding preservation', 'helper may receive an opcode other than Bitcast after rebinding'],
        continuation='rebind bitcast to its operand; continue chain removal and possible broadcast folding')
    add('HandleBitcast', 'recursive-inner', ('HandleBitcast', 'ABSL_RETURN_IF_ERROR(HandleBitcast(bitcast->mutable_operand(0)))'),
        'Bitcast(Bitcast(x))', 'inner handler-dependent graph', bitcast_guard + 'current operand opcode Bitcast',
        ['recursive call status and reachability', 'intermediate graph changes and current operand aliases'],
        continuation='after recursive success, re-match outer node for composition; success need not mean a rewrite')
    add('HandleBitcast', 'chain-delegation', ('TryRemovingBitcastOrReshapeTransposeChain', 'TryRemovingBitcastOrReshapeTransposeChain(bitcast)'),
        'current rebound node', 'helper-dependent graph', bitcast_guard + 'same-type check passed; helper returns true',
        ['current node may differ from original visited node', 'chain helper caller-specific premises'])
    add('HandleBitcast', 'broadcast-delegation', ('SimplifyTransposeOfBroadcast', 'SimplifyTransposeOfBroadcast(bitcast, dimensions.value())'),
        'Bitcast(Broadcast(x))', 'Broadcast(x,remapped dims)',
        bitcast_guard + 'current node still Bitcast with Broadcast operand; output/broadcast tile lists equal; DeduceTransposeDimensionsForBitcast returns permutation',
        ['ShapeUtil::DeduceTransposeDimensionsForBitcast', 'supplied permutation must implement this physical bitcast', 'broadcast helper layout restrictions'])

    add('HandleBitcastConvert', 'compose', 0, 'BitcastConvert(BitcastConvert(x))', 'BitcastConvert(x,final shape)',
        'inner opcode BitcastConvert', ['bit packing/unpacking, endianness and rank-changing shape inference'])
    add('HandleBitcastConvert', 'concat-delegation', ('TrySimplifyTautologicalBitcastConvert', 'TrySimplifyTautologicalBitcastConvert(bitcast)'),
        'BitcastConvert(Concat(...))', 'helper-dependent Concat', 'earlier composition did not return; helper returns true',
        ['input/output bit widths and original concat dimension'])
    option = 'layout sensitive; rewrite_no_op_bitcast_convert_to_bitcast; '
    add('HandleBitcastConvert', 'same-physical-shape', 1, 'BitcastConvert(x)', 'Bitcast(x)',
        option + 'ShapeUtil::EqualIgnoringElementType(output,x); legal source implies same storage bit width',
        ['shape legality is a premise to justify the width inference', 'bit representations and memory layout'], ['ReplaceWithBitcast'])
    add('HandleBitcastConvert', 'last-contiguous-axis', 2, 'BitcastConvert(x)', 'Bitcast(x)',
        option + 'shape with more dimensions has LastDimIsMinorMost; absent/zero element_size_in_bits requires StorageBitWidth divisible by8, otherwise exact element-size/width equality',
        ['StorageBitWidth versus logical bit width', 'extra-axis packing, rank and endian semantics'], ['ReplaceWithBitcast'])
    add('HandleBitcastConvert', 'compatible', 3, 'BitcastConvert(x)', 'x', 'compatibility replacement succeeds; return value otherwise ignored',
        ['SameShape', 'control and representation equality'])

    add('HandleCopy', 'swap-delegation', ('SwapCopyBitcastCopy', 'SwapCopyBitcastCopy(copy)'),
        'Copy(Bitcast*(Copy(x)))', 'helper-dependent reordered copies/bitcast', 'first handler path; helper true', ['host copies and tiling predicates'])
    for equal in (True, False):
        add('HandleCopy', 'compose-' + ('identity' if equal else 'copy'), 0 if equal else 1, 'Copy(Copy(x))',
            'x' if equal else 'Copy(x,outer shape)', 'nested Copy matcher; ShapeUtil::Equal(x shape,outer shape) is ' + str(equal),
            ['allocation/memory-space behavior', 'copy side effects and graph metadata'])
    add('HandleCopy', 'compatible', 2, 'Copy(x)', 'x',
        'no sharding OR copy is not module entry root; compatibility replacement succeeds',
        ['entry-root sharding preservation', 'SameShape', 'control dependency contract'])
    add('HandleCopy', 'chain-bitcast', 3, 'Copy(copy/reshape chain)', 'Bitcast(selected ancestor)',
        'not(layout sensitive AND both endpoint layouts present AND memory spaces differ); BitcastingOperandOfReshapeOrCopyChain returns nonnull',
        ['layout-sensitive helper walk', 'memory-space preservation'], ['BitcastingOperandOfReshapeOrCopyChain', 'ReplaceWithBitcast'])
    add('HandleCopy', 'reshape-clone', 4, 'Copy(Reshape(x))', 'Reshape(x,copy shape)',
        'Reshape one user; ShapeUtil::ReshapeIsBitcast(reshape shape,copy shape); layout insensitive OR neither endpoint has match-dimension tile OR tile lists equal',
        ['clone keeps Reshape attributes', 'logical versus hardware bitcast predicates', 'tiling/padding'], ['HasMatchDimensionTile'])
    reorder_guard = ('layout sensitive; Reshape one user; optional preceding Copy one user; AlignLayouts(output,reshape_operand) succeeds; '
                     'should_rewrite = (!old_hardware AND new_hardware) OR (copy_before present AND (!old_hardware OR new_hardware)); '
                     'after allocation estimate <= 10*before/9')
    for omit_copy in (False, True):
        for hardware in (False, True):
            add('HandleCopy', 'reshape-reorder-' + ('omit-copy' if omit_copy else 'new-copy') + '-' + ('bitcast' if hardware else 'reshape'), 5,
                'Copy(Reshape(optional Copy(x)))',
                ('Bitcast' if hardware else 'Reshape') + '(' + ('x' if omit_copy else 'Copy(reshape_operand,aligned shape)') + ',output shape)',
                reorder_guard + '; new_reshape_is_hardware_bitcast=' + str(hardware) + '; can_remove_copy=' + str(omit_copy) +
                ' where removal requires copy_before and equality ignoring memory space between aligned shape and copy_before input',
                ['ShapeUtil::AlignLayouts', 'UpdateLayout', 'virtual ReshapeIsBitcast', 'ArraySize products and integer overflow', 'memory space ignored by one equality, not universally'])

    for branch in ('move-bitcast', 'move-copy'):
        add('SwapCopyBitcastCopy', branch, 0 if branch == 'move-bitcast' else 1,
            'Copy(Bitcast*(Copy(x)))', 'Copy(Bitcast(x,new shape),output shape)' if branch == 'move-bitcast' else 'Bitcast(Copy(x,new shape),output shape)',
            'outer and inner Copy not synchronous host transfers; intervening nodes Bitcast; ComputeBitcastDimMap succeeds; initial ValidateTilingOfBitcast succeeds; ' +
            ('tiling test against x succeeds' if branch == 'move-bitcast' else 'tiling test against x fails; tiling test against outer Copy succeeds') +
            '; corresponding ReshapeLayoutDimensions returns shape and IsValidLayout true',
            ['host_offload_utils contract', 'CHECK_OK error behavior', 'virtual layout legality', 'intermediate cloned node attributes'],
            ['ComputeBitcastDimMap', 'InvertBitcastDimMap', 'ReshapeLayoutDimensions', 'ValidateTilingOfBitcast'])
    add('TrySimplifyTautologicalBitcastConvert', 'concat', 0, 'BitcastConvert(Concat(BitcastConvert(xs)))', 'Concat(xs,original axis)',
        'outer BitcastConvert; Concat operand; all concat inputs BitcastConvert whose source type equals outer output type; MakeConcatHlo succeeds',
        ['bitwidth-induced extra axes', 'concat dimension interpretation before/after packing', 'shape and byte correspondence'])

    for slug, ordinal, rhs, guard, deps, helpers in [
        ('tuple', 0, 'recursive Tuple of leaf constants', 'output shape Tuple', ['tuple/token leaves', 'literal slicing and recursive termination'], ['BuildTupleConstant']),
        ('uniform', 1, 'Broadcast(first scalar literal,original shape)', 'not Tuple or TOKEN; ElementsIn>1; literal IsAllFirst', ['bitwise/NaN/signed-zero meaning of IsAllFirst', 'CreateConstantWithLayoutUpdated'], []),
        ('iota', 2, 'Iota(original shape,axis0)', 'not Tuple/TOKEN; ElementsIn>1; IsR1Iota', ['Literal::IsR1Iota type/rounding domain', 'Iota finite-width values'], []),
        ('strided-iota', 3, 'Multiply(Iota(original shape,axis0),MakeScalarLike(stride))', 'not Tuple/TOKEN; earlier uniform/iota paths did not return; IsR1StridedIota returns stride', ['Literal::IsR1StridedIota', 'finite-width multiplier conversion and rounding'], [])]:
        add('HandleConstant', slug, ordinal, 'Constant(literal)', rhs, guard, deps, helpers)
    for tuple_operand in (False, True):
        row = add('HandleOptimizationBarrier', 'prune-' + ('tuple' if tuple_operand else 'producer'), 0,
                  'OptimizationBarrier(tuple-valued operand) and its GTE users',
                  'same barrier with projected operand tuple and shape; every GTE tuple index remapped',
                  'barrier Tuple shape and not computation root; every user GTE; direct token elements retained; at least one unused element; operand ' +
                  ('Tuple, retaining unused elements with multiple users, computation-root identity or side effects' if tuple_operand else 'not Tuple, so selected elements obtained through new GTEs'),
                  ['whole graph observation includes user remapping and metadata', 'token/effect reachability', 'index_map -1 entries', 'CopyOriginalValue pruning map', 'MarkAsChanged before later status failure'])
        anchors = [
            ('barrier->ReplaceOperandWithDifferentShape(0, new_operand)', 'operand edge mutation'),
            ('*barrier->mutable_shape() = new_operand->shape();', 'shape assignment'),
            ('CopyOriginalValue(barrier, barrier, index_map);', 'barrier metadata remap'),
            ('CopyOriginalValue(operand, new_operand, index_map);', 'operand metadata remap'),
            ('use->set_tuple_index(index_map[use->tuple_index()]);', 'each user GTE index mutation')]
        body = '\n'.join(source[row['line'] - 1:row['end_line']])
        row['effect_evidence'] = [dict(anchor=anchor, line=row['line'] + body[:body.index(anchor)].count('\n'), role=role)
                                  for anchor, role in anchors]
        row['acceptance_unit'] = 'barrier operand, barrier shape, both metadata maps and every GTE user; not a single replacement call'

    summaries = {
        'ComputeBitcastDimMap': 'walk physical minor-to-major dimensions, accumulating products and matching split/combine groups; unsupported repartition/size paths return nullopt; CHECK/index and overflow obligations remain',
        'InvertBitcastDimMap': 'invert dimension adjacency lists in original physical layout order; depends on input map bounds',
        'ReshapeLayoutDimensions': 'construct candidate minor-to-major layout from paired maps; reject noncontiguous or reordered groups; append unit dimensions; CHECK final size',
        'ValidateTilingOfBitcast': 'accept immediately if either tile list empty; otherwise compare first tile shapes and divisibility/split/combine restrictions while walking minor-to-major order',
        'HasMatchDimensionTile': 'return whether any existing layout tile contains Tile::kMatchDimension',
        'BitcastingOperandOfReshapeOrCopyChain': 'layout-sensitive only; walk copy/reshape operands until virtual ReshapeIsBitcast to original target shape succeeds; otherwise return null',
        'ReplaceWithBitcast': 'one operand required; select provided or original operand; CHECK equal byte sizes; create Bitcast with original output shape; CHECK_OK replacement',
        'BuildTupleConstant': 'recursively rebuild tuple literal structure; leaf literals cloned through layout-updated constants'}
    helpers = []
    for name, summary in summaries.items():
        matches = [f for f in structural['functions'] if name + '(' in f['declarator']]
        assert len(matches) == 1, name
        f = matches[0]
        body = '\n'.join(source[f['line'] - 1:f['end_line']])
        helpers.append(dict(id=name, line=f['line'], end_line=f['end_line'],
                            source_body_sha256=hashlib.sha256(body.encode()).hexdigest(),
                            source_behavior=summary, status='source_inspected_pending_independent_semantic_review'))
    output = dict(schema=1, source_sha256=inventory['source_sha256'], status='partial_source_extraction',
                  denominator_frozen=False, selected_handlers=sorted({c['handler'] for c in cases}),
                  cases=cases, helper_contracts=helpers,
                  limitations=['branch and continuing-stage schemas are not disjoint complete execution paths or a frozen denominator',
                               'primary-agent inspection only; layout algorithms and virtual predicates unproved',
                               'barrier effect evidence includes assignment and user writes outside replacement-site counting',
                               'datatype, tiling, memory space, errors and metadata obligations remain open'])
    validate_batch(output, inventory, source)
    validate_helpers(output, source)
    validate_effect_evidence(output, source, structural)
    (ROOT / 'census/layout-cases.json').write_text(json.dumps(output, indent=2) + '\n')
    print(f'Extracted {len(cases)} layout/constant/barrier schemas across {len(output["selected_handlers"])} handlers/helpers')


if __name__ == '__main__':
    main()
