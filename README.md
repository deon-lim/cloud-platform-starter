# Cloud Platform Starter

A minimal but production-style cloud platform built on AWS — demonstrating Infrastructure as Code, CI/CD automation, multi-environment deployment, and operational observability.

![CI/CD Pipeline](https://github.com/deon-lim/cloud-platform-starter/actions/workflows/deploy.yml/badge.svg)
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
(image pull)  (logs + dashboard metrics)
```

The same architecture runs across two environments — **production** and **staging** — each with their own ALB, ECS cluster, and CloudWatch log group.

---

## CI/CD Pipeline

Every push to `main` triggers a 5-job pipeline:

```
git push origin main
      │
      ▼
[1] test          ← ESLint + Jest must pass
      │
      ▼
[2] build         ← Docker image built (linux/amd64)
      │              Tagged with commit SHA + latest
      │              Pushed to ECR
      │              ECR vulnerability scan — CRITICAL CVEs fail pipeline
      │
      ▼
[3] deploy-staging   ← New task definition registered with SHA image
      │                 ECS staging service updated
      │                 Pipeline waits for service stability
      │
      ▼
[4] deploy-production ← Same image promoted to production
      │                  Pipeline waits for service stability
      │
      ▼
[5] notify         ← Email sent only on failure
                      Includes commit SHA, actor, link to failed run
```

---

## Tech Stack

| Tool / Service | Purpose |
|---|---|
| Terraform | Infrastructure as Code — provisions all AWS resources |
| AWS ECS Fargate | Serverless container runtime — no servers to manage |
| Amazon ECR | Private Docker image registry with vulnerability scanning |
| AWS ALB | Public entry point and health check manager |
| AWS IAM | Least-privilege task execution role |
| AWS CloudWatch | Container logs + live operational dashboard |
| GitHub Actions | 5-job CI/CD pipeline |
| Express (Node.js) | Minimal application |
| Jest + Supertest | Endpoint tests run as pipeline gate |
| ESLint | Linting enforced before build |
| Docker | Container runtime (Alpine base image) |

---

## Project Structure

```
cloud-platform-starter/
│
├── app/                        Application layer
│   ├── index.js               Express app (/ and /health routes)
│   ├── index.test.js          Jest tests for all endpoints
│   ├── package.json           Node dependencies + scripts
│   ├── eslint.config.cjs      ESLint configuration
│   └── Dockerfile             Container definition (linux/amd64)
│
├── infra/                      Infrastructure as Code (Terraform)
│   ├── main.tf                Root module — all environment modules
│   ├── variables.tf           Input variables (region, VPC, subnets)
│   ├── outputs.tf             ALB DNS names, ECR repository URL
│   ├── terraform.tfvars       Environment values (gitignored)
│   └── modules/
│       ├── ecr/               Private image registry (shared)
│       ├── iam/               ECS task execution role (shared)
│       ├── alb/               Load balancer, target group, listener
│       ├── ecs/               Cluster, task definition, service, logs
│       └── cloudwatch/        Dashboard with 8 live metric panels
│
└── .github/
    └── workflows/
        └── deploy.yml         5-job CI/CD pipeline definition
```

---

## Environments

| Resource | Production | Staging |
|---|---|---|
| ALB | cloud-platform-alb | cloud-platform-alb-staging |
| ECS Cluster | cloud-platform-cluster | cloud-platform-cluster-staging |
| ECS Service | cloud-platform-service | cloud-platform-service-staging |
| Task Family | cloud-platform-task | cloud-platform-task-staging |
| Log Group | /ecs/cloud-platform | /ecs/cloud-platform-staging |
| Image Registry | ECR (shared) | ECR (shared) |

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
- A dedicated IAM user with the following policies:
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
git clone https://github.com/deon-lim/cloud-platform-starter.git
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

This provisions all AWS resources for both production and staging environments plus the CloudWatch Dashboard. Note the outputs:

```
alb_dns_name         = "cloud-platform-alb-xxx.ap-southeast-1.elb.amazonaws.com"
alb_staging_dns_name = "cloud-platform-alb-staging-xxx.ap-southeast-1.elb.amazonaws.com"
ecr_repository_url   = "xxxxxxxxxxxx.dkr.ecr.ap-southeast-1.amazonaws.com/cloud-platform-starter"
```

### 6. Push First Image to ECR

```bash
# Authenticate Docker to ECR
aws ecr get-login-password --region ap-southeast-1 | \
  docker login --username AWS --password-stdin <ecr_repository_url>

# Build and push for linux/amd64
cd app
docker buildx build --platform linux/amd64 \
  -t <ecr_repository_url>:latest \
  --push .

# Force ECS to deploy (production)
aws ecs update-service \
  --cluster cloud-platform-cluster \
  --service cloud-platform-service \
  --force-new-deployment \
  --region ap-southeast-1

# Force ECS to deploy (staging)
aws ecs update-service \
  --cluster cloud-platform-cluster-staging \
  --service cloud-platform-service-staging \
  --force-new-deployment \
  --region ap-southeast-1
```

---

## CI/CD Pipeline Setup

### Add GitHub Secrets

Go to your repo → **Settings** → **Secrets and variables** → **Actions** and add:

| Secret | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | Your IAM user access key ID |
| `AWS_SECRET_ACCESS_KEY` | Your IAM user secret access key |
| `NOTIFY_EMAIL` | Your Gmail address for failure notifications |
| `NOTIFY_EMAIL_PASSWORD` | Gmail app password (16-character) |

### Triggering a Deployment

Push any change to `main`:

```bash
git add .
git commit -m "your change"
git push origin main
```

Monitor the run under the **Actions** tab in GitHub. All 5 jobs run automatically.

---

## Accessing the Application

| Endpoint | Method | Response |
|---|---|---|
| `http://<alb_dns_name>/` | GET | `{ status, message, version }` |
| `http://<alb_dns_name>/health` | GET | `{ healthy: true }` |

Both production and staging expose the same endpoints on their respective ALB URLs.

---

## Running Tests Locally

```bash
cd app
npm install
npm test       # Jest endpoint tests
npm run lint   # ESLint
```

---

## Monitoring & Logs

### CloudWatch Dashboard

- **Access:** AWS Console → CloudWatch → Dashboards → `cloud-platform-dashboard`
- **Panels:** 8 live metric panels across production and staging
  - ALB Request Count
  - ALB 5xx Error Rate
  - ECS CPU Utilisation
  - ECS Memory Utilisation

### Container Logs

| Environment | Log Group |
|---|---|
| Production | `/ecs/cloud-platform` |
| Staging | `/ecs/cloud-platform-staging` |

**Access:** AWS Console → CloudWatch → Log Management → Log Groups

---

## Teardown

To avoid ongoing AWS charges, destroy all resources when done:

```bash
cd infra
terraform destroy
```

Type `yes` to confirm. This removes all resources across both environments including ALBs, ECS clusters, ECR repository, IAM role, CloudWatch log groups, and the dashboard.

> ⚠️ This is irreversible. Ensure you no longer need the resources before running.

---

## Architectural Decisions

| Decision | Rationale |
|---|---|
| ECS Fargate over EKS | No node management overhead. Right-sized for a platform starter — EKS adds complexity only justified when Kubernetes-native features are needed |
| IAM role over hardcoded credentials | ECS assumes the task execution role at runtime. No access keys in code, no rotation risk |
| Modular Terraform | Each module owns one concern. Reused across environments via a name variable pattern |
| Shared ECR, separate ECS | One registry for all images, isolated runtime environments per deployment target |
| Commit SHA image tagging | Every deployment is traceable to a specific commit. Enables precise rollbacks |
| Single build, dual deploy | Image built once in the build job, SHA passed as output to both deploy jobs — staging and production always run identical images |
| Alpine base image | ~50MB vs ~300MB for the full Node image. Smaller attack surface, faster ECR pull times |
| Health check on `/health` | Dedicated endpoint for ALB probing. Separates platform health signalling from application logic |
| Vulnerability scan gate | Pipeline polls ECR scan results after push. Critical CVEs block deployment to all environments |
| Staging before production | deploy-production has needs: [build, deploy-staging] — staging failure stops the pipeline before production is touched |

---

## What Production Would Add

- **HTTPS** via ACM certificate and Route 53 custom domain
- **Private subnets** for ECS — ALB in public, containers in private
- **ECS Auto Scaling** based on ALB request count or CPU utilisation
- **ECS deployment circuit breaker** for automatic rollback on failed deployments
- **Remote Terraform state** in S3 with DynamoDB locking
- **Manual approval gate** before production deployment
- **CloudWatch Alarms** on ECS CPU, memory, and ALB 5xx error rate
- **Structured JSON logging** for CloudWatch Insights queries
- **Integration tests** against the staging URL before production promotion