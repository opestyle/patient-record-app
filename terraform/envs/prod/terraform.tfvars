env                  = "prod"
aws_region           = "us-east-1"
cluster_name         = "patient-app"
vpc_name             = "patient-app-vpc"
vpc_cidr             = "10.40.0.0/16"
private_subnets      = ["10.40.1.0/24", "10.40.2.0/24", "10.40.3.0/24"]
public_subnets       = ["10.40.101.0/24", "10.40.102.0/24", "10.40.103.0/24"]
app_bucket_name      = "prod-patient-app-storage"
db_name              = "patientapp"
db_instance_class    = "db.t3.small"
db_allocated_storage = 50
db_username          = "patientapp"
# db_password is intentionally not set here — supply it via TF_VAR_db_password
# or a local, gitignored *.auto.tfvars file. Never commit a real value.
