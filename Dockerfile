# syntax=docker/dockerfile:1

# Step 1: Download statically linked Qdrant release binary and optimize
FROM dhi.io/debian-base:trixie-debian13-dev AS builder

ARG QDRANT_VERSION=1.19.0
ARG TARGETARCH

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    tar \
    binutils \
    && rm -rf /var/lib/apt/lists/*

# Download musl-based static binary for both amd64 & arm64
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        TARBALL="qdrant-x86_64-unknown-linux-musl.tar.gz"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        TARBALL="qdrant-aarch64-unknown-linux-musl.tar.gz"; \
    else \
        echo "Unsupported architecture: $TARGETARCH" && exit 1; \
    fi \
    && mkdir -p /staging/qdrant/storage /staging/qdrant/snapshots /staging/qdrant/config /staging/usr/local/bin /tmp/extract \
    && curl -fSL "https://github.com/qdrant/qdrant/releases/download/v${QDRANT_VERSION}/${TARBALL}" -o /tmp/qdrant.tar.gz \
    && tar -xzf /tmp/qdrant.tar.gz -C /tmp/extract \
    && cp /tmp/extract/qdrant /staging/usr/local/bin/qdrant \
    && chmod +x /staging/usr/local/bin/qdrant \
    && strip --strip-all /staging/usr/local/bin/qdrant || true \
    && if ldd /staging/usr/local/bin/qdrant >/dev/null 2>&1; then \
         for lib in $(ldd /staging/usr/local/bin/qdrant | grep -o '/[^ ]*'); do \
           mkdir -p "/staging$(dirname "$lib")"; \
           cp -L "$lib" "/staging$lib"; \
           strip --strip-unneeded "/staging$lib" || true; \
         done; \
       fi \
    && rm -rf /tmp/qdrant.tar.gz /tmp/extract

# Step 2: Extract base root filesystem
FROM dhi.io/alpine-base:3.24 AS alpine-base

# Step 3: Combine filesystem and clean up unnecessary package manager & shell files
FROM dhi.io/debian-base:trixie-debian13-dev AS combiner
COPY --from=alpine-base / /rootfs/

# Strip shells and package manager metadata to minimize image footprint
RUN rm -rf /rootfs/bin/sh /rootfs/bin/ash \
           /rootfs/lib/apk /rootfs/var/cache/apk /rootfs/etc/apk \
           /rootfs/lib/ld-linux-* /rootfs/lib64/ld-linux-*

COPY --from=builder /staging/ /rootfs/

# Step 4: Final minimal hardened container image
FROM scratch
COPY --from=combiner /rootfs/ /

WORKDIR /qdrant

ENV QDRANT__SERVICE__HTTP_PORT=6333 \
    QDRANT__SERVICE__GRPC_PORT=6334 \
    RUN_MODE=production

# Expose HTTP (6333), gRPC (6334), and P2P/Cluster (6335) ports
EXPOSE 6333 6334 6335

VOLUME ["/qdrant/storage", "/qdrant/snapshots"]

ENTRYPOINT ["/usr/local/bin/qdrant"]
