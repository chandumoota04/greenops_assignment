#!/usr/bin/env bash
# Manual recovery: redeploys an earlier release bundle that is still in S3.
# CodeDeploy already rolls back on its own when a hook fails; this is for a
# release that passed its checks but turned out to be faulty.
#   scripts/rollback.sh            -> list the releases available
#   scripts/rollback.sh <release>  -> deploy that release and wait for it
set -euo pipefail
export AWS_REGION="${AWS_REGION:-us-east-1}"
account=$(aws sts get-caller-identity --query Account --output text)
bucket="surplus-food-releases-$account"

if [ $# -eq 0 ]; then
  aws s3 ls "s3://$bucket/releases/" | sort
  exit 0
fi

id=$(aws deploy create-deployment --application-name surplus-food --deployment-group-name production \
  --s3-location "bucket=$bucket,key=releases/$1.zip,bundleType=zip" \
  --description "Manual rollback to $1" --query deploymentId --output text)
echo "deployment $id: rolling back to $1"
aws deploy wait deployment-successful --deployment-id "$id"
echo "done; health: $(curl -fsS "$(cd "$(dirname "$0")/../infra/terraform" && terraform output -raw app_url)/api/health")"
