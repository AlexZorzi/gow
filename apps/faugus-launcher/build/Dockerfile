# syntax=docker/dockerfile:1.4
ARG BASE_APP_IMAGE=ghcr.io/games-on-whales/base-app:edge

######################################
# Build patched bubblewrap that works with CAP_SYS_ADMIN in containers.
# bwrap detects explicit capabilities and aborts; this patch removes that check.
FROM ${BASE_APP_IMAGE} AS bwrap-builder

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /root
COPY ignore_capabilities.patch /root/
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends git meson ca-certificates dpkg-dev && \
    git clone --branch v0.10.0 https://github.com/containers/bubblewrap && \
    cd bubblewrap && \
    ./ci/builddeps.sh && \
    patch -p1 < ../ignore_capabilities.patch && \
    meson _builddir -Dc_std=gnu11 && \
    meson compile -C _builddir

######################################

# hadolint ignore=DL3006
FROM ${BASE_APP_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive

# Install dependencies for faugus-launcher and wine/proton
ARG REQUIRED_PACKAGES=" \
    libfreetype6:i386 \
    libvulkan1 \
    libvulkan1:i386 \
    mesa-vulkan-drivers \
    mesa-vulkan-drivers:i386 \
    wine64 \
    wine32 \
    libasound2-plugins:i386 \
    libsdl2-2.0-0:i386 \
    libdbus-1-3:i386 \
    libsqlite3-0:i386 \
    wine-stable \
    winetricks \
    zenity \
    libnotify4 \
    xdg-utils \
    libsecret-1-0 \
    curl \
    unzip \
    p7zip-full \
    cabextract \
    gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav \
    gstreamer1.0-plugins-base:i386 gstreamer1.0-plugins-good:i386 gstreamer1.0-plugins-bad:i386 gstreamer1.0-plugins-ugly:i386 gstreamer1.0-libav:i386 \
    tar \
    wget \
    ca-certificates \
    xz-utils \
    python3 \
    python3-gi \
    python3-requests \
    python3-pil \
    python3-vdf \
    python3-psutil \
    python3-dbus \
    python3-icoextract \
    libadwaita-1-0 \
    gir1.2-adw-1 \
    libmanette-0.2-0 \
    gir1.2-manette-0.2 \
    libgtk-4-1 \
    gir1.2-gtk-4.0 \
    adwaita-icon-theme \
    librsvg2-common \
    gsettings-desktop-schemas \
    "
ARG CORE_PACKAGES=" \
    lsb-release \
    wget \
    gnupg2 \
    dbus-x11 \
    flatpak \
    sudo \
    "

ARG DE_PACKAGES=" \
    xfce4 \
    xfce4-settings \
    xubuntu-default-settings \
    xubuntu-icon-theme \
    papirus-icon-theme arc-theme \
    at-spi2-core \
    "

ARG ADDITIONAL_PACKAGES=" \
    xfce4-terminal \
    xfce4-taskmanager \
    xfce4-whiskermenu-plugin \
    xfce4-docklike-plugin \
    xarchiver \
    mousepad \
    zip unzip p7zip-full \
    gnome-software gnome-software-plugin-flatpak \
    "

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends $REQUIRED_PACKAGES && \
    # Setup Mozilla official APT repo \
    install -d -m 0755 /etc/apt/keyrings && \
    wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O /etc/apt/keyrings/packages.mozilla.org.asc && \
    echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" > /etc/apt/sources.list.d/mozilla.list && \
    printf 'Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n' > /etc/apt/preferences.d/mozilla && \
    apt-get update && \
    apt-get install -y --no-install-recommends firefox && \
    # Install core, de, and additional apps \
    apt-get install -y $CORE_PACKAGES && \
    apt-get install -y $DE_PACKAGES && \
    apt-get install -y --no-install-recommends $ADDITIONAL_PACKAGES && \
    # Enable multiverse and install steam with its dependencies \
    apt-get install -y --no-install-recommends software-properties-common && \
    add-apt-repository multiverse && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        steam \
        dbus-daemon \
        dbus-system-bus-common \
        dbus-session-bus-common \
        network-manager \
        bluez \
        ibus \
        pciutils \
        mesa-utils \
        libfontconfig1:i386 \
        libfontconfig1:amd64 && \
    # Fix steam updater UI font file \
    ln -sf /usr/share/fonts/truetype/dejavu /usr/share/fonts/truetype/ttf-dejavu && \
    # refresh system font cache \
    fc-cache -f -v && \
    # create symlink for improved decky loader compatibility \
    ln -sf "$HOME" /home/deck && \
    # Clean up foot and temp packages \
    apt-get remove -y foot software-properties-common && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


# Install Faugus Launcher from official GitHub releases (.deb)
RUN <<_INSTALL_FAUGUS
#!/bin/bash
set -e
source /opt/gow/bash-lib/utils.sh

URL=$(curl -fsSL "https://api.github.com/repos/Faugus/faugus-launcher/releases/latest" \
    | jq -r '.assets[] | select(.name | endswith(".deb")) | .browser_download_url' \
    | head -n1)

if [ -z "$URL" ] || [ "$URL" = "null" ]; then
    echo "Failed to resolve Faugus Launcher .deb download URL" >&2
    exit 1
fi

curl -fsSL -o /tmp/faugus-launcher.deb "$URL"
apt-get update
apt-get install -y /tmp/faugus-launcher.deb
rm -f /tmp/faugus-launcher.deb
rm -rf /var/lib/apt/lists/*
_INSTALL_FAUGUS

# Replace system bwrap with patched version that works with CAP_SYS_ADMIN
COPY --from=bwrap-builder --chmod=755 /root/bubblewrap/_builddir/bwrap /usr/bin/bwrap

# Replace launch scripts
COPY --chmod=777 scripts/launch-comp.sh scripts/startup.sh /opt/gow/
COPY --chmod=777 scripts/startdbus.sh /opt/gow/startdbus

# Include default xfce config
COPY --chmod=777 --chown=retro:retro scripts/xfce4 /opt/gow/xfce4

# Fix locales
COPY scripts/locale /etc/default/locale

# Allow anyone to start dbus without password
RUN echo "\nALL ALL=NOPASSWD: /opt/gow/startdbus" >> /etc/sudoers

# Fix bwrap perms for flatpaks
RUN chmod u+s /usr/bin/bwrap

# Configure autostart for Faugus Launcher inside XFCE
RUN mkdir -p /etc/xdg/autostart && \
    ln -s /usr/share/applications/faugus-launcher.desktop /etc/xdg/autostart/faugus-launcher.desktop

ENV XDG_RUNTIME_DIR=/tmp/.X11-unix

ARG IMAGE_SOURCE
LABEL org.opencontainers.image.source=$IMAGE_SOURCE
