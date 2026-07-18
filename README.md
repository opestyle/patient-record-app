# Patient Records Application

This project delivers a secure healthcare-oriented patient records platform built around a React frontend, a FastAPI backend, PostgreSQL on Amazon RDS, Amazon S3 for document storage, Amazon EKS for orchestration, and ArgoCD for GitOps delivery. The app supports patient registration, diagnoses, prescriptions, and document upload workflows.

## What this app does

- Lets clinicians manage patient profiles and basic medical records.
- Exposes a FastAPI backend with health checks, patient CRUD endpoints, and upload support.
- Uses a React web UI to register patients and view recent records.
- Stores persistent transactional data in Amazon RDS PostgreSQL.
- Stores uploaded documents in Amazon S3.
- Runs in Amazon EKS with secure networking, IRSA, ingress, Secrets Manager integration, and CloudWatch logging.

## Deployment overview

1. Provision the AWS infrastructure with Terraform only when you explicitly enable it.
2. Create or update the EKS cluster, VPC, ECR repositories, RDS instance, S3 bucket, and Secrets Manager secrets.
3. Build and push container images to ECR.
4. Update the Helm values with the AWS resource identifiers and image locations.
5. Deploy the application with Helm and optionally sync it through ArgoCD.

## Prerequisites

- Terraform v1.6+
- AWS CLI configured with permissions for EKS, ECR, RDS, S3, Secrets Manager, and IAM.
- kubectl
- Helm v3
- Docker

## Terraform deployment

### 1. Create backend storage for Terraform state

Run the following commands once:

```bash
aws s3api create-bucket --bucket REPLACE_ME_STATE_BUCKET --region us-east-1
aws dynamodb create-table \
  --table-name REPLACE_ME_LOCK_TABLE \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### 2. Initialize Terraform

```bash
cd terraform
terraform init -backend-config=../terraform/backend.tf
```

### 3. Apply the selected environment

By default this project is cost-safe and will not create AWS resources. To deploy to AWS, set `deploy_aws_infra = true` in the environment tfvars or in the Terraform CLI input.

The RDS master password is deliberately **not** stored in the tracked `tfvars` files. Supply it via an environment variable before running `apply`:

```bash
export TF_VAR_db_password='use-a-strong-generated-password'
terraform workspace select dev
terraform apply -var-file=envs/dev/terraform.tfvars
```

Use the same pattern for stg or prod. Never commit a real password into a `tfvars` file — `*.auto.tfvars` is gitignored if you'd rather keep it in a local file.

By default the EKS API server's public endpoint is restricted to a placeholder CIDR (`203.0.113.0/32`) so it isn't open to the entire internet. Override `eks_public_access_cidrs` with your office/VPN CIDR(s) before applying.

## AWS commands to populate Helm values

Use these commands after Terraform applies:

```bash
aws ecr describe-repositories --repository-names dev-patient-app-backend --query 'repositories[0].repositoryUri' --output text
aws ecr describe-repositories --repository-names dev-patient-app-frontend --query 'repositories[0].repositoryUri' --output text
aws secretsmanager describe-secret --secret-id dev/patient-app/app --query 'ARN' --output text
aws secretsmanager describe-secret --secret-id dev/patient-app/rds --query 'ARN' --output text
aws s3api list-buckets --query 'Buckets[?starts_with(Name, `dev-patient-app`)].Name' --output table
aws rds describe-db-instances --db-instance-identifier dev-patientapp --query 'DBInstances[0].Endpoint.Address' --output text
aws eks describe-cluster --name dev-patient-app --query 'cluster.identity.oidc.issuer' --output text
```

## Helm deployment

Update the values in [helm/patient-app/values.yaml](helm/patient-app/values.yaml) with the values from the commands above.

Then run:

```bash
helm upgrade --install patient-app ./helm/patient-app -n patient-app --create-namespace -f ./helm/patient-app/values.yaml
```

The observability stack ([helm/observability](helm/observability)) is a separate chart and can be installed independently of the app:

```bash
helm upgrade --install observability ./helm/observability -n monitoring --create-namespace -f ./helm/observability/values.yaml
```

## ArgoCD deployment

Install ArgoCD in the cluster, then apply the two application manifests after updating the GitHub repository URL (`REPLACE_ME_OWNER`) in each:

- [argocd/application.yaml](argocd/application.yaml) — the patient-app itself (backend, frontend, ingress), synced into the `patient-app` namespace.
- [argocd/observability-application.yaml](argocd/observability-application.yaml) — the Prometheus/Loki/Grafana stack ([helm/observability](helm/observability)), synced independently into the `monitoring` namespace. It can be synced, rolled back, or removed without touching the app.

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f argocd/application.yaml
kubectl apply -f argocd/observability-application.yaml
```

Grafana's admin password is generated automatically at install time (not a Helm value) and stored in the `grafana-admin` Secret in the `monitoring` namespace. Retrieve it with:

```bash
kubectl get secret grafana-admin -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d
```

## Local development

### Backend

```bash
cd app/backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.backend.app.main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend

```bash
cd app/frontend
npm install
npm run dev -- --host 0.0.0.0
```

The frontend should open at http://localhost:5173 and the backend at http://localhost:8000.

## CI/CD workflow

The GitHub Actions workflow at [.github/workflows/deploy.yml](.github/workflows/deploy.yml) runs a `test` job (backend `pytest`, frontend `npm run build`) on every push and pull request. The `build-and-deploy` job only runs after `test` passes, and will:

- build backend and frontend images,
- push them to ECR,
- update the Helm values file with the new tag,
- deploy the release to EKS.

Set the following repository secrets before enabling the workflow:

- AWS_ROLE_TO_ASSUME
- ECR_BACKEND_REPOSITORY
- ECR_FRONTEND_REPOSITORY
- EKS_CLUSTER_NAME
