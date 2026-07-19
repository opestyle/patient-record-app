variable "env" {
  description = "Deployment environment"
  type        = string
}

variable "deploy_aws_infra" {
  description = "Set to true to provision AWS infrastructure such as EKS, RDS, ECR, S3, and Secrets Manager"
  type        = bool
  default     = false
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  type    = string
  default = "patient-app"
}

variable "cluster_version" {
  type    = string
  default = "1.29"
}

variable "vpc_name" {
  type    = string
  default = "patient-app-vpc"
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "az_count" {
  type    = number
  default = 3
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.10.101.0/24", "10.10.102.0/24", "10.10.103.0/24"]
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "node_min" {
  type    = number
  default = 1
}

variable "node_max" {
  type    = number
  default = 3
}

variable "node_desired" {
  type    = number
  default = 2
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "app_bucket_name" {
  type    = string
  default = "patient-app-storage"
}

variable "db_name" {
  type    = string
  default = "patientapp"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "eks_public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public EKS API endpoint. Replace the placeholder default with your office/VPN CIDR before applying."
  type        = list(string)
  default     = ["203.0.113.0/32"]
}

variable "deploy_ci_prereqs" {
  description = "Set to true to provision only the low-cost CI prerequisites (ECR repositories + a GitHub Actions OIDC IAM role) without the full VPC/EKS/RDS stack. Implied by deploy_aws_infra."
  type        = bool
  default     = false
}

variable "github_repo" {
  description = "GitHub \"owner/repo\" allowed to assume the CI IAM role via OIDC"
  type        = string
  default     = "opestyle/patient-record-app"
}
