variable "env" {
  type = string
}

variable "github_repo" {
  description = "GitHub \"owner/repo\" allowed to assume this role via OIDC"
  type        = string
}

variable "ecr_backend_repo_arn" {
  type = string
}

variable "ecr_frontend_repo_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
