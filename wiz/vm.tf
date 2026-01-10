# AWS EC2 instance with MongoDB
# Data source for latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Generate SSH key pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer" {
  key_name   = "${var.environment}-deployer-key"
  public_key = tls_private_key.ssh_key.public_key_openssh

  tags = merge(var.tags, { Name = "${var.environment}-ssh-key" })
}

# Security Group for MongoDB
resource "aws_security_group" "mongodb_sg" {
  name        = "${var.environment}-mongodb-sg"
  description = "Allow SSH and MongoDB traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MongoDB"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.environment}-mongodb-sg" })
}

# EC2 Instance
resource "aws_instance" "mongodb" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.mongodb_sg.id]
  key_name               = aws_key_pair.deployer.key_name
  iam_instance_profile   = aws_iam_instance_profile.instance_profile.name

  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true
  }

  user_data = <<-EOF
              #!/bin/bash
              # Initial setup will be done via provisioners
              EOF

  tags = merge(var.tags, { Name = "${var.environment}-mongodb-instance" })

  lifecycle {
    create_before_destroy = false
  }
}

# S3 bucket for MongoDB backups
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "mongodb_backups" {
  bucket = var.ensure_unique_bucket ? "${var.mongodb_backup_sa_name}-${random_id.bucket_suffix.hex}" : var.mongodb_backup_sa_name

  tags = merge(var.tags, {
    Name    = "mongodb-backups"
    Purpose = "MongoDB Backups"
  })
}

resource "aws_s3_bucket_versioning" "mongodb_backups_versioning" {
  bucket = aws_s3_bucket.mongodb_backups.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "mongodb_backups_encryption" {
  bucket = aws_s3_bucket.mongodb_backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "mongodb_backups_access" {
  bucket = aws_s3_bucket.mongodb_backups.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Provisioner to install MongoDB
resource "null_resource" "install_mongodb" {
  depends_on = [aws_instance.mongodb]

  triggers = {
    file_hash = fileexists("${path.module}/scripts/install_mongodb.sh") ? filebase64("${path.module}/scripts/install_mongodb.sh") : ""
    instance  = aws_instance.mongodb.id
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.ssh_key.private_key_pem
    host        = aws_instance.mongodb.public_ip
    timeout     = "10m"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/install_mongodb.sh"
    destination = "/home/ubuntu/install_mongodb.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'MongoDB installation script copied'",
      "chmod 755 /home/ubuntu/install_mongodb.sh",
      "sudo /home/ubuntu/install_mongodb.sh"
    ]
  }
}

# Provisioner to setup backup script
resource "null_resource" "setup_backup" {
  depends_on = [null_resource.install_mongodb]

  triggers = {
    file_hash = fileexists("${path.module}/scripts/backup_mongodb.sh") ? filebase64("${path.module}/scripts/backup_mongodb.sh") : ""
    instance  = aws_instance.mongodb.id
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.ssh_key.private_key_pem
    host        = aws_instance.mongodb.public_ip
    timeout     = "10m"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/backup_mongodb.sh"
    destination = "/home/ubuntu/backup_mongodb.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Backup script copied'",
      "chmod 755 /home/ubuntu/backup_mongodb.sh",
      "sudo apt-get update && sudo apt-get install -y jq",
      "export BUCKET=${aws_s3_bucket.mongodb_backups.id}",
      "export AWS_REGION=${var.region}",
      "echo \"0 */2 * * * BUCKET=${aws_s3_bucket.mongodb_backups.id} AWS_REGION=${var.region} /home/ubuntu/backup_mongodb.sh >> /home/ubuntu/mongo_backup.log 2>&1\" | crontab -",
      "crontab -l",
      "echo 'Backup cron job configured'"
    ]
  }
}