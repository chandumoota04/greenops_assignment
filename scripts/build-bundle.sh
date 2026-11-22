#!/usr/bin/env bash
# Assembles the CodeDeploy bundle from a built jar and frontend:
#   scripts/build-bundle.sh <release-id> <out.zip>
set -euo pipefail
release="$1"; out="$2"
root=$(cd "$(dirname "$0")/.." && pwd)
stage=$(mktemp -d)

cp "$root"/api/target/surplus-food-*.jar "$stage/app.jar"
cp -r "$root/web/dist" "$stage/web"
cp "$root/infra/codedeploy/appspec.yml" "$stage/"
cp -r "$root/infra/codedeploy/hooks" "$stage/hooks"
mkdir "$stage/config"
cp "$root/infra/nginx/nginx.conf" "$root/infra/nginx/surplus-food.conf" "$root/infra/systemd/surplus-food.service" \
  "$root/infra/codedeploy/cloudwatch-agent.json" "$stage/config/"
echo "$release" > "$stage/RELEASE"

rm -f "$out"
(cd "$stage" && zip -qr "$out" .)
rm -rf "$stage"
