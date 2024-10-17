data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_subnet" "this" {
  for_each = { for app in var.apps : app.name => app if app.sg_rules != null }
  id       = each.value.subnets[0] # Use the first subnet in the list
}

resource "aws_security_group" "this" {
  for_each    = { for app in var.apps : app.name => app if app.sg_rules != null }
  name        = "${each.value.name}-${element(split("/", each.value.iam_role), 1)}-${each.value.deploy_type}-sg"
  description = "Security group for ${each.value.name}"
  vpc_id      = data.aws_subnet.this[each.key].vpc_id

  dynamic "ingress" {
    for_each = each.value.sg_rules != null ? [for rule in each.value.sg_rules : rule if rule.type == "ingress"] : []
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  dynamic "egress" {
    for_each = each.value.sg_rules != null ? [for rule in each.value.sg_rules : rule if rule.type == "egress"] : []
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = egress.value.description
    }
  }

  tags = merge(
    var.common_tags,
    { Name = "${each.value.name}-sg" }
  )
}

resource "aws_iam_instance_profile" "this" {
  for_each = { for app in var.apps : app.name => app if app.iam_role != null }
  name     = "${each.value.name}-profile"
  role     = element(split("/", each.value.iam_role), 1)
}

####################################
# DEPLOY TYPE == EC2
####################################

resource "aws_instance" "this" {
  for_each      = { for app in var.apps : app.name => app if app.deploy_type == "EC2" }
  ami           = coalesce(each.value.ami, data.aws_ami.latest_amazon_linux.id)
  instance_type = each.value.instance_type
  subnet_id     = each.value.subnets[0]
  key_name      = each.value.key_name != null ? each.value.key_name : null

  # Merge the existing security groups with the newly created one (if sg_rules are not null)
  vpc_security_group_ids = concat(
    each.value.security_groups,
    each.value.sg_rules != null ? [aws_security_group.this[each.key].id] : []
  )

  iam_instance_profile = aws_iam_instance_profile.this[each.key].name
  user_data            = each.value.user_data != null ? base64encode(each.value.user_data) : null
  tags = merge(
    var.common_tags,
    { Name = each.value.name }
  )
}

####################################
# DEPLOY TYPE == ASG
####################################

# Create a Launch Template for the ASG
resource "aws_launch_template" "this" {
  for_each      = { for app in var.apps : app.name => app if app.deploy_type == "ASG" }
  name_prefix   = "${each.value.name}-${each.value.deploy_type}-launch-template"
  image_id      = coalesce(each.value.ami, data.aws_ami.latest_amazon_linux.id)
  instance_type = each.value.instance_type
  key_name      = each.value.key_name != null ? each.value.key_name : null
  vpc_security_group_ids = concat(
    each.value.security_groups,
    each.value.sg_rules != null ? [aws_security_group.this[each.key].id] : []
  )

  user_data = each.value.user_data != null ? base64encode(each.value.user_data) : null
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = each.value.volume_size
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.this[each.key].name
  }

  tags = merge(
    var.common_tags,
    { Name = "${each.value.name}-launch-template" }
  )
}

resource "aws_lb_target_group" "this" {
  for_each = { for app in var.apps : app.name => app if app.deploy_type == "ASG" && app.alb != null }
  name     = "${each.value.name}-tg"
  port     = each.value.alb.dest_port
  protocol = "HTTP"
  vpc_id   = data.aws_subnet.this[each.key].vpc_id

  health_check {
    path                = each.value.alb.path
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    protocol            = "HTTP"
  }

  tags = merge(
    var.common_tags,
    { Name = "${each.value.name}-tg" }
  )
}

resource "aws_autoscaling_group" "this" {
  for_each            = { for app in var.apps : app.name => app if app.deploy_type == "ASG" }
  name                = "${each.value.name}-asg"
  desired_capacity    = each.value.asg.desired
  max_size            = each.value.asg.max
  min_size            = each.value.asg.min
  vpc_zone_identifier = each.value.subnets

  launch_template {
    id      = aws_launch_template.this[each.key].id
    version = "$Latest"
  }

  target_group_arns         = [aws_lb_target_group.this[each.key].arn]
  health_check_type         = "EC2"
  health_check_grace_period = 300

  
  tag {
    key                 = "Name"
    value               = "${each.value.name}-asg"
    propagate_at_launch = true
  }

 # Loop through common tags and add them as tag blocks
  dynamic "tag" {
    for_each = var.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }


  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "this" {
  for_each = { for app in var.apps : app.name => app if app.deploy_type == "ASG" && app.alb != null }

  name               = "${each.value.name}-lb"
  internal           = false
  load_balancer_type = "application"

  security_groups = concat([each.value.alb.sg], each.value.sg_rules != null ? [aws_security_group.this[each.key].id] : [])

  subnets = each.value.alb.subnets

  tags = merge(
    var.common_tags,
    { Name = "${each.value.name}-lb" }
  )
}

resource "aws_lb_listener" "this" {
  for_each = { for app in var.apps : app.name => app if app.deploy_type == "ASG" && app.alb != null }

  load_balancer_arn = aws_lb.this[each.key].arn
  port              = each.value.alb.listen_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }
  tags = merge(
    var.common_tags,
    { Name = "${each.value.name}-lb-listener" }
  )
}