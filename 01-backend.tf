# setup terraform backend to store state in s3 bucket
# I am using us-east-2 as a region
terraform {
  backend "s3" {
    bucket  = "marvin-jenkins-tf-state-031726"
    key     = "jenkins-test-031726.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
}
