variable "vpc_id" {}
variable "subnet_ids" { type = list(string) }
variable "name"      { default = "" }

locals {
  suffix = var.name != "" ? "-${var.name}" : ""
}

resource "aws_security_group" "alb" {
  name   = "alb-sg${local.suffix}"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "app" {
  name               = "cloud-platform-alb${local.suffix}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids
}

resource "aws_lb_target_group" "app" {
  name        = "cloud-platform-tg${local.suffix}"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

output "dns_name"          { value = aws_lb.app.dns_name }
output "target_group_arn"  { value = aws_lb_target_group.app.arn }
output "security_group_id" { value = aws_security_group.alb.id }