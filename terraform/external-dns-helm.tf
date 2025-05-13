# External DNS 설치
resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = "kube-system"
  
  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "aws.region"
    value = var.region
  }

  set {
    name  = "domainFilters[0]"
    value = "forspacelab.com"
  }
  
  set {
    name  = "policy"
    value = "upsert-only"
  }
  
  set {
    name  = "registry"
    value = "txt"
  }

  set {
    name  = "txtOwnerId"
    value = "my-eks-cluster"
  }

  # ServiceAccount 설정
  set {
    name  = "serviceAccount.create"
    value = "true"
  }
  
  set {
    name  = "serviceAccount.name"
    value = "external-dns"
  }
  
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.external_dns.arn
  }

  # 추가 설정
  set {
    name  = "rbac.create"
    value = "true"
  }

  set {
    name  = "sources[0]"
    value = "service"
  }
  
  set {
    name  = "sources[1]"
    value = "ingress"
  }

  set {
    name  = "aws.zoneType"
    value = "public"
  }
  
  # AWS Load Balancer Controller와의 호환성을 위한 주석
  set {
    name  = "podAnnotations.cluster-autoscaler\\.kubernetes\\.io/safe-to-evict"
    value = "\"true\""
  }

  # EKS 클러스터와 노드 그룹이 완전히 생성된 후에 실행되도록 설정
  depends_on = [
    module.eks,
    aws_iam_role_policy_attachment.external_dns,
    module.eks.eks_managed_node_groups,
    kubernetes_service_account.lb_controller_sa
  ]
}