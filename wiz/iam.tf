# IAM role and instance profile for EC2 instance to allow S3 uploads (MongoDB backups)
resource "aws_iam_role" "ec2_backup_role" {
  name = "${var.environment}-ec2-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.tags, { Name = "${var.environment}-ec2-backup-role" })
}

data "aws_iam_policy_document" "ec2_backup_policy" {
  #checkov:skip=CKV_AWS_356:Allowing wildcard for CloudWatch Logs permissions
  #checkov:skip=CKV_AWS_111:Write access needed for CloudWatch Logs
  statement {
    actions = [
      "s3:PutObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:PutObjectAcl"
    ]

    resources = [
      aws_s3_bucket.mongodb_backups.arn,
      "${aws_s3_bucket.mongodb_backups.arn}/*"
    ]
  }

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ec2_backup_policy_attach" {
  name   = "${var.environment}-ec2-backup-policy"
  role   = aws_iam_role.ec2_backup_role.id
  policy = data.aws_iam_policy_document.ec2_backup_policy.json
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.environment}-instance-profile"
  role = aws_iam_role.ec2_backup_role.name
}
