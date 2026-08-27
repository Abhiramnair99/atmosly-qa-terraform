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
  bucket_prefix = "atmosly-qa-"

  tags = {
    ManagedBy = "atmosly"
    Purpose   = "infra-management-qa"
    Owner     = var.owner
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

# QA CASE 2: plan-time failure probe.
# Init succeeds (config is syntactically valid); plan fails when AWS is queried
# for a bucket that does not exist. Remove after the plan-failure test.
data "aws_s3_bucket" "qa_case2_missing" {
  bucket = "atmosly-qa-does-not-exist-9f3a2c71"
}
