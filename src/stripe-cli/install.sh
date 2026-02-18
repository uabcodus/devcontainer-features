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
apt-get -y install --no-install-recommends curl ca-certificates jq git

# Fetch latest version if needed
if [ "${CLI_VERSION}" = "latest" ]; then
    CLI_VERSION=$(curl -s https://api.github.com/repos/stripe/stripe-cli/releases/latest | jq -r '.tag_name' | awk '{print substr($1, 2)}')
fi

# Detect current machine architecture
if [ "$(uname -m)" = "aarch64" ]; then
    ARCH="arm64"
else
    ARCH="amd64"
fi

# Download URL with normalized version input
DOWNLOAD_URL="https://github.com/stripe/stripe-cli/releases/download/v${CLI_VERSION#v}/stripe_${CLI_VERSION#v}_linux_${ARCH}.deb"

# Set temporary location for debian binary
tmp=/tmp/stripe.deb

# Download and install stripe
echo "Downloading stripe from ${DOWNLOAD_URL}"
curl -fsSL "${DOWNLOAD_URL}" -o "$tmp" 
apt-get -y install "$tmp"

# Remove binary after installation
rm -f "$tmp"

# Clean up
apt-get -y clean
rm -rf /var/lib/apt/lists/*
