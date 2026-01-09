#!/bin/bash
set -eux

# Basis installaties
DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release jq wget python3-pip

# ==========================================
# DOCKER (via official Docker repo)
# ==========================================
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable docker
systemctl restart docker
usermod -aG docker ubuntu || true

# ==========================================
# AWS CLI (via pip)
# ==========================================
pip3 install awscli

# ==========================================
# GRAFANA (Docker)
# ==========================================
mkdir -p /etc/grafana/provisioning/datasources
mkdir -p /etc/grafana/provisioning/dashboards
mkdir -p /etc/grafana/dashboards
mkdir -p /etc/grafana/data
chown -R 472:472 /etc/grafana || true
chmod -R 775 /etc/grafana || true

# Prometheus datasource
cat > /etc/grafana/provisioning/datasources/prometheus.yaml <<'PROM_DS'
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://host.docker.internal:9090
    isDefault: false
PROM_DS

# CloudWatch datasource
cat > /etc/grafana/provisioning/datasources/cloudwatch.yaml <<'CW_DS'
apiVersion: 1
datasources:
  - name: CloudWatch
    type: cloudwatch
    access: proxy
    isDefault: true
    jsonData:
      authenticationType: arn
      defaultRegion: eu-central-1
      assumeRoleArn: ""
CW_DS

# Dashboard provisioning
cat > /etc/grafana/provisioning/dashboards/dashboard.yaml <<'DASH_PROV'
apiVersion: 1
providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    options:
      path: /etc/grafana/dashboards
DASH_PROV

# run grafana container (recreate if exists)
docker rm -f grafana || true
docker run -d --name grafana \
  --add-host=host.docker.internal:host-gateway \
  -p 3000:3000 \
  -v /etc/grafana/provisioning:/etc/grafana/provisioning \
  -v /etc/grafana/dashboards:/etc/grafana/dashboards \
  -v /etc/grafana/data:/var/lib/grafana \
  -e "GF_SECURITY_ADMIN_USER=admin" \
  -e "GF_SECURITY_ADMIN_PASSWORD=admin" \
  grafana/grafana-oss

# quick status
sleep 5
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}' || true

echo 'INSTALL DONE'
