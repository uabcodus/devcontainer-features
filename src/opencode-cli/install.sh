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
apt-get -y install --no-install-recommends curl ca-certificates tar

# Detect Architecture
ARCH=$(uname -m)
case "$ARCH" in
    aarch64|arm64) ARCH="arm64" ;;
    x86_64|amd64)  ARCH="x64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Build the download URL from the official OpenCode binary endpoints
if [ "${CLI_VERSION}" = "latest" ]; then
    DOWNLOAD_URL="https://opencode.ai/update/api/latest/cli/opencode/opencode-linux-${ARCH}.tar.gz"
    echo "Downloading latest OpenCode for ${ARCH}..."
else
    CLI_VERSION="${CLI_VERSION#v}"
    DOWNLOAD_URL="https://opencode.ai/files/bin/${CLI_VERSION}/opencode-linux-${ARCH}.tar.gz"
    echo "Downloading OpenCode v${CLI_VERSION} for ${ARCH}..."
fi

TMP_DIR=$(mktemp -d)
ARCHIVE="${TMP_DIR}/opencode.tar.gz"

# The archive is large and the CDN can reset or stall long downloads. Retry
# failed attempts and resume from the already downloaded bytes.
attempt=1
max_attempts=5
while [ "${attempt}" -le "${max_attempts}" ]; do
    if curl -fsSL --connect-timeout 15 --speed-limit 1024 --speed-time 60 \
        -C - "${DOWNLOAD_URL}" -o "${ARCHIVE}"; then
        break
    fi

    # A resumed request can fail with HTTP 416 when the archive is already
    # complete, so verify the file before deciding to retry.
    if [ -s "${ARCHIVE}" ] && tar -tzf "${ARCHIVE}" >/dev/null 2>&1; then
        break
    fi

    if [ "${attempt}" -eq "${max_attempts}" ]; then
        echo "Failed to download OpenCode after ${max_attempts} attempts." >&2
        exit 1
    fi

    echo "Download failed (attempt ${attempt}/${max_attempts}); retrying..." >&2
    attempt=$((attempt + 1))
    sleep 3
done

# Extract the tarball
tar -xzf "${ARCHIVE}" -C "${TMP_DIR}"

# Move binary to /usr/local/bin
mv "${TMP_DIR}/opencode" /usr/local/bin/opencode
chmod +x /usr/local/bin/opencode

TARGET_USER="${_REMOTE_USER:-vscode}"
TARGET_HOME="${_REMOTE_USER_HOME:-/home/vscode}"

# Pre-create dirs with correct ownership so Docker bind mounts
# don't create parent dirs as root (which would cause EACCES)
mkdir -p "${TARGET_HOME}/.config/opencode" \
         "${TARGET_HOME}/.local/share/opencode" \
         "${TARGET_HOME}/.local/state"
chown -R "${TARGET_USER}:${TARGET_USER}" \
         "${TARGET_HOME}/.config" \
         "${TARGET_HOME}/.local"

# Cleanup
rm -rf "${TMP_DIR}"
apt-get -y clean
rm -rf /var/lib/apt/lists/*