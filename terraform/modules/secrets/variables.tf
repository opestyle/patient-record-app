variable "env" {
  type = string
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_host" {
  type = string
}

variable "db_name" {
  type = string
}

variable "database_url" {
  type      = string
  sensitive = true
}

variable "s3_bucket" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
