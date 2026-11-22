#!/bin/bash
# EC2 user data: runtime packages and the CodeDeploy agent. The application
# itself arrives later through CodeDeploy.
set -euxo pipefail

dnf install -y java-17-amazon-corretto-headless nginx ruby wget

# The agent installer comes from the regional CodeDeploy bucket.
cd /tmp
wget -q https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
chmod +x install
./install auto
systemctl enable --now codedeploy-agent

useradd --system --home-dir /opt/surplus-food --shell /sbin/nologin surplus || true
mkdir -p /opt/surplus-food/current
systemctl enable nginx
