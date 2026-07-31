terraform{
    required_version=">=1.15.0"
    
    backend "s3" {}

    required_providers {
      aws= {
        source = "hashicorp/aws"
        version= "~> 6.0"
      }
    }
}

provider "aws"{
    region = var.aws_region

    allowed_account_ids = [ var.aws_account_id ]

    default_tags {
    tags={
          Project="numeraft"
      ManagedBy="terraform"
      Scope="bootstrap"
    }
    }
}

data "aws_caller_identity" "current"{}
data "aws_partition" "current"{}