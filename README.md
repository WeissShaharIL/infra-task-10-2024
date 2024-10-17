# Infrastructure Deployment

This project automates the deployment of infrastructure using Terraform and Kubernetes.

## Overview

- **Terraform Module**: Deploys either EC2 instances or Auto Scaling Groups (ASGs) with an Application Load Balancer (ALB) based on a specified configuration. The deployment can read from AWS Secrets Manager.

- **Kubernetes Manifest**: Deploys a service that utilizes the AWS CLI to read secrets from AWS Secrets Manager.

## Key Features

- Easily deploy EC2 instances or ASGs with load balancing.
- Use AWS Secrets Manager for secure secret management.
- Customizable deployment configurations through variable inputs.

## Usage

Refer to the provided `terraform.tfvars` and Kubernetes manifest files to customize your deployment.

## Contact

- **Shahar Weiss**  
  Email: [weiss.shahar.il@gmail.com](mailto:weiss.shahar.il@gmail.com)
