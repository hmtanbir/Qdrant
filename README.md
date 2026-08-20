# Qdrant Vector Database Container

[![Docker Image](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://hub.docker.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A hardened, ultra-lightweight, and multi-arch Docker distribution for **[Qdrant](https://qdrant.tech/)** vector search engine.

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Repository Structure](#repository-structure)
4. [Step-by-Step Setup](#step-by-step-setup)
   - [Step 1: Clone Repository](#step-1-clone-repository)
   - [Step 2: Configure Environment](#step-2-configure-environment)
   - [Step 3: Build & Launch with Docker Compose](#step-3-build--launch-with-docker-compose)
   - [Step 4: Verify Deployment](#step-4-verify-deployment)
5. [Configuration & Customization](#configuration--customization)
6. [Docker Operations Reference](#docker-operations-reference)
7. [License](#license)

---

## Overview

This repository provides automated build definitions and orchestration for running Qdrant in a minimal, attack-surface-reduced container environment built on top of `scratch` with optimized dynamic `glibc` dependencies.

- **HTTP REST & Dashboard**: Port `6333`
- **gRPC API**: Port `6334`
- **Cluster / P2P**: Port `6335`

---

## Prerequisites

- [Docker Engine](https://docs.docker.com/engine/install/) (v20.10 or later)
- [Docker Compose](https://docs.docker.com/compose/) (v2.0 or later) or Docker Buildx

---

## Repository Structure

```text
.
├── Dockerfile            # Multi-stage hardened build definition
├── docker-compose.yml    # Service orchestration and volume definitions
├── README.md             # Project documentation and quick start guide
├── README-DOCKER.md      # Detailed Docker image build and runtime guide
├── LICENSE               # MIT License
└── .gitignore            # Git ignore rules
```

---

## Step-by-Step Setup

### Step 1: Clone Repository

```bash
git clone https://github.com/hmtanbir/qdrant.git
cd qdrant
```

### Step 2: Configure Environment

Review and modify settings in `docker-compose.yml` if needed. For instance, you can enable API Key authentication by setting:

```yaml
environment:
  - QDRANT__SERVICE__API_KEY=your_secure_api_key
```

### Step 3: Build & Launch with Docker Compose

Start the Qdrant service in detached mode:

```bash
docker compose up -d --build
```

### Step 4: Verify Deployment

Check container status:

```bash
docker compose ps
```

Verify the health status via curl:

```bash
curl http://localhost:6333/healthz
```

Open your browser and visit the Qdrant Web Dashboard:
```text
http://localhost:6333/dashboard
```

---

## Configuration & Customization

| Variable | Description | Default |
|----------|-------------|---------|
| `QDRANT_VERSION` | Version of Qdrant release binary | `1.19.0` |
| `QDRANT__SERVICE__HTTP_PORT` | HTTP REST API listening port | `6333` |
| `QDRANT__SERVICE__GRPC_PORT` | gRPC API listening port | `6334` |
| `QDRANT__SERVICE__API_KEY` | Secret key for protecting endpoints | `(none)` |
| `QDRANT__LOG_LEVEL` | Logging verbosity (`INFO`, `DEBUG`, etc.) | `INFO` |

Persistent data volumes:
- `qdrant_storage`: Holds collections and vector data (`/qdrant/storage`)
- `qdrant_snapshots`: Stores collection snapshots and backups (`/qdrant/snapshots`)

---

## Docker Operations Reference

For advanced container options, cross-platform builds, and multi-architecture instructions, see [README-DOCKER.md](file:///Users/hmtanbir/www/hmtanbir/qdrant/README-DOCKER.md).

---

## License

This project is licensed under the [MIT License](LICENSE).
