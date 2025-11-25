#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y ansible git curl

USER_HOME="/home/ubuntu"
REPO_DIR="/opt/devops-lab"

# Prepare SSH for the ubuntu user using the provided keypair
mkdir -p "${USER_HOME}/.ssh"
chmod 700 "${USER_HOME}/.ssh"

cat > "${USER_HOME}/.ssh/id_rsa" <<'EOF'
${private_key}
EOF
chmod 600 "${USER_HOME}/.ssh/id_rsa"

cat > "${USER_HOME}/.ssh/id_rsa.pub" <<'EOF'
${public_key}
EOF
chmod 644 "${USER_HOME}/.ssh/id_rsa.pub"

cat "${USER_HOME}/.ssh/id_rsa.pub" >> "${USER_HOME}/.ssh/authorized_keys"
chmod 600 "${USER_HOME}/.ssh/authorized_keys"

cat > "${USER_HOME}/.ssh/config" <<'EOF'
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
EOF
chmod 600 "${USER_HOME}/.ssh/config"
chown -R ubuntu:ubuntu "${USER_HOME}/.ssh"

# Clone or update the repo with playbooks and roles
if [ ! -d "${REPO_DIR}/.git" ]; then
  git clone "${repo_url}" "${REPO_DIR}"
else
  cd "${REPO_DIR}"
  git pull --rebase || true
fi

chown -R ubuntu:ubuntu "${REPO_DIR}"

# Write inventory so this host can reach slave and app server privately
cat > "${REPO_DIR}/ansible/inventory.ini" <<EOF
[ansible_slave]
${ansible_slave_ip}

[app_server]
${app_server_ip}
EOF

chown ubuntu:ubuntu "${REPO_DIR}/ansible/inventory.ini"

echo "Ansible master bootstrap complete"
