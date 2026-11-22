#!/bin/bash
# Writes the runtime settings and installs the Nginx and systemd files that
# ship in the bundle, so server config is versioned with the code.
set -euo pipefail
release=$(cat /opt/surplus-food/incoming/RELEASE)
app=/opt/surplus-food/releases/$release
rm -rf "$app"
cp -a /opt/surplus-food/incoming "$app"
export AWS_REGION=us-east-1

db_host=$(aws ssm get-parameter --name /surplus-food/db/host --query Parameter.Value --output text)
db_password=$(aws ssm get-parameter --name /surplus-food/db/password --with-decryption --query Parameter.Value --output text)

# Only root and the service read this file; it holds the database password.
umask 077
cat > /etc/surplus-food.env <<ENV
DB_URL=jdbc:postgresql://${db_host}:5432/surplus?sslmode=require
DB_USER=surplus_app
DB_PASSWORD=${db_password}
APP_RELEASE=$(cat "$app/RELEASE")
ENV
umask 022

install -m 644 "$app/config/nginx.conf" /etc/nginx/nginx.conf
install -m 644 "$app/config/surplus-food.conf" /etc/nginx/conf.d/surplus-food.conf
install -m 644 "$app/config/surplus-food.service" /etc/systemd/system/surplus-food.service
chown -R root:root "$app"
systemctl daemon-reload
nginx -t

# Memory, disk and the Nginx access log go to CloudWatch; EC2 alone reports
# only CPU and network.
rpm -q amazon-cloudwatch-agent >/dev/null || dnf install -y -q amazon-cloudwatch-agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s \
  -c "file:$app/config/cloudwatch-agent.json"
