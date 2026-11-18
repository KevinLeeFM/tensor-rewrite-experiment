"""Fresh private offline Lean compilations. An optional --spec ends at the frozen spec."""
import os, pathlib, shutil, subprocess, sys, tempfile, time
here = pathlib.Path(__file__).resolve().parent
subprocess.run(["sha256sum", "-c", "SHA256SUMS"], cwd=here, check=True)
files = [here.parent/"reshape-iota-radix"/"RadixSpec.lean", here/"ConvSwapSpec.lean"]
if "--spec" not in sys.argv:
    files += [here/"ConvSwapProof.lean",here/"ConvSwapControls.lean"]
with tempfile.TemporaryDirectory() as tmp:
    for path in files:
        shutil.copy(path, tmp)
        t=time.monotonic()
        p=subprocess.run([os.environ.get("LEAN","lean"),"-o", path.stem+".olean",path.name],
                         cwd=tmp,env={**os.environ,"LEAN_PATH":tmp})
        print(path.stem,round(time.monotonic()-t,3),p.returncode,flush=True)
        p.check_returncode()
