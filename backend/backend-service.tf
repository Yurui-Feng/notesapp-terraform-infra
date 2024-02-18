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
resource "aws_lb" "backend-lb" {
    name = "backend-lb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.alb_sg.id]
    subnets = data.aws_subnets.default.ids

    enable_deletion_protection = false
}

resource "aws_lb_target_group" "backend-tg" {
    name_prefix = "bakend"
    port = 80
    protocol = "HTTP"
    target_type = "ip"
    vpc_id = data.aws_vpc.default.id
    health_check {
        path = "/health"
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
    load_balancer_arn = aws_lb.backend-lb.arn
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
    load_balancer_arn = aws_lb.backend-lb.arn
    port = "443"
    protocol = "HTTPS"
    ssl_policy = "ELBSecurityPolicy-2016-08"
    certificate_arn = data.aws_acm_certificate.backend-cert.arn
    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.backend-tg.arn
    }
}

resource "aws_security_group" "alb_sg" {
    name = "alb_sg"
    description = "Security group for the backend ALB"
    vpc_id = data.aws_vpc.default.id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        }

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        }
    
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_route53_record" "backend" {
    zone_id = data.aws_route53_zone.mydomain.zone_id
    name = "api.fuyuri.com"
    type = "CNAME"
    ttl = "300"
    records = [aws_lb.backend-lb.dns_name]
}

resource "aws_ecs_task_definition" "backend-task" {
    family = "notes"
    requires_compatibilities = ["FARGATE"]
    network_mode = "awsvpc"
    cpu = 256
    memory = 1024
    execution_role_arn = data.aws_iam_role.ecs_execution_role.arn
    task_role_arn = data.aws_iam_role.ecs_task_role.arn

    container_definitions = jsonencode([
  {
    name        = "backend",
    image       = "${data.aws_ecr_repository.backend-repo.repository_url}:${var.backend_image_tag}",
    cpu         = 256,
    memory      = 1024,
    essential   = true,
    command     = ["node", "app.js"],
    environment = [
      { name = "CLIENT_SECRET", value = var.client_secret },
      { name = "PORT", value = var.port },
      { name = "CLIENT_ID", value = var.client_id },
      { name = "GOOGLE_CALLBACK_URL", value = var.google_callback_url },
      { name = "MONGODB_URI", value = var.mongodb_uri },
      { name = "SECRET", value = var.secret },
      { name = "FRONTEND_URL", value = var.frontend_url }
    ],
    portMappings = [
      {
        containerPort = 80,
        hostPort      = 80,
        protocol      = "tcp",
        appProtocol   = "http"
      }
    ],
    logConfiguration = {
      logDriver = "awslogs",
      options   = {
        "awslogs-group"         = "/ecs/",
        "awslogs-region"        = "us-west-2",
        "awslogs-stream-prefix" = "ecs",
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

resource "aws_ecs_service" "backend_service" {
  name = "backend-service"
  cluster = aws_ecs_cluster.notesApp-cluster.id
  task_definition = aws_ecs_task_definition.backend-task.arn
  launch_type = "FARGATE"
  desired_count = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.backend-tg.arn
    container_name = "backend"
    container_port = 80
  }

  network_configuration {
    assign_public_ip = true
    subnets = data.aws_subnets.default.ids
    security_groups = [aws_security_group.alb_sg.id]
  }
}