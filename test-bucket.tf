terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Use latest version if possible
    }
  }

    backend "s3" {
      bucket = "marvin-jenkins-tf-state-031726"
      key    = "jenkins-test-031726.tfstate"
      region = "us-east-2"
      encrypt = true
    }
}

provider "aws" {
  region  = "us-east-1"
}

resource "aws_s3_bucket" "frontend" {
  bucket_prefix = "jenkins-bucket-"
  force_destroy = true
  

  tags = {
    Name = "Jenkins Bucket"
  }
}