terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  default     = "production"
}

resource "aws_ecs_cluster" "microkernel" {
  name = "microkernel-${var.environment}"
}

resource "aws_ecs_task_definition" "server" {
  family                   = "microkernel-server"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  
  container_definitions = jsonencode([{
    name  = "server"
    image = "microkernel/server:latest"
    portMappings = [{
      containerPort = 4000
      protocol      = "tcp"
    }]
    environment = [
      { name = "DATABASE_URL", value = var.database_url },
      { name = "SECRET_KEY_BASE", value = var.secret_key_base }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.microkernel.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "server"
      }
    }
  }])
}

resource "aws_ecs_service" "server" {
  name            = "microkernel-server"
  cluster         = aws_ecs_cluster.microkernel.id
  task_definition = aws_ecs_task_definition.server.arn
  desired_count   = 3
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.server.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.server.arn
    container_name   = "server"
    container_port   = 4000
  }
}

resource "aws_lb" "microkernel" {
  name               = "microkernel-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "server" {
  name     = "microkernel-server"
  port     = 4000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }
}

resource "aws_lb_listener" "server" {
  load_balancer_arn = aws_lb.microkernel.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.server.arn
  }
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

resource "aws_security_group" "server" {
  name   = "microkernel-server"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "lb" {
  name   = "microkernel-lb"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
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

resource "aws_cloudwatch_log_group" "microkernel" {
  name              = "/ecs/microkernel"
  retention_in_days = 7
}

data "aws_availability_zones" "available" {
  state = "available"
}

variable "database_url" {
  description = "Database connection URL"
  type        = string
  sensitive   = true
}

variable "secret_key_base" {
  description = "Secret key base for Phoenix"
  type        = string
  sensitive   = true
}

output "load_balancer_dns" {
  value = aws_lb.microkernel.dns_name
}

