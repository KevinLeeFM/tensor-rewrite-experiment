"""Replay the immutable v1 model after its namespace gains additional declarations.

The historical checker's main collected its entire namespace. This adapter keeps
its unchanged fixture, exact 48 certificate set and unchanged result validator.
"""
import json
import subprocess
import check_concatenation as base

OUTPUT='reports/concatenation-base-replay-v2.json'


def main():
    frozen=base.check_inputs()
    for command in (['lake','build','TensorRewriteTheory'],):
        run=subprocess.run(command,cwd=base.ROOT,text=True,capture_output=True)
        assert run.returncode==0,run.stdout+run.stderr
    positive=subprocess.run(['lake','env','lean','tests/fixtures/ConcatenationControls.lean'],
                            cwd=base.ROOT,text=True,capture_output=True)
    assert positive.returncode==0,positive.stdout+positive.stderr
    negative=subprocess.run(['lake','env','lean','tests/fixtures/InvalidConcatenation.lean'],
                            cwd=base.ROOT,text=True,capture_output=True)
    theory=base.read('reports/theory-progress.json')
    for row in theory['files']:assert base.digest(base.ROOT/row['path'])==row['sha256']
    result=base.read('reports/concatenation.json')
    result.update(certificate_axioms={n:theory['axiom_dependencies'][n] for n in frozen['certificates']},
                  control_stdout=positive.stdout+positive.stderr,
                  controls=base.validate_controls(positive.stdout+positive.stderr),
                  invalid_profile_rejections=dict(returncode=negative.returncode,
                    diagnostic=negative.stdout+negative.stderr),
                  replay_scope='immutable v1 subset only; negative extension flags describe v1 scope',
                  replay_adapter='tools/replay_concatenation_base.py')
    base.validate_result(result)
    (base.ROOT/OUTPUT).write_text(json.dumps(result,indent=2)+'\n')
    print('Immutable Concat v1 replay: exact48 certificates and11742 oracle rows; four normal rejections.')


if __name__=='__main__':main()
