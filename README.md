# Asuli RAG Ingestion Lab

Manifest-driven EPUB ingestion and RAG operations lab.

This repository contains the public and shareable components of the ingestion pipeline used in the Asuli PDF Pilot project.

## Goals

- EPUB ingestion
- Batch processing
- Manifest management
- Chroma integration
- Health monitoring
- Smoke testing
- Operational recovery
- Retrieval quality improvements

---

## Architecture

```text
EPUB
 ↓
Manifest
 ↓
Batch Engine
 ↓
Chunking
 ↓
Embedding
 ↓
Chroma
 ↓
Metadata Ranking
 ↓
Retrieval
 ↓
Answer Engine
 ↓
API
```

---

## Components

### Scripts

- ingest_epub_v2.py
- add_epub_chunks_to_index_v1.py
- batch_ingest_epubs_v2.sh
- run_next_epub_batch.sh
- test_epub_collections_smoke.sh

### Documents

- EPUB_OPERATION_ARCHITECTURE.md

---

## Current Focus

Building a manifest-driven knowledge operating system for large-scale EPUB and document collections.

---

## Important

This repository intentionally excludes:

- private manifests
- personal notes
- API keys
- tokens
- private logs
- personal brain files

Only shareable components are published.

---

## Related Articles

Medium articles describing the architecture and operational lessons learned from the project will be linked here.

