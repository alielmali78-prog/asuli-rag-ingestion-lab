
# =====================================================================
# EPUB Operational Architecture
# Added: 2026-05-28
# =====================================================================

# 1. Purpose

This document explains the operational EPUB ingestion architecture used in AE PDF Pilot.

Goal:

- ingest large EPUB collections into RAG
- track processed/broken/pending EPUB files
- support safe batch ingestion
- support operational recovery
- prevent duplicate indexing
- standardize ingestion workflow

This document is intended to be understandable even weeks later.

---

# 2. Core Architecture

MASTER INVENTORY
        ↓
PENDING MANIFEST
        ↓
run_next_epub_batch.sh
        ↓
batch_ingest_epubs_v2.sh
        ↓
ingest_epub_v2.py
        ↓
JSONL chunks
        ↓
add_epub_chunks_to_index_v1.py
        ↓
Chroma Vector DB
        ↓
pdf_pilot_api_v1.py
        ↓
/ask endpoint

---

# 3. Manifest Structure

## 3.1 all_epubs_master_inventory.txt

Purpose:

Master EPUB inventory.

Contains all discovered EPUB files in the system.

Generated with:

find /home/ali \
  -type f \
  -iname "*.epub" \
  2>/dev/null | sort -u \
  > /path/to/rag_manifest/all_epubs_master_inventory.txt

Current size:

- 1616 EPUB files

---

## 3.2 all_epubs_pending_manifest.txt

Purpose:

EPUB files not yet ingested into RAG.

This is the operational queue.

Each successful batch reduces this list.

---

## 3.3 processed_epub_manifest.txt

Purpose:

Successfully ingested EPUB files.

This is the operational success record.

Tracks:

- already indexed EPUBs
- prevents operational confusion
- allows resume-from-last-state workflow

---

## 3.4 broken_epub_manifest.txt

Purpose:

Broken or unparseable EPUB files.

Examples:

- invalid ZIP structure
- missing TOC
- ebooklib parse failure

Example failure:

KeyError:
There is no item named 'OEBPS/toc01.xhtml' in the archive

---

## 3.5 last_epub_batch_20.txt

Purpose:

Tracks the most recent processed batch.

Useful for:

- debugging
- rollback analysis
- failure investigation
- operational visibility

---

# 4. Operational State Model

MASTER
 ├── PROCESSED
 ├── BROKEN
 └── PENDING

Logical model:

MASTER ≈ PROCESSED + BROKEN + PENDING

---

# 5. Main Scripts

## 5.1 ingest_epub_v2.py

Purpose:

Reads a single EPUB file and creates chunk JSONL output.

Input:

- EPUB file
- collection name
- domain

Output:

chunks/<slug>_epub_chunks_v2.jsonl

Example:

python3 ingest_epub_v2.py "book.epub" "epub-book-v2" "general"

Responsibilities:

- EPUB parsing
- chapter extraction
- chunk creation
- metadata generation

---

## 5.2 add_epub_chunks_to_index_v1.py

Purpose:

Adds generated chunk JSONL into Chroma vector database.

Input:

chunks/..._epub_chunks_v2.jsonl

Responsibilities:

- embedding generation
- vector insertion
- duplicate prevention
- replace existing IDs safely

Important:

This script deletes existing IDs before re-adding them.

This prevents uncontrolled index growth.

---

## 5.3 batch_ingest_epubs_v2.sh

Purpose:

Processes EPUB files from a manifest sequentially.

Responsibilities:

- read manifest
- generate collection names
- call ingest_epub_v2.py
- call add_epub_chunks_to_index_v1.py
- update registry
- create logs

Example:

MAX=20 DOMAIN=general ./batch_ingest_epubs_v2.sh manifest.txt

---

## 5.4 run_next_epub_batch.sh

Purpose:

Operational wrapper script (sarmalayıcı kontrol scripti).

This became the main operational entrypoint.

Responsibilities:

- run batch ingestion
- move successful batch into processed manifest
- reduce pending manifest
- update last batch file

Main operational command:

MAX=20 DOMAIN=general ./run_next_epub_batch.sh

This prevents re-processing the same EPUB batch accidentally.

---

## 5.5 test_epub_collections_smoke.sh

Purpose:

Smoke test (temel sağlık testi) for EPUB collections.

Responsibilities:

- find active epub-* collections
- send test queries
- validate source retrieval

Example:

./test_epub_collections_smoke.sh

Validation rule:

sources > 0

means collection is operational.

---

## 5.6 pdf_pilot_api_v1.py

Purpose:

Main FastAPI service.

Responsibilities:

- /health endpoint
- /ask endpoint
- retrieval logic
- summary generation
- evidence scoring

Managed through systemd:

sudo systemctl restart pdf-pilot-api

Health check:

curl -s http://127.0.0.1:8010/health | jq

---

# 6. Current Operational Workflow

Normal daily ingestion:

cd /path/to/asuli-rag-ingestion-lab

MAX=20 DOMAIN=general ./run_next_epub_batch.sh

sudo systemctl restart pdf-pilot-api

sleep 12

curl -s http://127.0.0.1:8010/health | jq '.status, .chunks, (.active_collections | length)'

---

# 7. Smoke Test Strategy

Smoke tests should not run after every batch.

Recommended:

- run smoke test every 100 EPUBs
- run smoke test after major parser changes
- run smoke test after API changes

Command:

./test_epub_collections_smoke.sh

---

# 8. Current System Status

As of 2026-05-28:

API status: ok
Chunks: 17115
Active collections: 54
Processed EPUB: 71
Pending EPUB: 1544
Broken EPUB: 1

---

# 9. Known Limitations

Current ingestion is operational.

However:

book-level summary quality is inconsistent.

Especially problematic:

- anthology books
- HBR-style collections
- fragmented business books
- index-heavy EPUBs

Symptoms:

- random fragments returned
- weak summaries
- intro/praise/index pollution

---

# 10. Future Improvements

Planned future improvements:

## Retrieval Engine Refactor

Potential future file:

retrieval_engine_v2.py

Goals:

- cleaner retrieval pipeline
- modular reranking
- summary composer separation
- evidence quality scoring

---

## Better Summary Pipeline

Needed improvements:

- introduction detection
- anthology detection
- front matter filtering
- praise filtering
- title-page scoring
- semantic reranking
- LLM-based summarization stage

---

# 11. Key Operational Decision

Important architectural decision:

EPUB ingestion is considered operationally solved.

Current focus is:

- scalability
- operational safety
- retrieval quality

NOT basic EPUB parsing anymore.

---

# 12. Long-Term Goal

Final target architecture:

EPUB + PDF + MD

inside a unified RAG ingestion platform.


---

# 2026-05-28 — Offline Embedding Model Fix

## Problem

During EPUB batch ingest, one EPUB failed at Chroma ingest stage:

/home/ali/Downloads/asuli/03. KILLERS OF THE FLOWER MOON by David Grann.epub

The EPUB itself was parsed successfully.

Failure happened while loading SentenceTransformer embedding model.

Error pattern:

Network is unreachable

## Root Cause

add_epub_chunks_to_index_v1.py attempted to reach HuggingFace while loading:

sentence-transformers/all-MiniLM-L6-v2

This is risky in offline/local RAG operations.

## Fix

Changed model loading to offline/local cache mode:

model = SentenceTransformer(
    "sentence-transformers/all-MiniLM-L6-v2",
    device="cpu",
    local_files_only=True
)

## Result

Retry with MAX=1 succeeded.

The failed EPUB was indexed successfully.

## Operational Lesson

Embedding model load must not depend on network access during batch ingest.


---

# 2026-05-29 — Slug Truncation and Failure Tracking Fix

## Problem 1

One EPUB was parsed successfully but failed at JSONL lookup stage:

/home/ali/Downloads/asuli/04. THE TRUMP INDICTMENTS with an introduction, annotations and supporting materials by Melissa Murray and Andrew Weissmann.epub

The ingest script created:

chunks/04-the-trump-indictments-with-an-introduction-annotations-and-supporting-materials-by-melissa-murray-and-andrew-weissmann_epub_chunks_v2.jsonl

But batch_ingest_epubs_v2.sh expected a truncated slug path:

chunks/04-the-trump-indictments-with-an-introduction-annotations-and-supporting-materials-by-meli_epub_chunks_v2.jsonl

## Root Cause

batch_ingest_epubs_v2.sh truncated slug values with:

print(s[:90])

while ingest_epub_v2.py used the full slug.

This caused JSONL lookup mismatch for long EPUB names.

## Fix

Removed slug truncation in batch_ingest_epubs_v2.sh.

Changed:

print(s[:90])

to:

print(s)

## Result

Retry with MAX=1 succeeded.

The Trump Indictments EPUB was indexed successfully.

## Problem 2

FAIL jsonl missing was not always written into last_epub_batch_failed.txt.

This created inconsistency:

DONE OK=18 FAIL=2

but:

FAILED_KEPT_PENDING=1

## Fix

batch_ingest_epubs_v2.sh was updated so jsonl-missing failures are written to:

/path/to/rag_manifest/last_epub_batch_failed.txt

## Operational Lesson

Batch status must be source-of-truth driven by success/failure manifests, not by assumed MAX count.

