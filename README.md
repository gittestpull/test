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
- 환경 변수
  - 하기 GitHub Secrets 설정 스크립트 참조

## 배포 방법

1. 이 레포지토리를 클론합니다.
2. GitHub Secrets를 설정합니다.
3. 코드를 main 브랜치에 푸시하면 GitHub Actions가 자동으로 실행됩니다.

## CI/CD 파이프라인

1. terraform-backend-setup.yml (초기 설정 시 1회)
- **초기 설정**: Terraform Backend를 설정합니다. 이 단계는 AWS S3와 DynamoDB를 사용하여 Terraform 상태 파일을 관리합니다.
2. terraform-deploy.yml (인프라 구축)
- **인프라 구축**: Terraform을 사용하여 AWS EKS 클러스터 및 관련 리소스를 생성합니다.
3. k8s-application-deploy.yml (애플리케이션 배포)
- **이미지 빌드 및 푸시**: Spring Boot 애플리케이션을 빌드하고 Docker 이미지로 패키징한 후 ECR에 푸시합니다.
- **애플리케이션 배포**: 빌드된 이미지를 EKS 클러스터에 배포합니다.

이 3단계 분리 구조는 각 단계의 독립적인 실행과 문제 발생 시 쉬운 디버깅을 가능하게 합니다.

## 구성 요소

- Terraform: AWS 인프라를 정의합니다.
- Kubernetes: 애플리케이션 배포 매니페스트를 정의합니다.
- GitHub Actions: CI/CD 파이프라인을 구성합니다.
- Spring Boot: 예제 애플리케이션입니다.

## GitHub Secrets 설정 스크립트

```bash
#!/bin/bash

# 색상 설정
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 시크릿 설정
REPO_PATH="your-github-username/your-repo-name"
AWS_ACCESS_KEY="your-access"
AWS_SECRET_KEY="your-secret"
AWS_REGION_VALUE="ap-northeast-2"
ECR_REPO_NAME="spring-boot-app"
EKS_CLUSTER_NAME_VALUE="eks-cluster"
HOSTED_ZONE_NAME="your-hosted-zone-name"
DOMAIN_NAME="your-domain-name"
ACM_CERTIFICATE_ARN="your-acm-certificate-arn"

echo -e "\n${BLUE}AWS_ACCESS_KEY_ID 설정 중...${NC}"
gh secret set AWS_ACCESS_KEY_ID -b "$AWS_ACCESS_KEY" -R "$REPO_PATH"

echo -e "\n${BLUE}AWS_SECRET_ACCESS_KEY 설정 중...${NC}"
gh secret set AWS_SECRET_ACCESS_KEY -b "$AWS_SECRET_KEY" -R "$REPO_PATH"

echo -e "\n${BLUE}AWS_REGION 설정 중...${NC}"
gh secret set AWS_REGION -b "$AWS_REGION_VALUE" -R "$REPO_PATH"

echo -e "\n${BLUE}ECR_REPOSITORY 설정 중...${NC}"
gh secret set ECR_REPOSITORY -b "$ECR_REPO_NAME" -R "$REPO_PATH"

echo -e "\n${BLUE}EKS_CLUSTER_NAME 설정 중...${NC}"
gh secret set EKS_CLUSTER_NAME -b "$EKS_CLUSTER_NAME_VALUE" -R "$REPO_PATH"

echo -e "\n${BLUE}HOSTED_ZONE_NAME 설정 중...${NC}"
gh secret set HOSTED_ZONE_NAME -b "$HOSTED_ZONE_NAME" -R "$REPO_PATH"

echo -e "\n${BLUE}DOMAIN_NAME 설정 중...${NC}"
gh secret set DOMAIN_NAME -b "$DOMAIN_NAME" -R "$REPO_PATH"

echo -e "\n${BLUE}ACM_CERTIFICATE_ARN 설정 중...${NC}"
gh secret set ACM_CERTIFICATE_ARN -b "$ACM_CERTIFICATE_ARN" -R "$REPO_PATH"

echo -e "\n${GREEN}모든 시크릿 설정이 완료되었습니다.${NC}"
```
