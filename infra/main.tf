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