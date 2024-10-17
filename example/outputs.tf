output "security_group_arns" {
  description = "ARNs of the security groups created by the module"
  value       = module.compute.security_group_arns
}

output "instance_public_dns_names" {
  description = "Public DNS addresses of the EC2 instances created by the module"
  value       = module.compute.instance_public_dns_names
}

output "instance_public_ipv4s" {
  description = "Public IP addresses of the EC2 instances created by the module"
  value       = module.compute.instance_public_ipv4s
}

output "instance_ssh_key_names" {
  description = "SSH key names used by the EC2 instances (if provided)"
  value       = module.compute.instance_ssh_key_names
}

output "asg_arns" {
  description = "ARNs of the created Auto Scaling Groups"
  value       = module.compute.asg_arns
}

output "alb_arns" {
  description = "ARNs of the created Application Load Balancers"
  value       = module.compute.alb_arns
}

output "alb_dns_names" {
  description = "DNS names of the created Application Load Balancers"
  value       = module.compute.alb_dns_names
}

output "alb_listener_arns" {
  description = "ARNs of the listeners attached to the Application Load Balancers"
  value       = module.compute.alb_listener_arns
}