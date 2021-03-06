#!/bin/bash

# Exit script if return code != 0
set -e

pacman_cleanup() {
    yes | pacman -Scc
    rm -rf /usr/share/locale/*
    rm -rf /usr/share/man/*
    rm -rf /tmp/*
}

aur_start() {
    # Install packages that all PKGBUILDs automatically assume are installed
    # Also install ed, it's a build-time dependency of runit
    pacman -S --needed --noconfirm base-devel ed
    # Create "makepkg-user" user for building packages, as we can't and shouldn't
    # build packages as root (although we're effectively root all the time when
    # interacting with docker, so it's a bit of a moot point...)
    useradd -m -s /bin/bash makepkg-user
    echo -e "makepkg-password\nmakepkg-password" | passwd makepkg-user
}

aur_finish() {
    # Remove "makepkg-user" - we don't want unnecessary users lying around in the image
    userdel -r makepkg-user
    # Remove base-devel packages, except a few useful core packages
    pacman -Ru --noconfirm $(pacman -Qgq base-devel | grep -v pacman | grep -v sed | grep -v grep | grep -v gzip)
    # Remove ed
    pacman -Ru --noconfirm ed
}

aur_build() {
    local pkg=$1

    # Download and extract package files from AUR
    local tar_path="/tmp/${pkg}.tar.gz"
    curl -s -L -o ${tar_path} "https://aur.archlinux.org/cgit/aur.git/snapshot/${pkg}.tar.gz"
    tar xvf ${tar_path} -C /tmp
    chmod a+rwx /tmp/${pkg}

    # Build and install package
    su -c "cd /tmp/${pkg} && makepkg" - makepkg-user
    pacman -U /tmp/${pkg}/${pkg}-*-x86_64.pkg.tar.xz --noconfirm
}
