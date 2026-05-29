#!/usr/bin/env bash
set -euo pipefail

MAX="${MAX:-20}"
DOMAIN="${DOMAIN:-general}"

PENDING="./examples/all_epubs_pending_manifest.txt"
PROCESSED="./examples/processed_epub_manifest.txt"
FAILED="./examples/failed_chroma_epub_manifest.txt"
SUCCESS_LIST="./examples/last_epub_batch_success.txt"
FAILED_LIST="./examples/last_epub_batch_failed.txt"
LAST="./examples/last_epub_batch_20.txt"

./batch_ingest_epubs_v2.sh "$PENDING"

python3 - << PY
from pathlib import Path

pending = Path("$PENDING")
processed = Path("$PROCESSED")
failed_file = Path("$FAILED")
success_list = Path("$SUCCESS_LIST")
failed_list = Path("$FAILED_LIST")
last = Path("$LAST")

items = [x.strip() for x in pending.read_text(encoding="utf-8").splitlines() if x.strip()]
success = [x.strip() for x in success_list.read_text(encoding="utf-8").splitlines() if x.strip()] if success_list.exists() else []
failed = [x.strip() for x in failed_list.read_text(encoding="utf-8").splitlines() if x.strip()] if failed_list.exists() else []

last.write_text("\\n".join(success + failed) + "\\n", encoding="utf-8")

old_processed = [x.strip() for x in processed.read_text(encoding="utf-8").splitlines() if x.strip()] if processed.exists() else []
pseen = set(old_processed)
new_processed = old_processed[:]
for x in success:
    if x not in pseen:
        new_processed.append(x)
        pseen.add(x)

old_failed = [x.strip() for x in failed_file.read_text(encoding="utf-8").splitlines() if x.strip()] if failed_file.exists() else []
fseen = set(old_failed)
new_failed = old_failed[:]
for x in failed:
    if x not in fseen:
        new_failed.append(x)
        fseen.add(x)

success_set = set(success)
pending_next = [x for x in items if x not in success_set]

processed.write_text("\\n".join(new_processed) + "\\n", encoding="utf-8")
failed_file.write_text("\\n".join(new_failed) + "\\n", encoding="utf-8")
pending.write_text("\\n".join(pending_next) + "\\n", encoding="utf-8")

print("SUCCESS_MARKED_PROCESSED=", len(success))
print("FAILED_KEPT_PENDING=", len(failed))
print("PENDING_LEFT=", len(pending_next))
print("PROCESSED_TOTAL=", len(new_processed))
print("FAILED_TOTAL=", len(new_failed))
PY
