# Toolchain image for dialectic-playground/hs: Haskell (container-first; see tools/dp-run).
#
# GHC 9.14; build and package tool: cabal.
# Official base image pinned by multi-architecture index digest, plus make and python3 (for the
# curriculum's black-box runner). Dependabot (docker) refreshes the digest; moving to a new
# release line is a deliberate change (keep `make toolchain` and the native CI in step).
FROM docker.io/library/haskell:9.14-slim-bookworm@sha256:9a00205d8e32b54cdc642ae8f37dce1041b87253d43011c22653eb60ad8ce814

RUN apt-get update \
    && apt-get install -y --no-install-recommends make python3 \
    && rm -rf /var/lib/apt/lists/*

ENV DP_IN_CONTAINER=1
