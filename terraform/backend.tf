terraform {
  backend "s3" {
    bucket         = "patient-app-tfstate-063718566254"
    key            = "patient-app/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "patient-app-tf-lock"
  }
}
