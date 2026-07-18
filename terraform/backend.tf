terraform {
  backend "s3" {
    bucket         = "REPLACE_ME_STATE_BUCKET"
    key            = "patient-app/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "REPLACE_ME_LOCK_TABLE"
  }
}
