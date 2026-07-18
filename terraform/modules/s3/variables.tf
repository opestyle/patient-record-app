variable "env" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "irsa_role_arn" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
