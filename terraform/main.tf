provider "aws" {
    region = "eu-west-1"
}

# Inputs to the module
module "vpc" {
    source = "./modules/vpc"
    vpc_cidr = "10.0.0.0/16"

    public_subnets = [
        "10.0.1.0/24",
        "10.0.2.0/24"
    ]

    private_subnets = [
        "10.0.3.0/24",
        "10.0.4.0/24"
    ]
}

# Creating the repo in ECR
resource "aws_ecr_repository" "app"{
    name = "my-app-repo"
    image_scanning_configuration {
    scan_on_push = true # Scanning vulnerabilities
  }
}

# Creating the role that ECS is gonna assume
resource "aws_iam_role" "ecs_execution_role"{
    name = "ECS-Execution-Role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "ecs-tasks.amazonaws.com" # ECS task is gonna assume the role
                }
            }
        ]
    })
}

# Creating the policy associated with the role
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy"{
    role = aws_iam_role.ecs_execution_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Creating ECS cluster (ECS divided into cluster, task and service), just creates the enviroment
resource "aws_ecs_cluster" "main"{
    name = "main-cluster"
}

# Creating the task definition, the blueprint of the service (defines mode, RAM, CPU, etc)
resource "aws_ecs_task_definition" "app"{
    family = "app-task"
    network_mode = "awsvpc" # Each task (container) has its own IP
    requires_compatibilities = ["FARGATE"] # Could be EC2 or serverless like here

    cpu = "256" # 1/4 of a vCPU
    memory = "512" # MiB

    execution_role_arn = aws_iam_role.ecs_execution_role.arn # Giving the role to the task

    container_definitions = jsonencode([
        {
            name = "Greetings-ecs"
            image = aws_ecr_repository.app.repository_url
            essential = true # Default

            portMappings = [
                {
                    containerPort = 80
                    hostPort = 80 # In awsvpc mode, container and host have the same port
                }
            ]
        }
    ])
}

# Creating the ECS service, responsible of keeping the stuff working, and binding it with the following created lb
resource "aws_ecs_service" "app"{

    # Defining cluster and task
    name = "app-service"
    cluster = aws_ecs_cluster.main.id
    task_definition = aws_ecs_task_definition.app.arn

    desired_count = 1 # always at least 1 container up
    launch_type = "FARGATE"

    network_configuration {
        subnets = module.vpc.private_subnets # Giving all the private subnets (output)
        security_groups = [aws_security_group.ecs_sg.id] # Connecting just with alb
        assign_public_ip = false
    }

    # Attaching the load balancer to the ecs service
    load_balancer{
        target_group_arn = aws_lb_target_group.app_target_group.arn
        container_name = "Greetings-ecs"
        container_port = 80
    }
}

# Creating the ALB SG
resource "aws_security_group" "alb_sg"{
    name = "alb-sg"
    description = "Allows http traffic in the ALB"
    vpc_id = module.vpc.vpc_id

    # Allowing HTTP
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # In order to let the "inside" establish a connection to the exterior
    egress {
        from_port = 0 # Map all the ports
        to_port = 0
        protocol = -1 # Map all the protocols
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        name = "alb_sg"
    }
}

# Creating the ECS SG
resource "aws_security_group" "ecs_sg" {
  name   = "ecs-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creating the application load balancer
resource "aws_lb" "lb" {
    name = "app-lb"
    load_balancer_type = "application"
    subnets = module.vpc.public_subnets # Defining it internet-facing
    security_groups = [aws_security_group.alb_sg.id]
}

# Creating a basic target group, it checks the ecs inside the group
resource "aws_lb_target_group" "app_target_group"{
    name = "app-tg"
    port = 80
    protocol = "HTTP"
    vpc_id = module.vpc.vpc_id
    target_type = "ip" # Mandatory mode in Fargate
}

# Creating the listener to direct the traffic to the target group
resource "aws_lb_listener" "app_listener"{
    load_balancer_arn = aws_lb.lb.arn
    port = 80
    protocol = "HTTP"
    default_action {
        type = "forward" # forwards traffic to the proper target group
        target_group_arn = aws_lb_target_group.app_target_group.arn
    }
}