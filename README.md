# Cloud Platform Starter

A minimal but production-style cloud platform built on AWS — demonstrating Infrastructure as Code, CI/CD automation, and cloud-native platform design.

![CI/CD Pipeline](https://github.com/<your-github-username>/cloud-platform-starter/actions/workflows/deploy.yml/badge.svg)
![Terraform](https://img.shields.io/badge/Terraform-v1.14.8-7B42BC?logo=terraform)
![AWS Region](https://img.shields.io/badge/AWS-ap--southeast--1-FF9900?logo=amazonaws)

---

## Architecture

```
Internet
   │
   ▼
Application Load Balancer  (public, port 80)
   │
   │   health check: GET /health every 30s
   │
   ▼
ECS Fargate Service  (port 3000)
   │              │
   ▼              ▼
ECR           CloudWatch
(image pull)  (container logs)
```

Every push to `main` triggers the CI/CD pipeline:

```
git push origin main
      │
      ▼
GitHub Actions
      │
      ├── Build Docker image (linux/amd64)
      ├── Push to ECR (tagged with commit SHA + latest)
      └── Force ECS redeployment
```

---

## Tech Stack

| Tool / Service | Purpose |
|---|---|
| Terraform | Infrastructure as Code — provisions all AWS resources |
| AWS ECS Fargate | Serverless container runtime |
| Amazon ECR | Private Docker image registry |
| AWS ALB | Public entry point and health check manager |
| AWS IAM | Least-privilege task execution role |
| AWS CloudWatch | Container log aggregation |
| GitHub Actions | CI/CD pipeline |
| Express (Node.js) | Minimal application |
| Docker | Container runtime |

---

## Project Structure

```
cloud-platform-starter/
│
├── app/                        Application layer
│   ├── index.js               Express app (/ and /health routes)
│   ├── package.json           Node dependencies
│   └── Dockerfile             Container definition (linux/amd64)
│
├── infra/                      Infrastructure as Code (Terraform)
│   ├── main.tf                Root module — wires all modules together
│   ├── variables.tf           Input variables (region, VPC, subnets)
│   ├── outputs.tf             ALB DNS name, ECR repository URL
│   ├── terraform.tfvars       Environment values (gitignored)
│   └── modules/
│       ├── ecr/               Private image registry
│       ├── iam/               ECS task execution role
│       ├── alb/               Load balancer, target group, listener
│       └── ecs/               Cluster, task definition, service, logs
│
└── .github/
    └── workflows/
        └── deploy.yml         CI/CD pipeline definition
```

---

## Prerequisites

### Tools

| Tool | Version | Install |
|---|---|---|
| Terraform | v1.14.8+ | `brew tap hashicorp/tap && brew install hashicorp/tap/terraform` |
| AWS CLI | v2+ | `brew install awscli` |
| Docker Desktop | v28+ | `brew install --cask docker` |
| Node.js | v20 (LTS) | `brew install node` |

### AWS Account

- An AWS account (free tier is sufficient)
- An IAM user (`cloud-platform-dev`) with the following policies:
  - `AmazonECS_FullAccess`
  - `AmazonEC2ContainerRegistryFullAccess`
  - `AmazonEC2FullAccess`
  - `IAMFullAccess`
  - `CloudWatchFullAccess`
  - `ElasticLoadBalancingFullAccess`

> ⚠️ Never use root credentials. Create a dedicated IAM user with scoped permissions.

---

## Getting Started

### 1. Clone the repo

```bash
git clone https://github.com/<your-github-username>/cloud-platform-starter.git
cd cloud-platform-starter
```

### 2. Configure AWS CLI

```bash
aws configure
# Enter: Access Key ID, Secret Access Key, region (ap-southeast-1), output (json)
```

Verify:
```bash
aws sts get-caller-identity
```

### 3. Get your VPC and Subnet IDs

```bash
# Default VPC
aws ec2 describe-vpcs --filters Name=isDefault,Values=true \
  --query 'Vpcs[0].VpcId' --output text

# Public subnets
aws ec2 describe-subnets --filters Name=defaultForAz,Values=true \
  --query 'Subnets[*].SubnetId' --output text
```

### 4. Create terraform.tfvars

Create `infra/terraform.tfvars` (this file is gitignored):

```hcl
vpc_id            = "vpc-xxxxxxxxx"
public_subnet_ids = ["subnet-xxx", "subnet-yyy", "subnet-zzz"]
```

### 5. Deploy Infrastructure

```bash
cd infra
terraform init
terraform plan
terraform apply
```

This provisions 12 AWS resources. Note the outputs:
```
alb_dns_name       = "cloud-platform-alb-xxxxxxxxx.ap-southeast-1.elb.amazonaws.com"
ecr_repository_url = "xxxxxxxxxxxx.dkr.ecr.ap-southeast-1.amazonaws.com/cloud-platform-starter"
```

### 6. Push First Image to ECR

```bash
# Authenticate Docker to ECR
aws ecr get-login-password --region ap-southeast-1 | \
  docker login --username AWS --password-stdin <ecr_repository_url>

# Build and push
cd app
docker buildx build --platform linux/amd64 \
  -t <ecr_repository_url>:latest \
  --push .

# Force ECS to deploy
aws ecs update-service \
  --cluster cloud-platform-cluster \
  --service cloud-platform-service \
  --force-new-deployment \
  --region ap-southeast-1
```

Wait ~2 minutes, then test:
```bash
curl http://<alb_dns_name>/
curl http://<alb_dns_name>/health
```

---

## CI/CD Pipeline

The pipeline lives in `.github/workflows/deploy.yml` and triggers automatically on every push to `main`.

### Add GitHub Secrets

Go to your repo → **Settings** → **Secrets and variables** → **Actions** and add:

| Secret | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | Your IAM user access key ID |
| `AWS_SECRET_ACCESS_KEY` | Your IAM user secret access key |

### Pipeline Steps

1. Checkout code
2. Configure AWS credentials from GitHub Secrets
3. Authenticate Docker to ECR
4. Build Docker image for `linux/amd64`
5. Push image to ECR — tagged with commit SHA and `latest`
6. Force ECS service redeployment

### Triggering a Deployment

Simply push any change to `main`:

```bash
git add .
git commit -m "your change"
git push origin main
```

Monitor the run under the **Actions** tab in GitHub.

---

## Accessing the Application

| Endpoint | Method | Response |
|---|---|---|
| `http://<alb_dns_name>/` | GET | `{ status, message, version }` |
| `http://<alb_dns_name>/health` | GET | `{ healthy: true }` |

---

## Monitoring & Logs

Container logs are streamed to CloudWatch automatically via the `awslogs` log driver.

- **Log group:** `/ecs/cloud-platform`
- **Retention:** 7 days
- **Access:** AWS Console → CloudWatch → Log Management → Log Groups → `/ecs/cloud-platform`

---

## Teardown

To avoid ongoing AWS charges, destroy all resources when done:

```bash
cd infra
terraform destroy
```

Type `yes` to confirm. This will remove all 12 resources including the ALB, ECS cluster, ECR repository, IAM role, and CloudWatch log group.

> ⚠️ This is irreversible. Make sure you no longer need the resources before running this command.

---

## Architectural Decisions

| Decision | Rationale |
|---|---|
| ECS Fargate over EKS | No node management overhead. Right-sized for a platform starter — EKS adds complexity only justified when Kubernetes-native features are needed |
| IAM role over hardcoded credentials | ECS assumes the task execution role at runtime. No access keys in code, no rotation risk |
| Modular Terraform | Each module owns one concern. Easier to reason about, test, and reuse independently |
| Commit SHA image tagging | Every deployment is traceable to a specific commit. Enables precise rollbacks — `latest` alone does not |
| Alpine base image | ~50MB vs ~300MB for the full Node image. Smaller attack surface and faster ECR pull times |
| Health check on `/health` | Dedicated endpoint for the ALB to probe. Separates platform health signalling from application logic |

---

## What Production Would Add

- **HTTPS** via ACM certificate and Route 53 custom domain
- **Private subnets** for ECS — ALB in public, containers in private
- **ECS Auto Scaling** based on ALB request count or CPU utilisation
- **Remote Terraform state** in S3 with DynamoDB locking
- **Separate environments** via Terraform workspaces (staging / production)
- **Pipeline test stage** — unit tests and linting before image build
- **Manual approval gate** before production deployment
- **CloudWatch Alarms** on ECS CPU, memory, and ALB 5xx error rate
- **Structured JSON logging** for CloudWatch Insights queries
