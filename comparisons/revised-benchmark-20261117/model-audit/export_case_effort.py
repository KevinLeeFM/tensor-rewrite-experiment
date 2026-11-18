"""Export the per-case index from the accepted ledger. Shared timings repeat by group."""
import csv
import json
import subprocess
from collections import Counter
from datetime import datetime
from pathlib import Path

here = Path(__file__).resolve().parent
packet = here.parent
ledger = json.loads((packet / "outcome-ledger.json").read_text())
catalog = ledger["reviewed_mathematical_cases"]
effort = catalog["effort"]
cases = catalog["cases"]
sizes = Counter(row.get("effort_group") for row in cases)
durations = (
    "freeze_to_proof_commit_seconds", "freeze_to_proof_seconds",
    "freeze_to_proof_checkpoint_wall_seconds", "freeze_to_candidate_commit_wall_seconds",
    "freeze_to_candidate_commit_seconds", "freeze_to_candidate_seconds",
    "freeze_to_candidate_seconds_from_commits", "candidate_seconds_from_freeze_commit",
)
def commit_pair(info):
    start = info.get("freeze") or info.get("frozen") or info.get("freeze_commit")
    end = info.get("candidate") or info.get("proof_checkpoint") or info.get("proof_commit") or info.get("proof")
    return start, end

def window(info):
    start, end = commit_pair(info)
    if start and start == end:
        return ""
    for key in durations:
        if isinstance(info.get(key), (int, float)):
            return info[key]
    if info.get("freeze_time") and info.get("candidate_time"):
        return (datetime.fromisoformat(info["candidate_time"]) -
                datetime.fromisoformat(info["freeze_time"])).total_seconds()
    if start and end:
        def timestamp(commit):
            return int(subprocess.check_output(["git", "show", "-s", "--format=%at", commit],
                                               cwd=packet, text=True).strip())
        seconds = timestamp(end) - timestamp(start)
        return seconds if seconds > 0 else ""
    return ""

def receipt(row):
    group = row.get("effort_group", "")
    block = effort["continuations"].get(row["catalog"], {})
    groups = block.get("packets", block.get("groups", {}))
    info = groups.get(group, effort["new_packets"].get(group, {}))
    if block.get("group") == group:
        info = block
    return group, info

mapped = {}
for source in ledger["source_candidates"]["records"]:
    for case in source.get("mathematical_case_ids", []):
        mapped.setdefault(case, set()).add(source["id"])

fields = ["case_id", "model_outcome", "source_labels", "additional_source_links", "original", "replacement", "conditions",
          "types", "checked_declaration", "review", "catalog", "effort_group",
          "counted_cases_in_group", "group_freeze_to_candidate_seconds", "proof_or_candidate_commit",
          "active_discovery_seconds", "timing_scope", "overlap", "evidence"]
with (here / "campaign-case-index.csv").open("w", newline="", encoding="utf-8") as stream:
    writer = csv.writer(stream, lineterminator="\n")
    writer.writerow(fields)
    for row in sorted(cases, key=lambda x: x["id"]):
        group, info = receipt(row)
        seconds = window(info)
        timing = ("Group checkpoint window; excludes earlier work and final review. Active time unknown."
                  if seconds != "" else "No normalized checkpoint window. See case and group receipts; active time unknown.")
        writer.writerow([row["id"], row["outcome"], " | ".join(row["source_ids"]),
                         " | ".join(sorted(mapped.get(row["id"], set()) - set(row["source_ids"]))), row["lhs"], row["rhs"],
                         row["conditions"], row["types"], row["theorem"], row["scope_review"], row["catalog"],
                         group, sizes[group] if group else "", seconds,
                         info.get("candidate") or info.get("proof_checkpoint") or info.get("proof_commit") or info.get("proof"),
                         "", timing, row["overlap"], " | ".join(row["evidence"])])
