terraform {
  required_version = ">= 1.10"

  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 6.0" }
    random = { source = "hashicorp/random", version = "~> 3.7" }
  }

  # The bucket is created once per account by scripts/bootstrap-buckets.sh.
  # use_lockfile locks state in S3 without a DynamoDB table.
  backend "s3" {
    bucket       = "surplus-food-tfstate-337221518279"
    key          = "surplus-food/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = { Project = "surplus-food", ManagedBy = "terraform" }
  }
}
