data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name = var.project_name
  azs  = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name = local.name
  cidr = var.vpc_cidr
  azs  = local.azs

  private_subnets = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 4, i)]
  public_subnets  = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 4, i + 8)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${local.name}" = "shared"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.31.6"

  cluster_name    = local.name
  cluster_version = var.cluster_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  cluster_endpoint_public_access = true
  enable_irsa                    = true

  eks_managed_node_groups = {
    general = {
      name           = "${local.name}-nodes"
      instance_types = var.node_instance_types
      capacity_type  = "SPOT"
      min_size       = var.min_size
      max_size       = var.max_size
      desired_size   = var.desired_size
      disk_size      = 20
    }
  }

  tags = {
    Project     = local.name
    Environment = "test"
    ManagedBy   = "Terraform"
  }
}
