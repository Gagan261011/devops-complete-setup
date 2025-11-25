#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

REPO_URL="${repo_url}"
SONAR_URL="${sonar_url}"
NEXUS_URL="${nexus_url}"
ANSIBLE_MASTER_IP="${ansible_master_ip}"
ANSIBLE_SLAVE_IP="${ansible_slave_ip}"
APP_SERVER_IP="${app_server_ip}"
NEXUS_REPO_NAME="${nexus_repo_name}"

apt-get update
apt-get install -y openjdk-17-jdk gnupg curl git maven unzip ansible python3-pip

curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee \
  /usr/share/keyrings/jenkins-keyring.asc >/dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | tee \
  /etc/apt/sources.list.d/jenkins.list >/dev/null

apt-get update
apt-get install -y jenkins

# Stop Jenkins during bootstrap to avoid racing JCasC/plugin install
systemctl stop jenkins || true

# Clone repo holding Jenkinsfile and JCasC
mkdir -p /opt/devops-lab
if [ ! -d "/opt/devops-lab/.git" ]; then
  git clone "${REPO_URL}" /opt/devops-lab
else
  cd /opt/devops-lab
  git pull --rebase || true
fi
chown -R jenkins:jenkins /opt/devops-lab

# Configure Jenkins service environment
cat >> /etc/default/jenkins <<EOF
JAVA_ARGS="\$JAVA_ARGS -Djenkins.install.runSetupWizard=false -Dcasc.jenkins.config=/opt/devops-lab/jenkins/jenkins-casc.yaml"
CASC_JENKINS_CONFIG=/opt/devops-lab/jenkins/jenkins-casc.yaml
SONAR_HOST_URL=${SONAR_URL}
NEXUS_HOST_URL=${NEXUS_URL}
ANSIBLE_MASTER_IP=${ANSIBLE_MASTER_IP}
ANSIBLE_SLAVE_IP=${ANSIBLE_SLAVE_IP}
APP_SERVER_IP=${APP_SERVER_IP}
REPO_URL=${REPO_URL}
NEXUS_REPO_NAME=${NEXUS_REPO_NAME}
EOF

cat > /etc/profile.d/jenkins-vars.sh <<EOF
export SONAR_HOST_URL=${SONAR_URL}
export NEXUS_HOST_URL=${NEXUS_URL}
export ANSIBLE_MASTER_IP=${ANSIBLE_MASTER_IP}
export ANSIBLE_SLAVE_IP=${ANSIBLE_SLAVE_IP}
export APP_SERVER_IP=${APP_SERVER_IP}
export REPO_URL=${REPO_URL}
export NEXUS_REPO_NAME=${NEXUS_REPO_NAME}
EOF

# Place Ansible SSH key for Jenkins credentials (referenced as file)
mkdir -p /var/lib/jenkins/.ssh
cat > /var/lib/jenkins/.ssh/ansible <<'EOF'
${ansible_private_key}
EOF
chown -R jenkins:jenkins /var/lib/jenkins/.ssh
chmod 600 /var/lib/jenkins/.ssh/ansible

# Preinstall essential plugins
jenkins-plugin-cli --plugins \
  "configuration-as-code job-dsl git workflow-aggregator ansicolor credentials-binding ssh-credentials ssh-agent sonar maven-plugin pipeline-utility-steps nexus-artifact-uploader"

systemctl enable jenkins
systemctl restart jenkins

echo "Jenkins bootstrap complete"
