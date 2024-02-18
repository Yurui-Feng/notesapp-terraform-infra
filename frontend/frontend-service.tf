terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}


resource "aws_ecs_cluster" "notesApp-cluster" {
    name = "notesApp-cluster"
}

resource "aws_lb" "frontend-lb" {
    name = "frontend-lb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.alb_sg.id]
    subnets = data.aws_subnets.default.ids
    enable_deletion_protection = false
}

resource "aws_lb_target_group" "frontend-tg" {
    name_prefix = "frotg"
    port = 80
    protocol = "HTTP"
    target_type = "ip"
    vpc_id = data.aws_vpc.default.id
    health_check {
        path = "/"
        protocol = "HTTP"
        matcher = "200"
        interval = 30
        timeout = 5
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.frontend-lb.arn
    port = "80"
    protocol = "HTTP"
    default_action {
        type = "redirect"
        redirect {
            port = "443"
            protocol = "HTTPS"
            status_code = "HTTP_301"
        }
    }
}

resource "aws_lb_listener" "https" {
    load_balancer_arn = aws_lb.frontend-lb.arn
    port = "443"
    protocol = "HTTPS"
    ssl_policy = "ELBSecurityPolicy-2016-08"
    certificate_arn = data.aws_acm_certificate.frontend-cert.arn
    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.frontend-tg.arn
    }
}

resource "aws_security_group" "alb_sg" {
    name        = "alb_sg_frontend"
    description = "Security group for the frontend ALB"
    vpc_id      = data.aws_vpc.default.id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        }

    ingress {
        from_port   = 443
        to_port     = 443
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

resource "aws_route53_record" "frontend_record" {
    zone_id = data.aws_route53_zone.mydomain.zone_id
    name = "notesapp.fuyuri.com"
    type = "CNAME"
    ttl = "300"
    records = [aws_lb.frontend-lb.dns_name]
}

resource "aws_ecs_task_definition" "frontend-task" {
    family = "frontend"
    requires_compatibilities = ["FARGATE"]
    network_mode = "awsvpc"
    cpu = "256"
    memory = "512" 
    execution_role_arn = data.aws_iam_role.ecs_execution_role.arn
    task_role_arn = data.aws_iam_role.ecs_task_role.arn

    container_definitions = jsonencode([
      {
        name        = "frontend",
        image       = "${data.aws_ecr_repository.frontend-repo.repository_url}:${var.frontend_image_tag}",
        cpu         = 256,
        memory      = 512,
        essential   = true,
        portMappings = [
          {
            containerPort = 80,
            hostPort      = 80,
            protocol      = "tcp"
          }
        ],
        logConfiguration = {
          logDriver = "awslogs",
          options   = {
            "awslogs-group"         = "/ecs/frontend",
            "awslogs-region"        = "us-west-2",
            "awslogs-stream-prefix" = "ecs"
            "awslogs-create-group"  = "true"
          }
        }
      }
    ])
      
    runtime_platform {
        operating_system_family = "LINUX"
        cpu_architecture = "X86_64"
    }
}

resource "aws_ecs_service" "frontend_service" {
  name = "frontend-service"
  cluster = aws_ecs_cluster.notesApp-cluster.id
  task_definition = aws_ecs_task_definition.frontend-task.arn
  launch_type = "FARGATE"
  desired_count = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend-tg.arn
    container_name = "frontend"
    container_port = 80
  }
  network_configuration {
    assign_public_ip = true
    subnets = data.aws_subnets.default.ids
    security_groups = [aws_security_group.alb_sg.id]
    }
}