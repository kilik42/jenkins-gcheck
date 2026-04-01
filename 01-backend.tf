
terraform {
  backend "s3" {
    bucket  = "marvin-jenkins-tf-state-031726"
    key     = "jenkins-test-031726.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
}
