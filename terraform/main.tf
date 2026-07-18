data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  tags = {
    Project     = "patient-record-app"
    Environment = var.env
    ManagedBy   = "Terraform"
  }
  # Computed from the same naming convention the s3 module uses, so the eks
  # module can scope its IRSA policy to this bucket without depending on the
  # s3 module's output (which would create a dependency cycle: s3 depends on
  # eks for its IRSA role ARN).
  s3_bucket_arn      = "arn:aws:s3:::${var.env}-${var.app_bucket_name}"
  secret_name_prefix = "${var.env}/patient-app"
}

module "vpc" {
  count  = var.deploy_aws_infra ? 1 : 0
  source = "./modules/vpc"

  env             = var.env
  vpc_name        = var.vpc_name
  cluster_name    = var.cluster_name
  vpc_cidr        = var.vpc_cidr
  azs             = local.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  tags            = local.tags
}

module "eks" {
  count  = var.deploy_aws_infra ? 1 : 0
  source = "./modules/eks"

  env                 = var.env
  cluster_name        = var.cluster_name
  cluster_version     = var.cluster_version
  vpc_id              = try(module.vpc[0].vpc_id, "")
  private_subnet_ids  = try(module.vpc[0].private_subnet_ids, [])
  node_instance_types = var.node_instance_types
  node_min            = var.node_min
  node_max            = var.node_max
  node_desired        = var.node_desired
  log_retention_days  = var.log_retention_days
  tags                = local.tags

  aws_region                           = var.aws_region
  s3_bucket_arn                        = local.s3_bucket_arn
  secret_name_prefix                   = local.secret_name_prefix
  cluster_endpoint_public_access_cidrs = var.eks_public_access_cidrs
}

module "ecr" {
  count  = var.deploy_aws_infra ? 1 : 0
  source = "./modules/ecr"

  env  = var.env
  tags = local.tags
}

module "s3" {
  count  = var.deploy_aws_infra ? 1 : 0
  source = "./modules/s3"

  env           = var.env
  bucket_name   = var.app_bucket_name
  irsa_role_arn = try(module.eks[0].s3_access_role_arn, "")
  tags          = local.tags
}

module "secrets" {
  count  = var.deploy_aws_infra ? 1 : 0
  source = "./modules/secrets"

  env          = var.env
  db_username  = var.db_username
  db_password  = var.db_password
  db_host      = try(module.rds[0].db_endpoint, "")
  db_name      = var.db_name
  database_url = "postgresql://${var.db_username}:${var.db_password}@${try(module.rds[0].db_endpoint, "")}/${var.db_name}"
  s3_bucket    = try(module.s3[0].bucket_name, "")
  tags         = local.tags
}

module "rds" {
  count  = var.deploy_aws_infra ? 1 : 0
  source = "./modules/rds"

  env                = var.env
  db_name            = var.db_name
  vpc_id             = try(module.vpc[0].vpc_id, "")
  private_subnet_ids = try(module.vpc[0].private_subnet_ids, [])
  eks_node_sg_id     = try(module.eks[0].node_security_group_id, "")
  instance_class     = var.db_instance_class
  allocated_storage  = var.db_allocated_storage
  db_username        = var.db_username
  db_password        = var.db_password
  tags               = local.tags
}
