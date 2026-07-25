# syntax=docker/dockerfile:1.4
ARG BASE_APP_IMAGE=ghcr.io/games-on-whales/base-app:fedora

######################################
# Build patched bubblewrap that works with CAP_SYS_ADMIN in containers.
# bwrap detects explicit capabilities and aborts; this patch removes that check.
FROM ${BASE_APP_IMAGE} AS bwrap-builder

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /root
COPY ignore_capabilities.patch /root/
RUN dnf install -y git meson ca-certificates dpkg-dev && \
    (command -v yum || ln -s /usr/bin/dnf /usr/bin/yum) && \
    git clone --branch v0.10.0 https://github.com/containers/bubblewrap && \
    cd bubblewrap && \
    ./ci/builddeps.sh && \
    patch -p1 < ../ignore_capabilities.patch && \
    meson _builddir -Dc_std=gnu11 && \
    meson compile -C _builddir

######################################

# hadolint ignore=DL3006
FROM ${BASE_APP_IMAGE}

# Install RPM Fusion for wine and multimedia codecs
RUN dnf install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Install Wine, 32-bit libs, multimedia, and XFCE desktop packages
RUN dnf install -y \
    freetype.i686 \
    vulkan-loader vulkan-loader.i686 \
    mesa-vulkan-drivers mesa-vulkan-drivers.i686 \
    wine wine.i686 \
    winetricks \
    alsa-plugins-pulseaudio.i686 \
    sdl2-compat.i686 \
    dbus-libs.i686 \
    sqlite-libs.i686 \
    zenity \
    libnotify \
    xdg-utils \
    libsecret \
    curl \
    unzip \
    p7zip \
    cabextract \
    gstreamer1-plugins-base gstreamer1-plugins-good gstreamer1-plugins-bad-free gstreamer1-plugins-ugly-free \
    gstreamer1-plugins-base.i686 gstreamer1-plugins-good.i686 gstreamer1-plugins-bad-free.i686 gstreamer1-plugins-ugly-free.i686 \
    tar \
    wget \
    ca-certificates \
    xz \
    adwaita-icon-theme \
    librsvg2 \
    gsettings-desktop-schemas \
    dbus-x11 \
    flatpak \
    sudo \
    @xfce-desktop-environment \
    xfce4-settings \
    papirus-icon-theme arc-theme \
    at-spi2-core \
    xfce4-terminal \
    xfce4-taskmanager \
    xfce4-whiskermenu-plugin \
    xfce4-docklike-plugin \
    xarchiver \
    mousepad \
    gnome-software \
    dconf \
    firefox \
    steam \
    NetworkManager \
    bluez \
    ibus \
    pkexec \
    pciutils \
    && { dnf remove -y foot 2>/dev/null || true; } \
    && rm -f /etc/xdg/autostart/xscreensaver.desktop \
    && dnf clean all

# The xfce-polkit authentication agent requires systemd-logind.
# Since we run without it, suppress the autostart to avoid errors.
RUN printf '\nHidden=true\n' >> /etc/xdg/autostart/xfce-polkit.desktop

# Register Flathub as a system remote and pre-seed AppStream metadata
RUN flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo \
    && flatpak remote-modify --enable flathub \
    && flatpak --system update --appstream --noninteractive || true

# Make gnome-software prefer flatpak over rpm for app installs
RUN mkdir -p /etc/dconf/db/local.d /etc/dconf/profile \
    && printf 'user-db:user\nsystem-db:local\n' > /etc/dconf/profile/user \
    && printf "[org/gnome/software]\npackaging-format-preference=['flatpak', 'rpm']\n" \
        > /etc/dconf/db/local.d/00-gnome-software-prefer-flatpak \
    && dconf update

# Enable Faugus Launcher Copr and install the package
RUN dnf install -y 'dnf-command(copr)' && \
    dnf copr enable -y faugus/faugus-launcher && \
    dnf install -y faugus-launcher && \
    dnf clean all

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
RUN echo -e "\nALL ALL=NOPASSWD: /opt/gow/startdbus" >> /etc/sudoers

# Fix bwrap perms for flatpaks
RUN chmod u+s /usr/bin/bwrap

# Configure autostart for Faugus Launcher inside XFCE
RUN mkdir -p /etc/xdg/autostart && \
    ln -s /usr/share/applications/faugus-launcher.desktop /etc/xdg/autostart/faugus-launcher.desktop

ENV XDG_RUNTIME_DIR=/tmp/.X11-unix

ARG IMAGE_SOURCE
LABEL org.opencontainers.image.source=$IMAGE_SOURCE
