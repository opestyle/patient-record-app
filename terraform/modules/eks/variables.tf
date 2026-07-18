variable "env" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "node_instance_types" {
  type = list(string)
}

variable "node_min" {
  type = number
}

variable "node_max" {
  type = number
}

variable "node_desired" {
  type = number
}

variable "log_retention_days" {
  type = number
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "aws_region" {
  type = string
}

variable "s3_bucket_arn" {
  description = "ARN of the application S3 bucket, used to scope the IRSA S3 access policy instead of Resource = \"*\""
  type        = string
}

variable "secret_name_prefix" {
  description = "Secrets Manager name prefix (e.g. \"<env>/patient-app\") used to scope the external-secrets IRSA policy"
  type        = string
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public EKS API endpoint. Replace the placeholder with your office/VPN CIDR before applying — do not leave this as 0.0.0.0/0."
  type        = list(string)
  default     = ["203.0.113.0/32"]
}
