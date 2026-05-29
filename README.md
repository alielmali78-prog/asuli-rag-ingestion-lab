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
Components
Scripts
Script	Purpose	Position in Flow
ingest_epub_v2.py	Single EPUB parse eder ve chunk üretir	Ingestion Layer
add_epub_chunks_to_index_v1.py	Chunk'ları Chroma'ya ekler	Index Layer
batch_ingest_epubs_v2.sh	Manifest içindeki EPUB'ları sırayla işler	Batch Engine
run_next_epub_batch.sh	Operasyonel giriş noktası, batch yönetimi yapar	Operations Layer
test_epub_collections_smoke.sh	EPUB koleksiyon sağlık testi yapar	Validation Layer
Documents
Document	Purpose
EPUB_OPERATION_ARCHITECTURE.md	Operasyonel mimari ve süreç açıklaması
Architecture
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
pdf_pilot_api_v1.py
        ↓
/ask

Bu mimari zaten EPUB_OPERATION_ARCHITECTURE.md içinde tanımlı.

Operational Entry Point

Normal kullanım:

cd ae-pdf-pilot

MAX=20 DOMAIN=general ./run_next_epub_batch.sh

Bu script:

batch'i çalıştırır
processed manifest'i günceller
pending manifest'i küçültür
son işlenen batch'i kaydeder

Bu yüzden operasyonel giriş noktasıdır.

Repository Structure
ae-pdf-pilot/
│
├── scripts
│   ├── ingest_epub_v2.py
│   ├── add_epub_chunks_to_index_v1.py
│   ├── batch_ingest_epubs_v2.sh
│   ├── run_next_epub_batch.sh
│   └── test_epub_collections_smoke.sh
│
├── docs
│   └── EPUB_OPERATION_ARCHITECTURE.md
│
├── chunks/
├── logs/
├── registry/
└── collections/

