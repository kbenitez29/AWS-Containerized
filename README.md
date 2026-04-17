# AWS Containerized Application

## Overview

This project is a hands-on implementation of a cloud architecture in AWS.

The goal is to build a small but realistic environment with proper networking, containerized workloads, and automated deployments using Terraform and CI/CD.

## Architecture
The infrastructure is deployed inside a custom VPC.

- Public subnets are used for internet-facing components
- Private subnets are used for internal services
- A NAT Gateway allows private resources to access the internet when needed
- Public subnets are associated with a route table that allows outbound internet access through an Internet Gateway.

## Technologies

## How It Works

## Terraform

## CI/CD Pipeline

## Design Decisions
- A NAT Gateway is used so that private resources can access the internet without being publicly exposed.
- 
## Status
- [x] Project design
- [ ] Terraform infrastructure
- [ ] Docker containerization
- [ ] CI/CD pipeline
