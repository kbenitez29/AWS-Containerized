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

In construction

