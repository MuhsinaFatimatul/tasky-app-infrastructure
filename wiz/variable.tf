variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "mongodb_backup_sa_name" {
  description = "The name to use for the S3 bucket for MongoDB backups (must be globally unique unless ensure_unique_bucket = true)"
  type        = string
  default     = "mongodb-backup-wiz-project"
  validation {
    condition     = length(var.mongodb_backup_sa_name) >= 3 && length(var.mongodb_backup_sa_name) <= 63 && can(regex("^[a-z0-9.-]+$", var.mongodb_backup_sa_name))
    error_message = "mongodb_backup_sa_name must be 3-63 characters and contain only lowercase letters, numbers, dots and hyphens."
  }
}

variable "ensure_unique_bucket" {
  description = "If true, append a short random suffix to mongodb_backup_sa_name to help guarantee global uniqueness."
  type        = bool
  default     = false
}

variable "ECR_name" {
  description = "Name of the ECR repository to create"
  type        = string
  default     = "tasky-app-repo"
}

variable "tags" {
  description = "Common tags to apply to created resources"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "EC2 instance type for MongoDB server"
  type        = string
  default     = "t3.medium"
}

variable "backend_bucket" {
  description = "S3 bucket name for Terraform state"
  type        = string
  default     = "backend-wiz-project-2026"
}

variable "dynamodb_table" {
  description = "DynamoDB table name for Terraform state locks"
  type        = string
  default     = "terraform-locks"
}

variable "create_defender_log_group" {
  description = "Whether to create a new CloudWatch log group for Defender"
  type        = bool
  default     = true
}

variable "defender_log_analytics_workspace_name" {
  description = "Name of the CloudWatch log group for Defender"
  type        = string
  default     = "/aws/CloudWatch/logs"
}

variable "defender_log_retention_days" {
  description = "Retention period in days for Defender logs"
  type        = number
  default     = 30
}

variable "mongodb_backup_prefix" {
  description = "Optional prefix inside the MongoDB backups bucket"
  type        = string
  default     = ""
}

variable "use_existing_vpc" {
  description = "Whether to use an existing VPC instead of creating a new one"
  type        = bool
  default     = false
}

variable "existing_vpc_id" {
  description = "ID of existing VPC to use (required if use_existing_vpc is true)"
  type        = string
  default     = ""
}