# Toolchain image for dialectic-playground/hs: Haskell (container-first; see tools/dp-run).
#
# GHC 9.14; build and package tool: cabal; lint: hlint; format: ormolu.
# Official base image pinned by multi-architecture index digest, plus make and python3 (for the
# curriculum's black-box runner). Dependabot (docker) refreshes the digest; moving to a new
# release line is a deliberate change (keep `make toolchain` and the native CI in step).
FROM docker.io/library/haskell:9.14-slim-bookworm@sha256:9a00205d8e32b54cdc642ae8f37dce1041b87253d43011c22653eb60ad8ce814

RUN apt-get update \
    && apt-get install -y --no-install-recommends make python3 curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# hlint and ormolu: the official prebuilt release binaries (building them with cabal takes a
# long time), verified by SHA-256. The native CI installs the same versions (ci.yml), and
# `make toolchain` checks them. Upstream publishes Linux binaries for x86_64 only; on other
# hosts build the image with DP_PLATFORM=linux/amd64.
ARG HLINT_VERSION=3.10
ARG HLINT_SHA256=ccabc8802a58154699a3583b8dddc5ea2e6d65753a62c45c0e80088ebb16b42b
ARG ORMOLU_VERSION=0.9.0.0
ARG ORMOLU_SHA256=367eb4969986504cf171f71f91e24ea5d7d9d97c41701e8e6eef9b642fd0d201
RUN set -eu; \
    arch="$(dpkg --print-architecture)"; \
    [ "$arch" = amd64 ] || { echo "hlint/ormolu: no prebuilt $arch binaries; use DP_PLATFORM=linux/amd64" >&2; exit 1; }; \
    cd /tmp; \
    curl -fsSLo hlint.tar.gz "https://github.com/ndmitchell/hlint/releases/download/v${HLINT_VERSION}/hlint-${HLINT_VERSION}-x86_64-linux.tar.gz"; \
    echo "${HLINT_SHA256}  hlint.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/hlint; \
    tar -xzf hlint.tar.gz -C /opt/hlint --strip-components=1; \
    ln -s /opt/hlint/hlint /usr/local/bin/hlint; \
    curl -fsSLo ormolu.zip "https://github.com/tweag/ormolu/releases/download/${ORMOLU_VERSION}/ormolu-x86_64-linux.zip"; \
    echo "${ORMOLU_SHA256}  ormolu.zip" | sha256sum -c -; \
    python3 -m zipfile -e ormolu.zip /usr/local/bin; \
    chmod 0755 /usr/local/bin/ormolu; \
    rm -f hlint.tar.gz ormolu.zip; \
    hlint --version; ormolu --version

ENV DP_IN_CONTAINER=1
