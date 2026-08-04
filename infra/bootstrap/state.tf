
//locals

locals{
state_bucket_name = "numeraft-tfstate-${var.aws_account_id}-${var.aws_region}"
}


// S3 initialization 

resource "aws_s3_bucket" "terraform_state"{
    bucket = local.state_bucket_name
    lifecycle {
      prevent_destroy = true
    }
}


// S3 ownership

resource "aws_s3_bucket_ownership_controls" "terraform_state"{
    bucket=aws_s3_bucket.terraform_state.id
    rule{
        object_ownership="BucketOwnerEnforced"
    }
}


// S3 aws_s3_bucket_versioning

resource "aws_s3_bucket_versioning" "terraform_state"{
    bucket = aws_s3_bucket.terraform_state.id
    versioning_configuration {
      status = "Enabled"
    }
}

// S3 encryption

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state"{
    bucket = aws_s3_bucket.terraform_state.id
    
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
}


// S3 public access block

resource "aws_s3_bucket_public_access_block" "terraform_state"{
    bucket=aws_s3_bucket.terraform_state.id
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}


// S3 lifecycle configuration

resource "aws_s3_bucket_lifecycle_configuration" "terraform_state"{
    bucket = aws_s3_bucket.terraform_state.id

    rule {
      id = "expire-old-state-versions"
      status = "Enabled"
      filter {
      }
      noncurrent_version_expiration {
        noncurrent_days = 90
      }
      abort_incomplete_multipart_upload {
        days_after_initiation = 7
      }
    }
}


// aws IAM Policy

data "aws_iam_policy_document" "state_tls_only"{
    statement {
      sid = "DenyInsecureTransport"
      effect = "Deny"
      actions = ["s3:*"]
      resources = [ aws_s3_bucket.terraform_state.arn,"${aws_s3_bucket.terraform_state.arn}/*" ]
    principals {
        type = "*"
      identifiers = [ "*" ]
    }
    condition {
      test = "Bool"
      values =["false"]
      variable = "aws:SecureTransport"
    }
    }
}

// S3 bucket policy

resource "aws_s3_bucket_policy" "terraform_state"{
    bucket = aws_s3_bucket.terraform_state.id
    policy = data.aws_iam_policy_document.state_tls_only.json
}