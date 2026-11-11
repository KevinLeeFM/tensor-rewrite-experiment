"""Regression checks for numerical-refutation category attribution without changing Lean sources."""
import copy
import hashlib
import json
from pathlib import Path
import sys
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
import check_theory as theory
from lean_size import count_source


class TheoryAccountingTests(unittest.TestCase):
    def test_superseding_measurement_preserves_frozen_model_and_total(self):
        addendum=json.loads((theory.ROOT/'census/convolution-ordered-accounting-v1.json').read_text())
        for key in ('superseded_measurement','category_override_manifest'):
            entry=addendum[key]
            self.assertEqual(hashlib.sha256((theory.ROOT/entry['path']).read_bytes()).hexdigest(),
                             entry['sha256'])
        old=json.loads((theory.ROOT/addendum['superseded_measurement']['path']).read_text())
        self.assertEqual(sum(addendum['new_category_lines'].values()),old['new_custom_lean_lines'])
        self.assertEqual(addendum['new_category_lines']['R'],old['new_category_lines']['R']-12)
        self.assertEqual(addendum['new_category_lines']['C'],12)
        self.assertEqual(sum(addendum['total_custom_category_lines'].values()),4165)
        self.assertFalse(addendum['lean_sources_changed'])
        self.assertFalse(addendum['mathematical_statements_changed'])

    def test_floating_refutations_and_private_notation_are_certificates(self):
        path='TensorRewrite/Theory/ConvolutionFloat.lean'
        rows=theory.measure_file(path,'R')
        self.assertEqual([(r['category'],r['code_lines']) for r in rows],[('R',39),('C',12),('R',1)])
        self.assertEqual(sum(r['code_lines'] for r in rows),count_source((theory.ROOT/path).read_text())['code_lines'])
        self.assertEqual(sum(r['physical_lines'] for r in rows),73)
        self.assertEqual(rows[1]['source_region'],dict(first=56,last=71))

    def test_source_drift_or_overlapping_regions_requires_new_measurement(self):
        original=json.loads((theory.ROOT/'census/lean-category-overrides-v1.json').read_text())['files']
        changed=copy.deepcopy(original);changed[0]['sha256']='changed'
        with self.assertRaises(AssertionError):theory.measure_file(original[0]['path'],'R',overrides=changed)
        changed=copy.deepcopy(original);changed[0]['regions'][1]['first']-=1
        with self.assertRaises(AssertionError):theory.measure_file(original[0]['path'],'R',overrides=changed)
        changed=copy.deepcopy(original);changed[0]['regions'][1]['first']+=1
        with self.assertRaises(AssertionError):theory.measure_file(original[0]['path'],'R',overrides=changed)


if __name__=='__main__':unittest.main()
