variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "eks-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.21.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for subnets"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "private_subnets" {
  description = "CIDR blocks for the private subnets"
  type        = list(string)
  default     = ["10.21.0.0/24", "10.21.1.0/24"]
}

variable "public_subnets" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
  default     = ["10.21.32.0/24", "10.21.33.0/24"]
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.32"
}

variable "desired_nodes" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "min_nodes" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "max_nodes" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "instance_types" {
  description = "EC2 instance types for worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "spring-boot-app"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  type        = string
  default     = "" # GitHub Secrets에서 값을 제공할 것이므로 기본값은 빈 문자열
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "" # GitHub Secrets에서 값을 제공할 것이므로 기본값은 빈 문자열
}

variable "hosted_zone_name" {
  description = "hosted zone name"
  type        = string
  default     = "" # GitHub Secrets에서 값을 제공할 것이므로 기본값은 빈 문자열
}