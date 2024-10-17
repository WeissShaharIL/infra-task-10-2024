variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}
variable "apps" {
  description = "List of applications to be deployed, including EC2 or ASG configurations"
  type = list(object({
    name            = string
    deploy_type     = string
    subnets         = list(string)
    security_groups = optional(list(string), [])
    ami             = optional(string, null)
    instance_type   = optional(string, "t3.nano")
    volume_size     = optional(number, 30)
    user_data       = optional(string, null)
    iam_role        = optional(string, null)
    key_name        = optional(string, null)

    asg = optional(object({
      min     = number
      max     = number
      desired = number
    }), null)

    sg_rules = optional(list(object({
      type        = string
      protocol    = string
      from_port   = number
      to_port     = number
      cidr_blocks = list(string)
      description = string
    })), null)

    alb = optional(object({
      deploy      = bool
      subnets     = list(string)
      sg          = string
      listen_port = number
      dest_port   = number
      host        = string
      path        = string
    }), null)
  }))
}