terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # 더 유연한 버전 제약 사용
    }
  }
}

provider "aws" {
  region = var.region
}

# VPC 생성
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = 1
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = 1
  }

  tags = var.tags
}

# EKS 클러스터 생성
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"  # 호환성을 위해 19 버전으로 조정

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # API 서버 엔드포인트 액세스 설정 추가
  cluster_endpoint_public_access  = true   # 퍼블릭 액세스 활성화
  cluster_endpoint_private_access = true   # 프라이빗 액세스도 유지

  # 필요한 경우 특정 CIDR에서만 접근 허용
  # cluster_endpoint_public_access_cidrs = ["your-ip/32"]


  eks_managed_node_groups = {
    main = {
      desired_size = var.desired_nodes
      min_size     = var.min_nodes
      max_size     = var.max_nodes

      instance_types = var.instance_types
      capacity_type  = "ON_DEMAND"

      subnet_ids = module.vpc.private_subnets
    }
  }

  tags = var.tags
}

# ECR 리포지토리 생성
resource "aws_ecr_repository" "app" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}