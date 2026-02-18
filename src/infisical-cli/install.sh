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
apt-get -y install --no-install-recommends curl ca-certificates jq

# Fetch latest version if needed
if [ "${CLI_VERSION}" = "latest" ]; then
    CLI_VERSION=$(curl -s https://api.github.com/repos/infisical/cli/releases/latest | jq -r '.tag_name' | awk '{print substr($1, 2)}')
fi

# Download URL with normalized version input
DDOWNLOAD_URL="https://github.com/Infisical/cli/releases/download/v${CLI_VERSION#v}/infisical_${CLI_VERSION#v}_linux_${ARCH}.deb"

# Set temporary location for debian binary
tmp=/tmp/infisical.deb

# Download and install infisical
echo "Downloading infisical from ${DOWNLOAD_URL}"
curl -sSL "${DOWNLOAD_URL}" -o "$tmp" 
apt-get -y install ./"$tmp"

# Remove binary after installation
rm -f "$tmp"

# Clean up
apt-get -y clean
rm -rf /var/lib/apt/lists/*
