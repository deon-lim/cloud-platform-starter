variable "image_url" {}
variable "execution_role_arn" {}
variable "target_group_arn" {}
variable "subnet_ids"        { type = list(string) }
variable "security_group_id" {}
variable "aws_region" {}
variable "name" { default = "" }

locals {
  suffix = var.name != "" ? "-${var.name}" : ""
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/cloud-platform${local.suffix}"
  retention_in_days = 7
}

resource "aws_ecs_cluster" "main" {
  name = "cloud-platform-cluster${local.suffix}"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "cloud-platform-task${local.suffix}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.execution_role_arn

  container_definitions = jsonencode([{
    name      = "app"
    image     = var.image_url
    essential = true

    portMappings = [{
      containerPort = 3000
      protocol      = "tcp"
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/cloud-platform${local.suffix}"
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_security_group" "ecs" {
  name   = "ecs-sg${local.suffix}"
  vpc_id = data.aws_subnet.first.vpc_id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [var.security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_subnet" "first" {
  id = var.subnet_ids[0]
}

resource "aws_ecs_service" "app" {
  name            = "cloud-platform-service${local.suffix}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "app"
    container_port   = 3000
  }
}

output "cluster_name" { value = aws_ecs_cluster.main.name }
output "service_name" { value = aws_ecs_service.app.name }
output "task_family"  { value = aws_ecs_task_definition.app.family }