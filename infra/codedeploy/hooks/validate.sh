#!/bin/bash
# The deployment only succeeds when the new release answers through Nginx.
# A non-zero exit makes CodeDeploy roll back to the last good revision.
set -uo pipefail
expected=$(cat /opt/surplus-food/current/RELEASE)

for _ in $(seq 1 40); do
  body=$(curl -fsS --max-time 3 http://127.0.0.1/api/health || true)
  if [[ "$body" == *'"status":"ok"'* && "$body" == *"\"release\":\"$expected\""* ]]; then
    echo "healthy: $body"
    exit 0
  fi
  sleep 3
done

echo "release $expected did not become healthy; last response: ${body:-none}"
journalctl -u surplus-food -n 40 --no-pager || true
exit 1
