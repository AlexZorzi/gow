# syntax=docker/dockerfile:1.4
ARG BASE_APP_IMAGE=ghcr.io/games-on-whales/base-app:edge

# hadolint ignore=DL3006
FROM ${BASE_APP_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
ENV APPIMAGE_EXTRACT_AND_RUN=1

# Downloading Eden Emulator AppImage.
RUN <<_INSTALL_EDEN
#!/bin/bash
set -e
echo "**** Downloading Eden Emulator AppImage ****"
mkdir -p /Applications
wget --tries=5 --waitretry=2 --timeout=30 -O /Applications/eden.AppImage "https://stable.eden-emu.dev/v0.2.1/Eden-Linux-v0.2.1-amd64-clang-pgo.AppImage"
chmod -v 777 /Applications/eden.AppImage
chmod -v a+x /Applications/eden.AppImage
_INSTALL_EDEN

COPY --chmod=777 scripts/startup.sh /opt/gow/startup-app.sh

ENV XDG_RUNTIME_DIR=/tmp/.X11-unix

ARG IMAGE_SOURCE
LABEL org.opencontainers.image.source=$IMAGE_SOURCE
