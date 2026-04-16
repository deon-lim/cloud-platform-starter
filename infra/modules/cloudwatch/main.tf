variable "aws_region" {}
variable "production_alb_suffix" {}
variable "staging_alb_suffix" {}
variable "production_tg_suffix" {}
variable "staging_tg_suffix" {}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "cloud-platform-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# Cloud Platform Dashboard\nReal-time metrics for production and staging environments."
        }
      },
      {
        type   = "text"
        x      = 0
        y      = 1
        width  = 24
        height = 1
        properties = {
          markdown = "## Production"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 6
        height = 6
        properties = {
          title   = "ALB Request Count (Production)"
          region  = var.aws_region
          metrics = [["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.production_alb_suffix]]
          stat    = "Sum"
          period  = 60
          view    = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 6
        y      = 2
        width  = 6
        height = 6
        properties = {
          title   = "ALB 5xx Errors (Production)"
          region  = var.aws_region
          metrics = [["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", var.production_alb_suffix]]
          stat    = "Sum"
          period  = 60
          view    = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 2
        width  = 6
        height = 6
        properties = {
          title   = "ECS CPU Utilisation (Production)"
          region  = var.aws_region
          metrics = [["AWS/ECS", "CPUUtilization", "ClusterName", "cloud-platform-cluster", "ServiceName", "cloud-platform-service"]]
          stat    = "Average"
          period  = 60
          view    = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 18
        y      = 2
        width  = 6
        height = 6
        properties = {
          title   = "ECS Memory Utilisation (Production)"
          region  = var.aws_region
          metrics = [["AWS/ECS", "MemoryUtilization", "ClusterName", "cloud-platform-cluster", "ServiceName", "cloud-platform-service"]]
          stat    = "Average"
          period  = 60
          view    = "timeSeries"
        }
      },
      {
        type   = "text"
        x      = 0
        y      = 8
        width  = 24
        height = 1
        properties = {
          markdown = "## Staging"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 9
        width  = 6
        height = 6
        properties = {
          title   = "ALB Request Count (Staging)"
          region  = var.aws_region
          metrics = [["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.staging_alb_suffix]]
          stat    = "Sum"
          period  = 60
          view    = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 6
        y      = 9
        width  = 6
        height = 6
        properties = {
          title   = "ALB 5xx Errors (Staging)"
          region  = var.aws_region
          metrics = [["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", var.staging_alb_suffix]]
          stat    = "Sum"
          period  = 60
          view    = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 9
        width  = 6
        height = 6
        properties = {
          title   = "ECS CPU Utilisation (Staging)"
          region  = var.aws_region
          metrics = [["AWS/ECS", "CPUUtilization", "ClusterName", "cloud-platform-cluster-staging", "ServiceName", "cloud-platform-service-staging"]]
          stat    = "Average"
          period  = 60
          view    = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 18
        y      = 9
        width  = 6
        height = 6
        properties = {
          title   = "ECS Memory Utilisation (Staging)"
          region  = var.aws_region
          metrics = [["AWS/ECS", "MemoryUtilization", "ClusterName", "cloud-platform-cluster-staging", "ServiceName", "cloud-platform-service-staging"]]
          stat    = "Average"
          period  = 60
          view    = "timeSeries"
        }
      }
    ]
  })
}
