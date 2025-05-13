
provider "aws" {
  region = var.region
}

S3 버킷 생성 (Terraform 상태용)
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
