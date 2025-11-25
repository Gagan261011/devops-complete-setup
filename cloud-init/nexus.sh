#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
NEXUS_VERSION="3.68.1-02"
NEXUS_HOME="/opt/nexus"
NEXUS_DATA="/opt/sonatype-work"
NEXUS_USER="nexus"
ADMIN_PASSWORD="${admin_password}"
REPO_NAME="${repo_name}"

apt-get update
apt-get install -y openjdk-17-jre-headless wget tar jq

id -u "${NEXUS_USER}" >/dev/null 2>&1 || useradd -m -d "${NEXUS_HOME}" -s /bin/bash "${NEXUS_USER}"

wget -q "https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-unix.tar.gz" -O /tmp/nexus.tar.gz
mkdir -p "${NEXUS_HOME}"
tar -xzf /tmp/nexus.tar.gz -C /opt
mv "/opt/nexus-${NEXUS_VERSION}" "${NEXUS_HOME}/nexus-${NEXUS_VERSION}"
ln -s "${NEXUS_HOME}/nexus-${NEXUS_VERSION}" "${NEXUS_HOME}/latest"

chown -R "${NEXUS_USER}:${NEXUS_USER}" "${NEXUS_HOME}" "${NEXUS_DATA}"

echo "run_as_user=${NEXUS_USER}" > "${NEXUS_HOME}/latest/bin/nexus.rc"

cat > /etc/systemd/system/nexus.service <<EOF
[Unit]
Description=nexus service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
User=${NEXUS_USER}
Group=${NEXUS_USER}
ExecStart=${NEXUS_HOME}/latest/bin/nexus start
ExecStop=${NEXUS_HOME}/latest/bin/nexus stop
Restart=on-abort
TimeoutStartSec=240

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable nexus
systemctl start nexus

# Wait for Nexus to respond
for i in {1..60}; do
  if curl -s "http://localhost:8081/service/rest/v1/status" | jq -e '.state' >/dev/null 2>&1; then
    break
  fi
  sleep 10
done

INITIAL_PASSWORD_FILE="${NEXUS_DATA}/nexus3/admin.password"
if [ -f "${INITIAL_PASSWORD_FILE}" ]; then
  INITIAL_PASSWORD=$(cat "${INITIAL_PASSWORD_FILE}")
else
  INITIAL_PASSWORD="admin123"
fi

# Update admin password
curl -s -X PUT -u admin:"${INITIAL_PASSWORD}" \
  -H "Content-Type: text/plain" \
  "http://localhost:8081/service/rest/v1/security/users/admin/change-password" \
  -d "${ADMIN_PASSWORD}" || true

# Create hosted Maven repo if missing
curl -s -o /tmp/repos.json -u admin:"${ADMIN_PASSWORD}" "http://localhost:8081/service/rest/v1/repositories"
if ! grep -q "\"name\" *: *\"${REPO_NAME}\"" /tmp/repos.json; then
  curl -s -X POST -u admin:"${ADMIN_PASSWORD}" \
    -H "Content-Type: application/json" \
    "http://localhost:8081/service/rest/v1/repositories/maven/hosted" \
    -d "{
          \"name\": \"${REPO_NAME}\",
          \"online\": true,
          \"storage\": {\"blobStoreName\": \"default\", \"strictContentTypeValidation\": true, \"writePolicy\": \"ALLOW\"},
          \"cleanup\": {\"policyNames\": []},
          \"component\": {\"proprietaryComponents\": true},
          \"maven\": {\"versionPolicy\": \"RELEASE\", \"layoutPolicy\": \"STRICT\", \"contentDisposition\": \"INLINE\"}
        }"
fi

echo "Nexus ready on port 8081 with repo ${REPO_NAME}"
