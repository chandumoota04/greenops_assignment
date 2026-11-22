data "aws_caller_identity" "current" {}

data "aws_iam_role" "codedeploy" {
  name = var.service_role
}

# The bucket is created by scripts/bootstrap-buckets.sh because the Academy
# policy denies s3:GetBucketObjectLockConfiguration, which the aws_s3_bucket
# resource always reads. Its settings are still managed here.
locals {
  release_bucket = "surplus-food-releases-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_public_access_block" "releases" {
  bucket                  = local.release_bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "releases" {
  bucket = local.release_bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bundles older than 30 days are removed so storage does not grow with every
# push; recent ones stay for CodeDeploy rollbacks.
resource "aws_s3_bucket_lifecycle_configuration" "releases" {
  bucket = local.release_bucket

  rule {
    id     = "expire-old-releases"
    status = "Enabled"
    filter {}

    expiration {
      days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

resource "aws_codedeploy_app" "main" {
  name             = "surplus-food"
  compute_platform = "Server"
}

# In-place deployment to the one tagged instance. If any lifecycle hook fails
# (including the health check in ValidateService), CodeDeploy redeploys the
# last successful revision automatically.
resource "aws_codedeploy_deployment_group" "main" {
  app_name               = aws_codedeploy_app.main.name
  deployment_group_name  = "production"
  service_role_arn       = data.aws_iam_role.codedeploy.arn
  deployment_config_name = "CodeDeployDefault.OneAtATime"

  ec2_tag_set {
    ec2_tag_filter {
      key   = "DeployGroup"
      type  = "KEY_AND_VALUE"
      value = "surplus-food"
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}
