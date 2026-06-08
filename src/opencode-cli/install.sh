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

# Install minimal prerequisites
apt-get -y update
apt-get -y install --no-install-recommends curl ca-certificates jq tar

# Fetch version tag
if [ "${CLI_VERSION}" = "latest" ]; then
    CLI_VERSION=$(curl -s https://api.github.com/repos/anomalyco/opencode/releases/latest | jq -r '.tag_name' | sed 's/^v//')
fi

# Detect Architecture
ARCH=$(uname -m)
case "$ARCH" in
    aarch64) ARCH="arm64" ;;
    x86_64)  ARCH="x64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

DOWNLOAD_URL="https://github.com/anomalyco/opencode/releases/download/v${CLI_VERSION#v}/opencode-linux-${ARCH}.tar.gz"

echo "Downloading OpenCode v${CLI_VERSION#v} for ${ARCH}..."
TMP_DIR=$(mktemp -d)
curl -fsSL "${DOWNLOAD_URL}" -o "${TMP_DIR}/opencode.tar.gz"

# Extract the tarball
tar -xzf "${TMP_DIR}/opencode.tar.gz" -C "${TMP_DIR}"

# Move binary to /usr/local/bin
mv "${TMP_DIR}/opencode" /usr/local/bin/opencode
chmod +x /usr/local/bin/opencode

# Cleanup
rm -rf "${TMP_DIR}"
apt-get -y clean
rm -rf /var/lib/apt/lists/*