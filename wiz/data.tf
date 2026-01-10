# Returns the AWS account information (account ID, ARN, user id)
data "aws_caller_identity" "current" {}

# Lookup an existing CloudWatch Log Group by name when create_defender_log_group is false.
data "aws_cloudwatch_log_group" "existing_cloudwatch_log_group" {
  count = var.create_defender_log_group ? 0 : 1
  name  = var.defender_log_analytics_workspace_name
}

# Optionally create a CloudWatch Log Group with the given name (useful if you want Terraform to ensure it exists).
resource "aws_cloudwatch_log_group" "defender" {
  count             = var.create_defender_log_group ? 1 : 0
  name              = var.defender_log_analytics_workspace_name
  retention_in_days = var.defender_log_retention_days

  tags = merge({
    Name = var.defender_log_analytics_workspace_name
  }, var.tags)
}