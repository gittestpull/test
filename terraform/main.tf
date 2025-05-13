terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  # Terraform 상태를 S3에 저장하는 백엔드 설정
  backend "s3" {
    bucket         = "terraform-state-eks-cluster-634835101857"
    key            = "terraform/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "terraform-locks-eks-cluster"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}

# S3 버킷 생성 (Terraform 상태용)
resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-eks-cluster-634835101857"

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(var.tags, {
    Name = "Terraform State"
  })
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 상태 잠금을 위한 DynamoDB 테이블
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks-eks-cluster"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(var.tags, {
    Name = "Terraform Locks"
  })
}

# 애플리케이션용 S3 버킷 생성
resource "aws_s3_bucket" "app_storage" {
  bucket = "eks-app-storage-634835101857"

  tags = merge(var.tags, {
    Name = "EKS Application Storage"
  })
}

resource "aws_s3_bucket_versioning" "app_versioning" {
  bucket = aws_s3_bucket.app_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

# VPC 생성
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

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
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # API 서버 엔드포인트 액세스 설정 추가
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true
  
  # 클러스터 생성자에게 자동으로 관리자 권한 부여
  enable_cluster_creator_admin_permissions = true

  # IRSA(IAM Role for Service Account) 활성화
  enable_irsa = true

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
  # Fargate 프로필 설정
  fargate_profiles = {
    default = {
      name = "default"
      selectors = [
        {
          namespace = "default"
        },
        {
          namespace = "kube-system"
        }
      ]
      subnet_ids = module.vpc.private_subnets
      tags = {
        Environment = "dev"
      }
    }
    
    app = {
      name = "applications"
      selectors = [
        {
          namespace = "applications"
        }
      ]
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

# # S3 접근을 위한 IAM 정책 생성
# resource "aws_iam_policy" "s3_access" {
#   name        = "eks-s3-access-policy"
#   description = "Policy for accessing S3 bucket from EKS pods"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Action = [
#           "s3:GetObject",
#           "s3:PutObject",
#           "s3:ListBucket",
#           "s3:DeleteObject"
#         ],
#         Resource = [
#           aws_s3_bucket.app_storage.arn,
#           "${aws_s3_bucket.app_storage.arn}/*"
#         ]
#       }
#     ]
#   })

#   tags = var.tags
# }

# # IRSA를 위한 서비스 계정 및 IAM 역할 생성
# module "iam_assumable_role_with_oidc" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
#   version = "~> 4.0"
  
#   create_role                   = true
#   role_name                     = "eks-s3-access-role"
#   provider_url                  = module.eks.cluster_oidc_issuer_url
#   role_policy_arns              = [aws_iam_policy.s3_access.arn]
#   oidc_fully_qualified_subjects = ["system:serviceaccount:applications:s3-service-account"]
  
#   tags = var.tags
# }

# # 서비스 계정 Kubernetes 리소스 생성을 위한 manifest
# resource "kubernetes_service_account" "s3_service_account" {
#   depends_on = [module.eks]
  
#   metadata {
#     name      = "s3-service-account"
#     namespace = "applications"
#     annotations = {
#       "eks.amazonaws.com/role-arn" = module.iam_assumable_role_with_oidc.iam_role_arn
#     }
#   }
# }

# # applications 네임스페이스 생성
# resource "kubernetes_namespace" "applications" {
#   depends_on = [module.eks]
  
#   metadata {
#     name = "applications"
#   }
# }

# # 샘플 Pod에서 S3 접근 시연을 위한 Deployment 예제
# resource "kubernetes_deployment" "s3_example" {
#   depends_on = [kubernetes_service_account.s3_service_account]
  
#   metadata {
#     name      = "s3-example"
#     namespace = "applications"
#   }

#   spec {
#     replicas = 1

#     selector {
#       match_labels = {
#         app = "s3-example"
#       }
#     }

#     template {
#       metadata {
#         labels = {
#           app = "s3-example"
#         }
#       }

#       spec {
#         service_account_name = "s3-service-account"
        
#         container {
#           name  = "s3-example"
#           image = "amazon/aws-cli:latest"
          
#           command = ["/bin/sh", "-c", "while true; do aws s3 ls s3://eks-app-storage-634835101857; sleep 30; done"]
          
#           env {
#             name  = "AWS_REGION"
#             value = var.region
#           }
#         }
#       }
#     }
#   }
# }