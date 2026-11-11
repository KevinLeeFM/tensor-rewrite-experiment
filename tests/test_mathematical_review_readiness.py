"""Protect the distinction between reproducibility, semantic review and full-workload success."""
import copy
import hashlib
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
import check_mathematical_review as review
import freeze_mathematical_review as packet


class MathematicalReviewTests(unittest.TestCase):
    def test_replay_cannot_skip_stages_or_claim_semantic_review(self):
        result=json.loads((review.ROOT/review.REPLAY).read_text());review.validate_replay(result)
        changed=copy.deepcopy(result);changed['steps'].pop()
        with self.assertRaises(AssertionError):review.validate_replay(changed)
        for field,value in [('project_artifacts_copied',True),
                            ('project_build_outputs_initially_absent',False),
                            ('independent_semantic_review_performed',True),
                            ('whole_workload_verdict','positive')]:
            changed=copy.deepcopy(result);changed[field]=value
            with self.assertRaises(AssertionError):review.validate_replay(changed)

    def test_replayed_results_are_bound_to_the_committed_baseline(self):
        result=json.loads((review.ROOT/review.REPLAY).read_text())
        changed=copy.deepcopy(result);changed['result_comparisons'][0]['actual_json_sha256']='changed'
        with self.assertRaises(AssertionError):review.validate_replay(changed)
        changed=copy.deepcopy(result);changed['whole_benchmark_records_closed']=488
        with self.assertRaises(AssertionError):review.validate_replay(changed)
        changed=copy.deepcopy(result);changed['packages_after'][0]['revision']='changed'
        with self.assertRaises(AssertionError):review.validate_replay(changed)
        changed=copy.deepcopy(result);changed['registered_declarations']+=1
        with self.assertRaises(AssertionError):review.validate_replay(changed)

    def test_packet_file_pins_survive_a_changed_archive_envelope(self):
        descriptor=json.loads((review.ROOT/review.DESCRIPTOR).read_text())
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder);(root/'reviews/packets').mkdir(parents=True)
            shutil.copyfile(review.ROOT/descriptor['manifest'],root/descriptor['manifest'])
            archive=root/descriptor['archive']
            with zipfile.ZipFile(review.ROOT/descriptor['archive']) as original:
                with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED) as modified:
                    first=original.namelist()[0]
                    for name in original.namelist():
                        data=original.read(name)
                        modified.writestr(name,data+b'changed' if name==first else data)
            descriptor['archive_sha256']=hashlib.sha256(archive.read_bytes()).hexdigest()
            (root/review.DESCRIPTOR).write_text(json.dumps(descriptor))
            with patch.object(packet,'ROOT',root):
                with self.assertRaises(AssertionError):packet.verify()


if __name__=='__main__':unittest.main()
