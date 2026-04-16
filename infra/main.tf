provider "aws" {
  region = var.aws_region
}

# ── Production ──────────────────────────────────────────────
module "ecr" {
  source    = "./modules/ecr"
  repo_name = "cloud-platform-starter"
}

module "iam" {
  source = "./modules/iam"
}

module "alb" {
  source     = "./modules/alb"
  vpc_id     = var.vpc_id
  subnet_ids = var.public_subnet_ids
}

module "ecs" {
  source             = "./modules/ecs"
  image_url          = "${module.ecr.repository_url}:latest"
  execution_role_arn = module.iam.execution_role_arn
  target_group_arn   = module.alb.target_group_arn
  subnet_ids         = var.public_subnet_ids
  security_group_id  = module.alb.security_group_id
  aws_region         = var.aws_region
}

# ── Staging ─────────────────────────────────────────────────
module "alb_staging" {
  source     = "./modules/alb"
  vpc_id     = var.vpc_id
  subnet_ids = var.public_subnet_ids
  name       = "staging"
}

module "ecs_staging" {
  source             = "./modules/ecs"
  image_url          = "${module.ecr.repository_url}:latest"
  execution_role_arn = module.iam.execution_role_arn
  target_group_arn   = module.alb_staging.target_group_arn
  subnet_ids         = var.public_subnet_ids
  security_group_id  = module.alb_staging.security_group_id
  aws_region         = var.aws_region
  name               = "staging"
}

# ── CloudWatch Dashboard ─────────────────────────────────────────────────
module "cloudwatch_dashboard" {
  source                = "./modules/cloudwatch"
  aws_region            = var.aws_region
  production_alb_suffix = "app/cloud-platform-alb/c7194de7db715c11"
  staging_alb_suffix    = "app/cloud-platform-alb-staging/6fde2024a5e498df"
  production_tg_suffix  = "targetgroup/cloud-platform-tg/037d986f122ac4a0"
  staging_tg_suffix     = "targetgroup/cloud-platform-tg-staging/7491aaaace81d9cf"
}