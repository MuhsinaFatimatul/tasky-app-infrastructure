########################################
# TERRAFORM + PROVIDER
########################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.30"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

########################################
# VPC + SUBNETS + NAT
########################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name = "demo-eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Environment = "Production"
  }
}

########################################
# EKS CLUSTER + NODE GROUPS
########################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name    = "demo-eks"
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Private cluster (AKS private equivalent)
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false

  enable_irsa = true

  eks_managed_node_groups = {
    system = {
      name           = "system-ng"
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 3
      desired_size   = 2
    }

    user = {
      name           = "user-ng"
      instance_types = ["t3.medium"]
      desired_size   = 1
    }
  }

  tags = {
    Environment = "Production"
  }
}

########################################
# CLOUDWATCH LOGGING
########################################

resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/demo-eks"
  retention_in_days = 30
}

########################################
# EKS ADDONS (CNI + OBSERVABILITY)
########################################

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = module.eks.cluster_name
  addon_name   = "vpc-cni"
}

resource "aws_eks_addon" "cloudwatch" {
  cluster_name = module.eks.cluster_name
  addon_name   = "amazon-cloudwatch-observability"
}

########################################
# ECR (ACR EQUIVALENT)
########################################

resource "aws_ecr_repository" "app" {
  name                 = "demo-ecr"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = "Production"
  }
}