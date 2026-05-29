 # Asuli RAG Ingestion Lab

Manifest-driven EPUB ingestion and RAG operations laboratory.

This repository contains the public and shareable components of the ingestion and indexing pipeline used in the Asuli knowledge platform.

The goal is not only to build a Retrieval-Augmented Generation (RAG) system, but also to operate it reliably at scale using manifest-driven workflows, operational recovery mechanisms, validation scripts, and metadata-aware collection management.

---

# Goals

- EPUB ingestion
- Batch processing
- Manifest management
- Chroma integration
- Health monitoring
- Smoke testing
- Operational recovery
- Retrieval quality improvements
- Collection registry management
- Knowledge platform operations

---

# High-Level Architecture

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

# Operational Flow

```text
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
JSONL Chunks
        ↓
add_epub_chunks_to_index_v1.py
        ↓
ChromaDB
        ↓
FastAPI
        ↓
/ask
```

The architecture is intentionally designed around operational reliability.

Instead of treating ingestion as a one-time task, the platform treats ingestion as a repeatable and recoverable operational workflow.

---

# Components

## Scripts

| Script | Purpose | Layer |
|----------|----------|----------|
| ingest_epub_v2.py | Parse a single EPUB and generate chunk files | Parsing |
| add_epub_chunks_to_index_v1.py | Load generated chunks into ChromaDB | Indexing |
| batch_ingest_epubs_v2.sh | Process EPUBs from an inventory file | Batch Engine |
| run_next_epub_batch.sh | Operational entry point for ingestion batches | Operations |
| test_epub_collections_smoke.sh | Validate active EPUB collections | Validation |

---

## Documents

| Document | Purpose |
|-----------|----------|
| EPUB_OPERATION_ARCHITECTURE.md | Operational architecture and workflow documentation |

---

# Repository Structure

```text
asuli-rag-ingestion-lab
│
├── docs
│   └── EPUB_OPERATION_ARCHITECTURE.md
│
├── scripts
│   ├── batch_ingest_epubs_v2.sh
│   ├── run_next_epub_batch.sh
│   └── test_epub_collections_smoke.sh
│
├── examples
│   ├── sample_manifest.txt
│   └── sample_health_output.txt
│
├── README.md
└── LICENSE
```

---

# Quick Start

Run the next ingestion batch:

```bash
MAX=20 DOMAIN=general ./run_next_epub_batch.sh
```

Run collection validation:

```bash
./test_epub_collections_smoke.sh
```

Example health endpoint:

```bash
curl -s http://127.0.0.1:8010/health | jq
```

Example output:

```json
{
  "status": "ok",
  "chunks": 44967,
  "active_collections": 131
}
```

---

# Design Principles

The project is built around several operational principles:

- Manifest-driven processing
- Idempotent ingestion workflows
- Recovery-first design
- Collection registry management
- Metadata-aware retrieval
- Observable batch execution
- Validation before promotion

These principles allow large document collections to be processed incrementally while maintaining operational control.

---

# Current Focus

Building a manifest-driven knowledge operating system for large-scale EPUB and document collections.

Current areas of experimentation include:

- Collection orchestration
- Registry-based routing
- Retrieval optimization
- Metadata ranking
- Evidence-aware answering
- Operational automation

---

# Security Notice

This repository intentionally excludes:

- Private manifests
- Personal notes
- API keys
- Tokens
- Private logs
- Personal brain files
- Internal infrastructure details
- Production configuration

Only public and shareable components are published.

---

# Related Articles

Technical articles describing the architecture, operational lessons, and retrieval strategies used in this project will be linked here as they are published.

Topics include:

- Manifest-driven ingestion
- EPUB operations at scale
- Collection registry architecture
- Metadata-aware retrieval
- Evidence-aware answer generation
- Knowledge Operating Systems
- Operational RAG engineering

---

# License

 

MIT License

Copyright (c) 2026 Ali Elmali

This project is licensed under the MIT License.
See the LICENSE file for details.
