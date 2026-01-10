provider "aws" {
  # Configure credentials/region elsewhere (provider file or environment)
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

# VPC (equivalent to Azure Virtual Network)
resource "aws_vpc" "vpc" {
  cidr_block           = "10.42.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "myVPC"
  }
}

# Public subnet that will hold the NAT Gateway (map_public_ip_on_launch = true)
resource "aws_subnet" "nat_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.42.1.0/24"
  availability_zone       = element(data.aws_availability_zones.available.names, 0)
  map_public_ip_on_launch = true

  tags = {
    Name = "myNatCluster"
  }
}

# Private subnet for VMs (no public IPs by default)
resource "aws_subnet" "vm_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.42.4.0/24"
  availability_zone       = element(data.aws_availability_zones.available.names, 0)
  map_public_ip_on_launch = false

  tags = {
    Name = "mySubnet"
  }
}

# Internet Gateway for public routes
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "myVPC-igw"
  }
}

# Public route table (routes to Internet Gateway) and association to nat_subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "myVPC-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc_nat_subnet" {
  subnet_id      = aws_subnet.nat_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Allocate an Elastic IP for the NAT Gateway (equivalent to Azure Public IP)
resource "aws_eip" "nat_eip" {
  vpc = true

  tags = {
    Name = "myNatGatewayEIP"
  }
}

# NAT Gateway (equivalent to azurerm_nat_gateway + public ip association)
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.nat_subnet.id

  tags = {
    Name = "myNatGateway"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Private route table that routes Internet-bound traffic through NAT Gateway
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "myVPC-private-rt"
  }
}

resource "aws_route_table_association" "private_assoc_vm_subnet" {
  subnet_id      = aws_subnet.vm_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# VPC Endpoint for S3 (replaces Azure service endpoint for Microsoft.Storage)
# S3 gateway endpoints require route_table_ids so attach to the private route table.
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.vpc.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_route_table.private_rt.id
  ]

  tags = {
    Name = "myVPC-s3-endpoint"
  }
}

# Outputs
output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "nat_subnet_id" {
  value = aws_subnet.nat_subnet.id
}

output "vm_subnet_id" {
  value = aws_subnet.vm_subnet.id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.nat_gateway.id
}

output "nat_eip_allocation_id" {
  value = aws_eip.nat_eip.id
}