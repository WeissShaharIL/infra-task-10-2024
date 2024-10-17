# Output the ARNs of the created security groups
output "security_group_arns" {
  description = "ARNs of the created security groups"
  value       = { for sg in aws_security_group.this : sg.id => sg.arn }
}

# Output the public DNS names of the created EC2 instances
output "instance_public_dns_names" {
  description = "Public DNS names of the created EC2 instances"
  value       = { for instance in aws_instance.this : instance.id => instance.public_dns }
}

# Output the public IPv4 addresses of the created EC2 instances
output "instance_public_ipv4s" {
  description = "Public IPv4 addresses of the created EC2 instances"
  value       = { for instance in aws_instance.this : instance.id => instance.public_ip }
}

# Output the SSH key names used by the EC2 instances (if provided)
output "instance_ssh_key_names" {
  description = "SSH key names used by the EC2 instances (if provided)"
  value       = { for instance in aws_instance.this : instance.id => instance.key_name }
}

output "asg_arns" {
  description = "ARNs of the created Auto Scaling Groups"
  value       = { for asg in aws_autoscaling_group.this : asg.id => asg.arn }
}

output "alb_arns" {
  description = "ARNs of the created Application Load Balancers"
  value       = { for alb in aws_lb.this : alb.id => alb.arn }
}

output "alb_dns_names" {
  description = "DNS names of the created Application Load Balancers"
  value       = { for alb in aws_lb.this : alb.id => alb.dns_name }
}

output "alb_listener_arns" {
  description = "ARNs of the listeners attached to the Application Load Balancers"
  value       = { for listener in aws_lb_listener.this : listener.id => listener.arn }
}