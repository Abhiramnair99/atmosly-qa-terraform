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

  # Guard: abort if the executor's credentials resolve to any other account.
  allowed_account_ids = [var.aws_account_id]
}

# ---------------------------------------------------------------------------
# Inputs
# ---------------------------------------------------------------------------

variable "aws_account_id" {
  type        = string
  description = "AWS account this workspace is allowed to deploy into (atmosly-testing)."
  default     = "767398031518"
}

variable "region" {
  type        = string
  description = "AWS region to deploy into."
  default     = "us-east-2"
}

variable "bucket_name" {
  type        = string
  description = "Explicit bucket name. Leave empty to derive one from the account and region."
  default     = ""
}

variable "owner" {
  type        = string
  description = "Probe variable. Surfaces in a tag so variable pass-through is visible in a plan diff."
  default     = "unset"
}

locals {
  # S3 bucket names are globally unique across all AWS accounts, so the account
  # id and region are folded into the name to avoid collisions with anyone else.
  bucket_name = var.bucket_name != "" ? var.bucket_name : "atmosly-qa-${var.aws_account_id}-${var.region}"
}

# Reports the identity the executor actually authenticates as, so the account
# in use is visible in the run output rather than assumed.
data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------
# Bucket
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "qa" {
  bucket = local.bucket_name

  # QA fixture: allows `terraform destroy` to remove the bucket even when it
  # still holds objects. Do not carry this setting into a real environment.
  force_destroy = true

  tags = {
    ManagedBy = "atmosly"
    Purpose   = "infra-management-qa"
    Owner     = var.owner
    Account   = var.aws_account_id
  }
}

# Disables ACLs entirely; the bucket owner owns every object. This is the
# current AWS default for new buckets and is set explicitly so it is not
# left to whatever the account default happens to be.
resource "aws_s3_bucket_ownership_controls" "qa" {
  bucket = aws_s3_bucket.qa.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Blocks every route to making the bucket or its objects publicly readable.
resource "aws_s3_bucket_public_access_block" "qa" {
  bucket = aws_s3_bucket.qa.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "qa" {
  bucket = aws_s3_bucket.qa.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "qa" {
  bucket = aws_s3_bucket.qa.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

output "bucket_name" {
  description = "Name of the bucket that was created."
  value       = aws_s3_bucket.qa.id
}

output "bucket_arn" {
  description = "ARN of the bucket that was created."
  value       = aws_s3_bucket.qa.arn
}

output "bucket_region" {
  description = "Region the bucket actually lives in."
  value       = aws_s3_bucket.qa.region
}

output "aws_account_id" {
  description = "Account the executor authenticated as."
  value       = data.aws_caller_identity.current.account_id
}

output "aws_caller_arn" {
  description = "Full identity ARN the executor authenticated as."
  value       = data.aws_caller_identity.current.arn
}

output "owner_seen_by_terraform" {
  value = var.owner
}
