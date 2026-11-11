from pathlib import Path
import json,unittest,os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
records=json.loads(Path('reports/concatenation-validation-v1/commands.json').read_text())
patterns=next(row['patterns'] for row in records if row.get('exit_code')==0 and 'patterns' in row)+['test_concatenation_family.py']
suite=unittest.TestSuite()
for pattern in patterns:suite.addTests(unittest.defaultTestLoader.discover('tests',pattern=pattern))
log='reports/concatenation-family-validation-v1/curated-tests.log'
with Path(log).open('w') as stream:
 result=unittest.TextTestRunner(verbosity=2,stream=stream).run(suite)
Path('/tmp/concat-family-curated-result.json').write_text(json.dumps(dict(patterns=patterns,exit_code=int(not result.wasSuccessful()),test_count=result.testsRun,log=log),indent=2))
print(result.testsRun,'tests;',len(result.failures),'failures;',len(result.errors),'errors')
raise SystemExit(not result.wasSuccessful())
