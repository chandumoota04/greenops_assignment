#!/usr/bin/env bash
# Creates the Terraform state bucket and the release bucket once per AWS account.
# Terraform cannot create them itself in AWS Academy (see infra/terraform/deploy.tf).
set -euo pipefail
region="${AWS_REGION:-us-east-1}"
account=$(aws sts get-caller-identity --query Account --output text)

for name in "surplus-food-tfstate-$account" "surplus-food-releases-$account"; do
  if aws s3api head-bucket --bucket "$name" >/dev/null 2>&1; then
    echo "exists: $name"
  else
    aws s3api create-bucket --bucket "$name" --region "$region" >/dev/null
    echo "created: $name"
  fi
  aws s3api put-public-access-block --bucket "$name" --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
done

# State history lets a bad apply be undone.
aws s3api put-bucket-versioning --bucket "surplus-food-tfstate-$account" \
  --versioning-configuration Status=Enabled
