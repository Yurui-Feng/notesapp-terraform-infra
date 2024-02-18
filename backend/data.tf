data "aws_iam_role" "ecs_execution_role" {
  name = "ecsTaskExecutionRole"
}

data "aws_iam_role" "ecs_task_role" {
  name = "ecsTaskExecutionRole"
}

data "aws_ecr_repository" "backend-repo" {
    name = "notes-backend"
    }

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_acm_certificate" "backend-cert" {
  domain   = "api.fuyuri.com"
  statuses = ["ISSUED"]
  most_recent = true
}
