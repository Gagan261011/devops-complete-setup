#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
SONAR_VERSION="9.9.3.79811"
SONAR_DIR="/opt/sonarqube"
SONAR_USER="sonar"
ADMIN_PASSWORD="${admin_password}"

apt-get update
apt-get install -y openjdk-17-jre-headless unzip wget jq

id -u "${SONAR_USER}" >/dev/null 2>&1 || useradd -m -d "${SONAR_DIR}" -s /bin/bash "${SONAR_USER}"

wget -q "https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SONAR_VERSION}.zip" -O /tmp/sonarqube.zip
unzip -q /tmp/sonarqube.zip -d /opt
mv "/opt/sonarqube-${SONAR_VERSION}" "${SONAR_DIR}"

chown -R "${SONAR_USER}:${SONAR_USER}" "${SONAR_DIR}"

cat >> "${SONAR_DIR}/conf/sonar.properties" <<'EOF'
sonar.web.host=0.0.0.0
sonar.web.port=9000
EOF

cat > /etc/systemd/system/sonarqube.service <<EOF
[Unit]
Description=SonarQube service
After=network.target

[Service]
Type=forking
User=${SONAR_USER}
Group=${SONAR_USER}
ExecStart=${SONAR_DIR}/bin/linux-x86-64/sonar.sh start
ExecStop=${SONAR_DIR}/bin/linux-x86-64/sonar.sh stop
LimitNOFILE=65536
LimitNPROC=4096
TimeoutStartSec=240
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable sonarqube
systemctl start sonarqube

# Wait for SonarQube to be healthy
for i in {1..60}; do
  STATUS=$(curl -s http://localhost:9000/api/system/status | jq -r '.status' || true)
  if [ "${STATUS}" == "UP" ] || [ "${STATUS}" == "OPERATIONAL" ]; then
    break
  fi
  sleep 10
done

# Change default admin password if reachable
curl -s -u admin:admin -X POST 'http://localhost:9000/api/users/change_password' \
  -d "login=admin&previousPassword=admin&password=${ADMIN_PASSWORD}" || true

echo "SonarQube ready on port 9000"
