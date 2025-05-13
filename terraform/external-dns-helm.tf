# External DNS 설치
resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"  # 변경된 저장소
  chart      = "external-dns"
  namespace  = "kube-system"
  # 버전은 지정하지 않으면 최신 버전 사용 (또는 최신 안정 버전 확인 후 지정)
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

  depends_on = [
    module.eks,
    aws_iam_role_policy_attachment.external_dns
  ]
}