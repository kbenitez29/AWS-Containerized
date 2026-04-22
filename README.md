# AWS Containerized Application

## Overview

This project deploys a containerized web application on AWS using Terraform.

The infrastructure includes networking, container orchestration, and load balancing to run a scalable service on AWS.


## Architecture
The system is composed of the following components:

- Custom VPC with public and private subnets.
- Internet Gateway and NAT Gateway for network routing.
- ECS Fargate to run the application containers.
- Amazon ECR to store the Docker image.
- Application Load Balancer to expose the service.


### Traffic flow
User → ALB (Public) → ECS (Private) → Container

## Infrastructure (Terraform)
All infrastructure is defined using Terraform.

Main components:

- VPC with public and private subnets.
- Routing configuration for internet access.
- Security groups controlling ALB -> ECS communication.
- ECR repository for Docker images.
- ECS cluster, task definition, and service.
- Application Load Balancer with the target group and the listener.
  

## Application

The application is a simple Flask service running inside a Docker container.

It exposes a single HTTP endpoint that returns a response confirming the service is running.


## Deployment

1. Docker image is built locally.
2. Image is pushed to Amazon ECR.
3. ECS pulls the image and runs the container.
4. ALB routes traffic to the ECS service.
   

## CI/CD Pipeline

The project includes two separate GitHub Actions workflows to handle application and infrastructure changes independently.

### Application pipeline

When changes are pushed to the application code or Dockerfile, a pipeline is triggered that builds a new Docker image and pushes it to Amazon ECR. After that, the ECS service is updated to force a new deployment.

ECS performs a rolling update, meaning new containers are started before the old ones are stopped. This allows to have zero downtime in the application.

### Infrastructure pipeline

Infrastructure changes are handled through Terraform. Any modification inside the Terraform directory triggers a pipeline that runs `terraform init`, `plan`, and `apply`.

Terraform state is stored remotely in S3 so that each pipeline run has a broad view of the infrastructure and avoids recreating existing resources.


