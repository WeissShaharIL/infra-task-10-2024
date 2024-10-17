
# Terraform Compute Module

This Terraform module is designed to manage the deployment of EC2 instances and Auto Scaling Groups (ASG) with optional support for Application Load Balancers (ALB). It includes configuration options for security groups, key pairs, user data, and more.

## Features

- Deploy **EC2 instances** or **Auto Scaling Groups**.
- Configure **Security Groups** with custom ingress/egress rules.
- Automatically fetch the latest **Amazon Linux 2 AMI**.
- Manage **IAM instance profiles** for EC2 and ASG instances.
- Optional support for **Application Load Balancers (ALB)** with target groups and listeners.
- Supports **user data scripts** for configuring instances on launch.
- Optionally attach an **SSH key pair** to EC2 or ASG instances.

## Usage

To use this module, create a `main.tf` file in your project that consumes the module:

```hcl
module "compute" {
  source      = "../"  # Adjust the path if necessary
  apps        = var.apps
  common_tags = var.common_tags
}
```

### Example `terraform.tfvars`

```hcl
apps = [
  {
    name            = "microsoft-ec2"
    deploy_type     = "EC2"
    subnets         = ["subnet-0c0f1005e39418feb", "subnet-05c9c85b07fe721a9"]
    ami             = null
    instance_type   = "t3.micro"
    volume_size     = 30
    user_data       = "#!/bin/bash yum update -y && amazon-linux-extras install nginx1.12 -y && systemctl start nginx && systemctl enable nginx"
    iam_role        = "arn:aws:iam::123456789012:role/test-role"
    key_name        = "my-key-pair"

    sg_rules = [
      {
        type        = "ingress"
        protocol    = "tcp"
        from_port   = 80
        to_port     = 80
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow HTTP traffic"
      },
      {
        type        = "ingress"
        protocol    = "tcp"
        from_port   = 22
        to_port     = 22
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow SSH traffic"
      },
      {
        type        = "egress"
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow all egress traffic"
      }
    ]
  },
  {
    name            = "microsoft-asg"
    deploy_type     = "ASG"
    subnets         = ["subnet-0c0f1005e39418feb", "subnet-05c9c85b07fe721a9"]
    ami             = null
    instance_type   = "t3.micro"
    volume_size     = 30
    user_data       = "#!/bin/bash yum update -y && amazon-linux-extras install nginx1.12 -y && systemctl start nginx && systemctl enable nginx"
    iam_role        = "arn:aws:iam::123456789012:role/test-role"
    key_name        = "my-key-pair"

    asg = {
      min     = 1
      max     = 3
      desired = 2
    }

    sg_rules = [
      {
        type        = "ingress"
        protocol    = "tcp"
        from_port   = 80
        to_port     = 80
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow HTTP traffic"
      },
      {
        type        = "ingress"
        protocol    = "tcp"
        from_port   = 22
        to_port     = 22
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow SSH traffic"
      }
    ]

    alb = {
      deploy      = true
      subnets     = ["subnet-0c0f1005e39418feb", "subnet-05c9c85b07fe721a9"]
      sg          = "sg-0c38438ac6a70dc5d"
      listen_port = 80
      dest_port   = 80
      host        = "microsoft-asg.com"
      path        = "/"
    }
  }
]

common_tags = {
  Environment = "dev"
  Project     = "ExampleProject"
}
```

### Variables

| Name         | Description                                         | Type   | Default      | Required |
|--------------|-----------------------------------------------------|--------|--------------|----------|
| `apps`       | List of applications with EC2 or ASG configurations | `list` | n/a          | Yes      |
| `common_tags`| Common tags to apply to all resources               | `map`  | `{}`         | Yes      |

### Application Object Structure

Each application in the `apps` list can have the following structure:

| Name             | Description                                                       | Type     | Default   | Required |
|------------------|-------------------------------------------------------------------|----------|-----------|----------|
| `name`           | The name of the application                                       | `string` | n/a       | Yes      |
| `deploy_type`    | Deployment type (`EC2` or `ASG`)                                  | `string` | n/a       | Yes      |
| `subnets`        | List of subnet IDs where the instances will be deployed           | `list`   | n/a       | Yes      |
| `ami`            | AMI ID for the instances                                           | `string` | `null`    | No       |
| `instance_type`  | EC2 instance type                                                  | `string` | `t3.nano` | No       |
| `volume_size`    | Size of the instance volume in GB                                  | `number` | 30        | No       |
| `user_data`      | User data script for provisioning the instances                    | `string` | `null`    | No       |
| `iam_role`       | IAM role for the instances                                         | `string` | n/a       | Yes      |
| `key_name`       | Optional SSH key pair name                                         | `string` | `null`    | No       |
| `asg`            | Configuration for Auto Scaling Group                               | `object` | `null`    | No       |
| `sg_rules`       | List of security group rules for the instances                     | `list`   | `null`    | No       |
| `alb`            | Configuration for Application Load Balancer (if deploying ASG)     | `object` | `null`    | No       |

### Outputs

| Name                       | Description                                                |
|----------------------------|------------------------------------------------------------|
| `security_group_arns`       | ARNs of the created security groups                        |
| `instance_public_dns_names` | Public DNS names of the created EC2 instances              |
| `instance_public_ipv4s`     | Public IPv4 addresses of the created EC2 instances         |
| `instance_ssh_key_names`    | SSH key names used by the EC2 instances (if provided)      |
| `asg_arns`                  | ARNs of the created Auto Scaling Groups                    |
| `alb_arns`                  | ARNs of the created Application Load Balancers             |
| `alb_dns_names`             | DNS names of the created Application Load Balancers        |
| `alb_listener_arns`         | ARNs of the listeners attached to the Load Balancers       |


### Example Usage with Outputs

After applying the Terraform configuration, you can output the relevant information like the public IP addresses and security group ARNs:

```hcl
output "instance_public_ips" {
  value = module.compute.instance_public_ipv4s
}

output "security_group_arns" {
  value = module.compute.security_group_arns
}
```

### How to Apply

1. Initialize Terraform:

   ```bash
   terraform init
   ```

2. Plan the infrastructure changes:

   ```bash
   terraform plan
   ```

3. Apply the changes:

   ```bash
   terraform apply
   ```

4. Destroy the infrastructure when you are done:

   ```bash
   terraform destroy
   ```

### Requirements

- **Terraform** v1.0+
- **AWS CLI** configured with access to the appropriate AWS account

## Contact

- **Shahar Weiss**  
  Email: [weiss.shahar.il@gmail.com](mailto:weiss.shahar.il@gmail.com)