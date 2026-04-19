provider "aws" {
    region = "eu-west-1"
}

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
                    Service = "ecs-task.amazonaws.com" # ECS task is gonna assume the role
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
    network_mode = "awsvpc"
    requires_compatibilities = ["FARGATE"] # Could be EC2 or serverless like here
}
