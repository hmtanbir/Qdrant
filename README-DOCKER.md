# Hardened Qdrant Docker Image

A minimal, secure, and multi-architecture Docker image for [Qdrant](https://qdrant.tech/) vector search engine built on top of a hardened `scratch` container.

## Features

- **Minimal Attack Surface**: Uses a `scratch` base with extracted dynamic `glibc` dependencies.
- **Hardened**: Shells (`sh`, `ash`) are removed to prevent arbitrary shell executions.
- **Multi-Platform Support**: Works on `linux/amd64` and `linux/arm64`.
- **Preconfigured Ports**: Exposes HTTP (`6333`), gRPC (`6334`), and Cluster/P2P (`6335`).

---

## Quick Start

### 1. Build the Docker Image

Build locally using Docker CLI:

```bash
docker build -t hmtanbir/qdrant:latest .
```

To build for a specific Qdrant version:

```bash
docker build --build-arg QDRANT_VERSION=1.19.0 -t hmtanbir/qdrant:1.19.0 .
```

### 2. Multi-Architecture Build (Buildx)

To build and push multi-architecture images (`amd64` and `arm64`):

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t hmtanbir/qdrant:latest \
  --push .
```

---

## Running the Container

### Option A: Using Docker Run

```bash
docker run -d \
  --name qdrant \
  -p 6333:6333 \
  -p 6334:6334 \
  -v qdrant_storage:/qdrant/storage \
  -v qdrant_snapshots:/qdrant/snapshots \
  hmtanbir/qdrant:latest
```

### Option B: Using Docker Compose

Start the service with `docker-compose`:

```bash
docker compose up -d
```

Check status and logs:

```bash
# View container status
docker compose ps

# Follow logs
docker compose logs -f
```

Stop the service:

```bash
docker compose down
```

---

## Port Mappings

| Port | Protocol | Purpose |
|------|----------|---------|
| `6333` | HTTP | REST API & Web Dashboard (`http://localhost:6333/dashboard`) |
| `6334` | gRPC | High-performance gRPC API |
| `6335` | TCP | Distributed cluster & P2P communication |

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `QDRANT__SERVICE__HTTP_PORT` | `6333` | HTTP API port |
| `QDRANT__SERVICE__GRPC_PORT` | `6334` | gRPC API port |
| `QDRANT__SERVICE__API_KEY` | *(optional)* | Set to enable API Key authentication |
| `QDRANT__LOG_LEVEL` | `INFO` | Logging level (`DEBUG`, `INFO`, `WARN`, `ERROR`) |
| `RUN_MODE` | `production` | Runtime mode |

---

## Verification & Healthcheck

Verify that Qdrant is running:

```bash
# Check health status
curl http://localhost:6333/healthz

# Check cluster info / version
curl http://localhost:6333/
```

Access the Web Dashboard in your browser at:
[http://localhost:6333/dashboard](http://localhost:6333/dashboard)
