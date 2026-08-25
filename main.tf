terraform {
  required_version = ">= 1.5"
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

resource "aws_s3_bucket" "qa" {
  bucket_prefix = "atmosly-qa-"

  tags = {
    ManagedBy = "atmosly"
    Purpose   = "infra-management-qa"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.qa.id
}

output "bucket_arn" {
  value = aws_s3_bucket.qa.arn
}
