#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y python3 python3-apt curl

USER_HOME="/home/ubuntu"
mkdir -p "${USER_HOME}/.ssh"
chmod 700 "${USER_HOME}/.ssh"

cat >> "${USER_HOME}/.ssh/authorized_keys" <<'EOF'
${public_key}
EOF

chmod 600 "${USER_HOME}/.ssh/authorized_keys"
chown -R ubuntu:ubuntu "${USER_HOME}/.ssh"

echo "Ansible slave ready with provided authorized key"
