terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  # Pin the account this configuration is allowed to touch. If the executor's
  # credentials resolve to any other account, Terraform fails before it can
  # create or destroy anything.
  allowed_account_ids = [var.aws_account_id]
}

variable "aws_account_id" {
  type        = string
  description = "AWS account this workspace is allowed to deploy into (atmosly-testing)."
  default     = "767398031518"
}

variable "region" {
  type        = string
  description = "AWS region to deploy into"
  default     = "us-east-2"
}

variable "owner" {
  type        = string
  description = "Probe variable. Surfaces in a tag so variable pass-through is visible in a plan diff."
  default     = "unset"
}

resource "aws_s3_bucket" "qa" {
  bucket_prefix = "atmosly-qa-r2-"

  tags = {
    ManagedBy = "atmosly"
    Purpose   = "infra-management-qa"
    Owner     = var.owner
    CaseThree = "case5-commit-C-STALE-TEST"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.qa.id
}

output "bucket_arn" {
  value = aws_s3_bucket.qa.arn
}

output "owner_seen_by_terraform" {
  value = var.owner
}

# Reports the identity Atmosly's executor actually authenticates as, so the
# account/role in use is visible in the run output rather than assumed.
data "aws_caller_identity" "current" {}

output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "aws_caller_arn" {
  value = data.aws_caller_identity.current.arn
}
