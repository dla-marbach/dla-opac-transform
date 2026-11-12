# Base Image mit festem Versionstag, Updates über Dependabot.
FROM mcr.microsoft.com/devcontainers/base:2.2.5-trixie

# Java für OpenRefine und Solr, jq/curl/wget für die Pipeline,
# Python und xmllint für Statistik und Validierung (task docs, task validate),
# shellcheck als Linter für scripts/*.sh.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       openjdk-21-jre-headless jq curl wget python3 libxml2-utils shellcheck \
    && rm -rf /var/lib/apt/lists/*

# go-task und yq (mikefarah) mit fester Version und Prüfsumme. Dependabot erfasst
# diese Downloads nicht; Versionen bei Bedarf hier und in .github/workflows/ci.yml
# gemeinsam anheben. Das yq-Paket aus Debian ist ein anderes Werkzeug.
# Architektur des Containers (amd64 oder arm64, z. B. Apple Silicon mit Podman).
ARG TASK_VERSION=3.45.4
ARG TASK_SHA256_AMD64=4367eba04abcbcb407578d18d2439ee32604a872419601abec76a829c797fb82
ARG TASK_SHA256_ARM64=61d773d7a81af2283079e640f14e8aa52a4e793460733a0da37228a283f4ce00
ARG YQ_VERSION=4.48.1
ARG YQ_SHA256_AMD64=99df6047f5b577a9d25f969f7c3823ada3488de2e2115b30a0abb10d9324fd9f
ARG YQ_SHA256_ARM64=0e46b5b926a9e57c526fa2bd8f8e38b7e17fbf6e2403ff1741f3b268e3363a9e
RUN set -e; \
    ARCH="$(dpkg --print-architecture)"; \
    case "$ARCH" in \
      amd64) TASK_SHA256="$TASK_SHA256_AMD64"; YQ_SHA256="$YQ_SHA256_AMD64" ;; \
      arm64) TASK_SHA256="$TASK_SHA256_ARM64"; YQ_SHA256="$YQ_SHA256_ARM64" ;; \
      *) echo "Nicht unterstützte Architektur: $ARCH" >&2; exit 1 ;; \
    esac; \
    curl -fsSL -o /tmp/task.tar.gz "https://github.com/go-task/task/releases/download/v${TASK_VERSION}/task_linux_${ARCH}.tar.gz"; \
    echo "${TASK_SHA256}  /tmp/task.tar.gz" | sha256sum -c -; \
    tar -xzf /tmp/task.tar.gz -C /usr/local/bin task; \
    rm /tmp/task.tar.gz; \
    curl -fsSL -o /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${ARCH}"; \
    echo "${YQ_SHA256}  /usr/local/bin/yq" | sha256sum -c -; \
    chmod +x /usr/local/bin/yq

USER vscode
