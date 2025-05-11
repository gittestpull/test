# AWS EKS 기반 Spring Boot 애플리케이션 배포

이 프로젝트는 AWS EKS를 사용하여 Spring Boot 애플리케이션을 배포하는 인프라 코드와 배포 파이프라인을 포함하고 있습니다.

## 아키텍처

- AWS의 모든 자원은 Terraform으로 구성합니다.
- Terraform registry의 공식 Module을 사용합니다 (vpc, eks).
- 네트워크 구성:
  - Public Subnet은 ALB와 인터넷 게이트웨이 연결을 위한 것입니다.
  - Private Subnet은 EC2와 같은 리소스가 NAT를 통해 외부 통신하는 용도입니다.
  - Private Subnet에서 외부 통신 시 같은 Zone의 NAT를 이용합니다.
- Amazon EKS의 관리형 노드는 각각의 Private Subnet에 위치합니다.
- Deployment에 구성될 Pod는 Spring Boot 이미지로 제작하여 컨테이너 레지스트리에 업로드합니다.
- 만들어진 이미지는 affinity 옵션을 통해 Private Subnet에 전개된 노드에 위치 가능합니다.
- Application Load Balancer는 인터넷으로 접근이 가능하며 구성된 Pod로 라우팅합니다.

## 사전 요구사항

- AWS 계정
- GitHub 계정
- 다음 GitHub Secrets 설정:
  - AWS_ACCESS_KEY_ID
  - AWS_SECRET_ACCESS_KEY
  - AWS_REGION
  - ECR_REPOSITORY
  - EKS_CLUSTER_NAME

## 배포 방법

1. 이 레포지토리를 클론합니다.
2. GitHub Secrets를 설정합니다.
3. 코드를 main 브랜치에 푸시하면 GitHub Actions가 자동으로 실행됩니다.

## 구성 요소

- Terraform: AWS 인프라를 정의합니다.
- Kubernetes: 애플리케이션 배포 매니페스트를 정의합니다.
- GitHub Actions: CI/CD 파이프라인을 구성합니다.
- Spring Boot: 예제 애플리케이션입니다.