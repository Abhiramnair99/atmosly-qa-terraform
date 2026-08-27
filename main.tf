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
