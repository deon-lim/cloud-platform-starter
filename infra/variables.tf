variable "aws_region" { default = "ap-southeast-1" }
variable "vpc_id" {}
variable "public_subnet_ids" { type = list(string) }
