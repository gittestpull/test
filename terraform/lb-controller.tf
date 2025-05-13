data "aws_eks_cluster" "main" {
  name = var.cluster_name
depends_on = [
    module.eks,
    aws_iam_role_policy_attachment.external_dns
  ]
}

# AWS Load Balancer Controller IAM 역할
resource "aws_iam_role" "lb_controller_role" {
  name = "${var.cluster_name}-lb-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:aud" : "sts.amazonaws.com",
            "${module.eks.oidc_provider}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
}

# AWS Load Balancer Controller IAM 정책
resource "aws_iam_policy" "lb_controller_policy" {
  name        = "${var.cluster_name}-AWSLoadBalancerControllerIAMPolicy"
  description = "Policy for AWS Load Balancer Controller"
  policy      = file("${path.module}/policies/lb-controller-policy.json")
}

# IAM 정책 연결
resource "aws_iam_role_policy_attachment" "lb_controller_attach" {
  role       = aws_iam_role.lb_controller_role.name
  policy_arn = aws_iam_policy.lb_controller_policy.arn
}

# AWS Load Balancer Controller 서비스 계정 생성
resource "kubernetes_service_account" "lb_controller_sa" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.lb_controller_role.arn
    }
    labels = {
      "app.kubernetes.io/name"       = "aws-load-balancer-controller"
      "app.kubernetes.io/component"  = "controller"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
  depends_on = [
    module.eks
  ]
}

# AWS Load Balancer Controller 배포
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.6.0"  # 최신 안정 버전으로 업데이트

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"  # 이미 Kubernetes 리소스로 생성했음
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  # 필요하면 VPC ID 명시적으로 설정
  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  set {
    name  = "region"
    value = var.region
  }

  # 디버깅에 도움이 됨
  set {
    name  = "enableShield"
    value = "false"
  }

  set {
    name  = "enableWaf"
    value = "false"
  }

  set {
    name  = "enableWafv2"
    value = "false"
  }

  depends_on = [
    module.eks,
    # kubernetes_service_account.lb_controller_sa,
    # aws_iam_role_policy_attachment.lb_controller_attach
  ]
}

data "aws_caller_identity" "current" {}
