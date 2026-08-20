# syntax=docker/dockerfile:1.7

# --- Stage 1: Downloader & Staging ---
FROM --platform=$BUILDPLATFORM dhi.io/debian-base:trixie-debian13-dev AS builder

ARG QDRANT_VERSION=1.19.0
ARG QDRANT_WEB_UI_VERSION=v0.2.16
ARG TARGETARCH

# Use BuildKit cache mounts for package manager
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates tar unzip binutils

# Set up non-root user (UID 1000 / standard container UID)
RUN mkdir -p /staging/etc /staging/qdrant/storage /staging/qdrant/snapshots /staging/qdrant/config /staging/qdrant/static /staging/usr/local/bin /staging/tmp \
    && echo "qdrant:x:1000:1000:Qdrant User:/qdrant:/sbin/nologin" > /staging/etc/passwd \
    && echo "qdrant:x:1000:" > /staging/etc/group

# Download & verify Qdrant static binary, default config, and Web UI
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        TARBALL="qdrant-x86_64-unknown-linux-musl.tar.gz"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        TARBALL="qdrant-aarch64-unknown-linux-musl.tar.gz"; \
    else \
        echo "Unsupported architecture: $TARGETARCH" && exit 1; \
    fi \
    && mkdir -p /tmp/extract /tmp/web-ui \
    && curl -fSL "https://github.com/qdrant/qdrant/releases/download/v${QDRANT_VERSION}/${TARBALL}" -o /tmp/qdrant.tar.gz \
    && tar -xzf /tmp/qdrant.tar.gz -C /tmp/extract \
    && cp /tmp/extract/qdrant /staging/usr/local/bin/qdrant \
    && chmod 0755 /staging/usr/local/bin/qdrant \
    && strip --strip-all /staging/usr/local/bin/qdrant || true \
    # Fetch default base config and production config
    && curl -fSL "https://raw.githubusercontent.com/qdrant/qdrant/v${QDRANT_VERSION}/config/config.yaml" -o /staging/qdrant/config/config.yaml \
    && cp /staging/qdrant/config/config.yaml /staging/qdrant/config/production.yaml \
    # Web UI Download & Extraction
    && curl -fSL "https://github.com/qdrant/qdrant-web-ui/releases/download/${QDRANT_WEB_UI_VERSION}/dist-qdrant.zip" -o /tmp/web-ui.zip \
    && unzip -q /tmp/web-ui.zip -d /tmp/web-ui \
    && if [ -d "/tmp/web-ui/dist" ]; then \
         cp -r /tmp/web-ui/dist/* /staging/qdrant/static/; \
       else \
         cp -r /tmp/web-ui/* /staging/qdrant/static/; \
       fi \
    # Copy SSL certificates for TLS / outbound calls
    && cp -r /etc/ssl /staging/etc/ssl \
    # Adjust ownership and permissions
    && chown -R 1000:1000 /staging/qdrant /staging/tmp \
    && chmod 1777 /staging/tmp

# --- Stage 2: Final Minimal & Distroless / Scratch Runtime ---
FROM scratch

# Standard OCI Image Labels
LABEL org.opencontainers.image.title="Qdrant Vector Database" \
      org.opencontainers.image.description="Hardened, ultra-minimal enterprise container for Qdrant" \
      org.opencontainers.image.version="1.19.0" \
      org.opencontainers.image.vendor="hmtanbir" \
      org.opencontainers.image.licenses="MIT"

# Copy rootfs from builder
COPY --from=builder /staging/ /

WORKDIR /qdrant

# Run as non-root user (UID 1000)
USER 1000:1000

ENV QDRANT__SERVICE__HTTP_PORT=6333 \
    QDRANT__SERVICE__GRPC_PORT=6334 \
    RUN_MODE=production

EXPOSE 6333 6334 6335

VOLUME ["/qdrant/storage", "/qdrant/snapshots"]

ENTRYPOINT ["/usr/local/bin/qdrant"]

