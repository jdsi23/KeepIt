terraform {
  required_version = ">= 1.7.0"
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.60" } }

  backend "s3" {
    bucket         = "keepit-tf-state-jl"         # from bootstrap output
    key            = "keepit-infra.tfstate"
    region         = "us-east-1"
    dynamodb_table = "keepit-tf-locks"            # from bootstrap output
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project = var.project
      Env     = var.env
      Owner   = var.owner
    }
  }
}
