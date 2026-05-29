#!/usr/bin/env bash

# Example batch ingestion script
# Reads EPUB paths from an inventory/manifest file
# Parses each EPUB into JSONL chunks
# Updates collection registry
# Adds chunks into the vector index
# Records success and failure lists

set -u

INV="${1:-epub_inventory_all.txt}"
DOMAIN="${DOMAIN:-general}"
MAX="${MAX:-3}"
LOG="logs/epub_batch_ingest_$(date +%Y%m%d_%H%M).log"
SUCCESS_LIST="./examples/last_epub_batch_success.txt"
FAILED_LIST="./examples/last_epub_batch_failed.txt"
: > "$SUCCESS_LIST"
: > "$FAILED_LIST"

mkdir -p logs

if [ ! -s "$INV" ]; then
  echo "ERROR: inventory file not found or empty: $INV"
  echo "Use: ./batch_ingest_epubs_v2.sh /path/to/existing_epub_inventory.txt"
  exit 1
fi

echo "INVENTORY=$INV" | tee -a "$LOG"
echo "DOMAIN=$DOMAIN" | tee -a "$LOG"
echo "MAX=$MAX" | tee -a "$LOG"

COUNT=0
OK=0
FAIL=0

while IFS= read -r EPUB; do
  [ -z "$EPUB" ] && continue
  [ ! -f "$EPUB" ] && echo "SKIP missing: $EPUB" | tee -a "$LOG" && continue

  COUNT=$((COUNT+1))
  [ "$COUNT" -gt "$MAX" ] && break

  SLUG=$(python3 - << PY
import re
from pathlib import Path
p = Path("$EPUB")
s = p.stem.lower()
s = re.sub(r"[^a-z0-9]+", "-", s).strip("-")
print(s)
PY
)

  COLLECTION="epub-${SLUG}-v2"

  echo
  echo "### [$COUNT] $EPUB" | tee -a "$LOG"
  echo "COLLECTION=$COLLECTION" | tee -a "$LOG"

  if python3 ingest_epub_v2.py "$EPUB" "$COLLECTION" "$DOMAIN" >> "$LOG" 2>&1; then
    JSONL="chunks/${SLUG}_epub_chunks_v2.jsonl"

    if [ ! -s "$JSONL" ]; then
      echo "FAIL jsonl missing: $JSONL" | tee -a "$LOG"
      echo "$EPUB" >> "$FAILED_LIST"
      FAIL=$((FAIL+1))
      continue
    fi

    python3 - << PY >> "$LOG" 2>&1
import json
from pathlib import Path

p = Path("collections_registry.json")
data = json.loads(p.read_text(encoding="utf-8"))

entry = {
    "name": "$COLLECTION",
    "active": True,
    "domain": "$DOMAIN",
    "priority": 5,
    "chunks_file": "${SLUG}_epub_chunks_v2.jsonl"
}

cols = data.get("collections", [])
cols = [c for c in cols if c.get("name") != entry["name"]]
cols.append(entry)
data["collections"] = cols
p.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
print("registry updated:", entry["name"])
PY

    if python3 add_epub_chunks_to_index_v1.py "$JSONL" >> "$LOG" 2>&1; then
      echo "OK indexed: $COLLECTION" | tee -a "$LOG"
      echo "$EPUB" >> "$SUCCESS_LIST"
      OK=$((OK+1))
    else
      echo "FAIL chroma ingest: $COLLECTION" | tee -a "$LOG"
      echo "$EPUB" >> "$FAILED_LIST"
      FAIL=$((FAIL+1))
    fi
  else
    echo "FAIL epub parse: $EPUB" | tee -a "$LOG"
    echo "$EPUB" >> "$FAILED_LIST"
    FAIL=$((FAIL+1))
  fi

done < "$INV"

echo
echo "DONE OK=$OK FAIL=$FAIL LOG=$LOG"
