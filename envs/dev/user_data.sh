#!/usr/bin/env bash
# User data for app instances: nginx + node_exporter
set -eux

dnf update -y
dnf install -y nginx wget tar

cat > /usr/share/nginx/html/index.html <<'HTML'
<h1>DTAP Web (dev)</h1><p>ALB → EC2 werkt</p>
HTML

systemctl enable nginx
systemctl restart nginx

# Install node_exporter
NODE_EXPORTER_VERSION="1.8.1"
useradd --no-create-home --shell /sbin/nologin node_exporter || true
cd /tmp
wget -q https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar -xzf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
cp node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
chown node_exporter:node_exporter /usr/local/bin/node_exporter

cat > /etc/systemd/system/node_exporter.service <<'UNIT'
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter --web.listen-address=":9100"
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter


