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
  - ECR_REPO_NAME
  - REPO_PATH

## 배포 방법

1. 이 레포지토리를 클론합니다.
2. GitHub Secrets를 설정합니다.
3. 코드를 main 브랜치에 푸시하면 GitHub Actions가 자동으로 실행됩니다.

## CI/CD 파이프라인

GitHub Actions 워크플로우는 다음 3단계로 분리되어 있습니다:
1. **인프라 구축**: Terraform을 사용하여 AWS EKS 클러스터 및 관련 리소스를 생성합니다.
2. **이미지 빌드 및 푸시**: Spring Boot 애플리케이션을 빌드하고 Docker 이미지로 패키징한 후 ECR에 푸시합니다.
3. **애플리케이션 배포**: 빌드된 이미지를 EKS 클러스터에 배포합니다.

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
```
```사용자가 요청한 대로 README.md에 GitHub Actions 워크플로우가 3단계로 분리되어 있다는 내용을 추가했습니다. 파일의 구조를 보존하고, "CI/CD 파이프라인" 섹션을 새로 추가하여 3단계 배포 프로세스에 대한 설명을 포함했습니다:

1. 인프라 구축: Terraform으로 AWS 리소스 생성
2. 이미지 빌드 및 푸시: Spring Boot 앱을 Docker 이미지로 빌드하여 ECR에 푸시
3. 애플리케이션 배포: 빌드된 이미지를 EKS 클러스터에 배포

또한 이 구조의 장점(독립적 실행과 디버깅 용이성)도 간략히 설명했습니다.