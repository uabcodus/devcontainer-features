#!/bin/sh

set -e

CLI_VERSION="${VERSION:-"latest"}"

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Bring in ID, ID_LIKE, VERSION_ID, VERSION_CODENAME
. /etc/os-release

# Get an adjusted ID independent of distro variants
if [ "${ID}" != "debian" ] && [ "${ID_LIKE}" != "debian" ]; then
    echo "Linux distro ${ID} not supported."
    exit 1
fi

# Install prerequisites
apt-get -y update
apt-get -y install --no-install-recommends curl ca-certificates unzip

# Install Bun binary latest or selected version
if [ "${CLI_VERSION}" = "latest" ]; then
    curl -fsSL https://bun.com/install | bash
else
    # Normalize version input: accept v1.2.0 or 1.2.0 -> remove leading v
    curl -fsSL https://bun.com/install | bash -s "bun-v${CLI_VERSION#v}"
fi

# Clean up
apt-get -y clean
rm -rf /var/lib/apt/lists/*
