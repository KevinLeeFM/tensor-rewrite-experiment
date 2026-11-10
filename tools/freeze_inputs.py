"""Fetch immutable experiment inputs; verify the snapshot offline with --check."""
import argparse
import concurrent.futures
import hashlib
import json
from pathlib import Path
import re
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
XLA = "e58e523b11f1fde802a493a776d158007486e1bf"
BASE = "xla/hlo/transforms/simplifiers/"


def fetch(url):
    request = urllib.request.Request(url, headers={"User-Agent": "tensor-rewrite-experiment"})
    with urllib.request.urlopen(request, timeout=60) as response:
        return response.read()


def digest(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    manifest_path = ROOT / "sources/manifest.json"
    if args.check:
        manifest = json.loads(manifest_path.read_text())
        for item in manifest["files"]:
            data = (ROOT / item["path"]).read_bytes()
            assert digest(data) == item["sha256"], item["path"]
        print(f"Verified {len(manifest['files'])} input hashes")
        return
    if manifest_path.exists():
        parser.error("snapshot already exists; use --check, or create an explicitly versioned snapshot")
    items = []

    def save(relative, data, url):
        path = ROOT / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
        items.append({"path": relative, "url": url, "sha256": digest(data), "bytes": len(data)})

    initial = [BASE + name for name in (
        "algebraic_simplifier.cc", "algebraic_simplifier.h",
        "algebraic_simplifier_options.proto", "algebraic_simplifier_test.cc")]
    def get_xla(path):
        url = f"https://raw.githubusercontent.com/openxla/xla/{XLA}/{path}"
        return path, fetch(url), url
    fetched = [get_xla(path) for path in initial]
    # Preserve direct XLA headers as evidence; this is not a transitive build closure.
    includes = set()
    for _, data, _ in fetched:
        includes.update(re.findall(r'#include "(xla/[^"\n]+)"', data.decode()))
    direct = sorted(p for p in includes if p not in initial and not p.endswith('.pb.h'))
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        fetched.extend(pool.map(get_xla, direct))
    for path, data, url in fetched:
        save("sources/xla/" + path, data, url)
    record_url = "https://zenodo.org/api/records/14159871"
    metadata = fetch(record_url)
    save("sources/tensorright/zenodo-14159871.json", metadata, record_url)
    record = json.loads(metadata)
    for file in record["files"]:
        assert file["size"] < 10_000_000, "review large artifact before downloading"
        url = file["links"]["self"]
        data = fetch(url)
        algorithm, expected = file["checksum"].split(":", 1)
        assert hashlib.new(algorithm, data).hexdigest() == expected
        relative = "sources/tensorright/" + file["key"]
        save(relative, data, url)
        with zipfile.ZipFile(ROOT / relative) as archive:
            for entry in archive.infolist():
                if entry.is_dir():
                    continue
                name = Path(entry.filename)
                assert not name.is_absolute() and ".." not in name.parts
                assert entry.file_size < 10_000_000
                save("sources/tensorright/artifact/" + entry.filename,
                     archive.read(entry), url + "#" + entry.filename)
    toolchain = "leanprover/lean4:v4.35.0\n"
    (ROOT / "lean-toolchain").write_text(toolchain)
    manifest = {"schema": 1, "xla_commit": XLA, "lean_toolchain": toolchain.strip(),
                "historical_artifact": "10.5281/zenodo.14159871",
                "xla_dependency_scope": "target, header, options, tests, and their direct non-generated XLA headers",
                "files": sorted(items, key=lambda item: item["path"])}
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Preserved {len(items)} files")


if __name__ == "__main__":
    main()
