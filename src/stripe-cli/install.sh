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

# Add Stripe CLI’s GPG key to the apt sources keyring
curl -s https://packages.stripe.dev/api/security/keypair/stripe-cli-gpg/public | gpg --dearmor | sudo tee /usr/share/keyrings/stripe.gpg

# Add CLI’s apt repository to the apt sources list
echo "deb [signed-by=/usr/share/keyrings/stripe.gpg] https://packages.stripe.dev/stripe-cli-debian-local stable main" | sudo tee -a /etc/apt/sources.list.d/stripe.list

# Update the package list
apt-get -y update

# Install latest or selected version
if [ "${CLI_VERSION}" = "latest" ]; then
    apt-get -y install stripe
else
    # Normalize version input: accept v1.2.0 or 1.2.0 -> remove leading v
    apt-get -y install "stripe=v${CLI_VERSION#v}"
fi

# Clean up
apt-get -y clean
rm -rf /var/lib/apt/lists/*
