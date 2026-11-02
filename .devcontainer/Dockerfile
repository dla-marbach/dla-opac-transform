# Base Image mit festem Versionstag, Updates über Dependabot.
FROM mcr.microsoft.com/devcontainers/base:2.2.5-trixie

# Java für OpenRefine und Solr, jq/curl/wget für die Pipeline,
# Python und xmllint für Statistik und Validierung (task docs, task validate).
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       openjdk-21-jre-headless jq curl wget python3 libxml2-utils \
    && rm -rf /var/lib/apt/lists/*

# go-task und yq (mikefarah) mit fester Version und Prüfsumme. Dependabot erfasst
# diese Downloads nicht; Versionen bei Bedarf hier und in .github/workflows/ci.yml
# gemeinsam anheben. Das yq-Paket aus Debian ist ein anderes Werkzeug.
ARG TASK_VERSION=3.45.4
ARG TASK_SHA256=4367eba04abcbcb407578d18d2439ee32604a872419601abec76a829c797fb82
ARG YQ_VERSION=4.48.1
ARG YQ_SHA256=99df6047f5b577a9d25f969f7c3823ada3488de2e2115b30a0abb10d9324fd9f
RUN curl -fsSL -o /tmp/task.tar.gz "https://github.com/go-task/task/releases/download/v${TASK_VERSION}/task_linux_amd64.tar.gz" \
    && echo "${TASK_SHA256}  /tmp/task.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/task.tar.gz -C /usr/local/bin task \
    && rm /tmp/task.tar.gz \
    && curl -fsSL -o /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64" \
    && echo "${YQ_SHA256}  /usr/local/bin/yq" | sha256sum -c - \
    && chmod +x /usr/local/bin/yq

USER vscode
