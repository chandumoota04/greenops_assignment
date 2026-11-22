#!/usr/bin/env bash
# Post-deploy check against the public URL:
#   scripts/smoke-test.sh <base-url> <expected-release>
# Covers health + release, the page and a deep link, CRUD on a throwaway batch,
# and a 422 for invalid input. The throwaway batch is always deleted.
set -euo pipefail
base="${1%/}"; release="$2"
pass=0
ok() { pass=$((pass + 1)); printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; exit 1; }

health=$(curl -fsS --max-time 10 "$base/api/health")
[[ "$health" == *'"status":"ok"'* && "$health" == *"\"release\":\"$release\""* ]] && ok "health reports release $release" || fail "health: $health"

curl -fsS --max-time 10 "$base/" | grep -q '<div id="root">' && ok "home page served" || fail "home page"
curl -fsS --max-time 10 "$base/batches/new" | grep -q '<div id="root">' && ok "deep link served" || fail "deep link"

expiry=$(date -u -d '+3 days' +%F 2>/dev/null || date -u -v+3d +%F)
body=$(curl -fsS --max-time 10 -H 'Content-Type: application/json' \
  -d "{\"itemName\":\"Smoke test $release\",\"quantity\":1,\"unit\":\"items\",\"expiryDate\":\"$expiry\"}" \
  "$base/api/batches")
id=$(sed -E 's/.*"id":([0-9]+).*/\1/' <<<"$body")
[[ "$id" =~ ^[0-9]+$ ]] && ok "create batch $id" || fail "create: $body"
trap 'curl -s -o /dev/null -X DELETE "$base/api/batches/$id"' EXIT

curl -fsS --max-time 10 "$base/api/batches/$id" | grep -q "Smoke test $release" && ok "read batch" || fail "read"
curl -fsS --max-time 10 -X PUT -H 'Content-Type: application/json' \
  -d "{\"itemName\":\"Smoke test $release\",\"quantity\":2,\"unit\":\"packs\",\"expiryDate\":\"$expiry\"}" \
  "$base/api/batches/$id" | grep -q '"unit":"packs"' && ok "update batch" || fail "update"
[[ $(curl -s -o /dev/null -w '%{http_code}' -X DELETE "$base/api/batches/$id") == 204 ]] && ok "delete batch" || fail "delete"
trap - EXIT
[[ $(curl -s -o /dev/null -w '%{http_code}' "$base/api/batches/$id") == 404 ]] && ok "deleted batch is gone" || fail "still there"

code=$(curl -s -o /dev/null -w '%{http_code}' -H 'Content-Type: application/json' \
  -d '{"itemName":"x","quantity":0,"unit":"gallons","expiryDate":"2026-02-30"}' "$base/api/batches")
[[ "$code" == 422 ]] && ok "invalid input rejected with 422" || fail "invalid input gave $code"

echo "$pass checks passed"
