data "aws_iam_role" "ecs_execution_role" {
  name = "ecsTaskExecutionRole"
}

data "aws_iam_role" "ecs_task_role" {
  name = "ecsTaskExecutionRole"
}

data "aws_ecr_repository" "frontend-repo" {
    name = "notes-frontend"
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

data "aws_acm_certificate" "frontend-cert" {
  domain   = "notesapp.fuyuri.com"
  statuses = ["ISSUED"]
  most_recent = true
}