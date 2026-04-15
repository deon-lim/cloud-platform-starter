variable "image_url" {}
variable "execution_role_arn" {}
variable "target_group_arn" {}
variable "subnet_ids" { type = list(string) }
variable "security_group_id" {}
variable "aws_region" {}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/cloud-platform"
  retention_in_days = 7
}

resource "aws_ecs_cluster" "main" {
  name = "cloud-platform-cluster"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "cloud-platform-task"
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
        awslogs-group         = "/ecs/cloud-platform"
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_security_group" "ecs" {
  name   = "ecs-sg"
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
  name            = "cloud-platform-service"
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