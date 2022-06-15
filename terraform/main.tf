# ------------------------------------------------------ Terraform files ---------------------------------------------------------

# --------------------- EC2 security group ----------------------
locals {
  ports_in  = [8000]
  ports_out = [0]
}

resource "aws_security_group" "ec2_sg" {

  name        = "Nginx_security_group"
  description = "EC2 security group"
  vpc_id      = var.vpc_id_

  dynamic "ingress" {
    for_each = toset(local.ports_in)
    content {
      description = "Web Traffic from internet"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  dynamic "egress" {
    for_each = toset(local.ports_out)
    content {
      description = "Web Traffic to internet"
      from_port   = egress.value
      to_port     = egress.value
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = {
    Name = "Nginx-security-group"
  }
}

# ------------ Launch Template for EC2 Instances ----------------
resource "aws_launch_template" "ec2_template" {

  # depends_on             = [aws_security_group.ec2_sg, aws_iam_role.ec2_describe_role]
  depends_on    = [aws_security_group.ec2_sg]
  name          = "Nginx-app"
  image_id      = var.ami
  instance_type = var.instance_type

  key_name               = var.aws_key
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.volume_size
      volume_type = var.volume_type
    }
  }
}

# ------------------- Auto Scaling group ------------------------
resource "aws_autoscaling_group" "auto_scaling_group" {

  name                      = "Nginx-ASG"
  depends_on                = [aws_launch_template.ec2_template, aws_lb_target_group.lb_target_group]
  max_size                  = var.max_ec2
  min_size                  = var.min_ec2
  desired_capacity          = var.desired_ec2
  health_check_grace_period = 30
  health_check_type         = "ELB"
  force_delete              = true
  launch_template {
    id      = aws_launch_template.ec2_template.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "Nginx-ASG"
    propagate_at_launch = true
  }
  target_group_arns   = [aws_lb_target_group.lb_target_group.arn]
  vpc_zone_identifier = [var.subnet_2a, var.subnet_2b]
  # role_arn = aws_iam_role.ec2_describe_role

}

# ------------------------ Secuirty Group LB -----------------------
resource "aws_security_group" "load_balancer_sg" {

  name        = "alb_security_group"
  description = "Nginx-LB-SG"
  vpc_id      = var.vpc_id_

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-Nginx-LB"
  }
}

# ------------------ Load Balancer -----------------------------------
resource "aws_lb" "load_balancer" {

  depends_on         = [aws_security_group.load_balancer_sg]
  name               = "Nginx-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer_sg.id]
  subnets            = [var.subnet_2a, var.subnet_2b]
}

# ------------------- Target Group for Load Balancer ------------------
resource "aws_lb_target_group" "lb_target_group" {
  #   depends_on  = [aws_autoscaling_group.auto_scaling_group]
  name        = "Nginx-TG"
  port        = 8000
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id_

  health_check {
    path                = "/"
    port                = 8000
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200-499"
  }
}

# ------------------------ LB listener ----------------------------------
resource "aws_lb_listener" "lb_listener" {

  depends_on        = [aws_lb.load_balancer]
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }
}

# ------------------------ Route53 subdomain LB ------------------------
resource "aws_route53_record" "sub_domain_lb" {

  depends_on = [aws_lb.load_balancer]
  zone_id    = data.aws_route53_zone.zone.id
  name       = "${var.dns_name}.${data.aws_route53_zone.zone.name}"
  type       = "A"

  alias {
    name                   = aws_lb.load_balancer.dns_name
    zone_id                = aws_lb.load_balancer.zone_id
    evaluate_target_health = true

  }
}

# ------------------------ Null Resource - Get IPs of Remote Hosts ---------------
resource "null_resource" "get_hosts_ips" {
  triggers = {
    cluster_instance = "${aws_autoscaling_group.auto_scaling_group.id}"
  }
  provisioner "local-exec" {
    command     = <<-EOT
      /home/ubuntu/assessment/terraform-files/get-host-ip.sh ${var.aws_region} ${aws_autoscaling_group.auto_scaling_group.name}
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

# ------------------------ Null resource- Run the Ansble-playbook ----------
resource "null_resource" "ansible_run" {
  triggers = {
    order = null_resource.get_hosts_ips.id
  }
  provisioner "local-exec" {
    command     = <<-EOT
      sudo ansible-playbook --extra-vars "aws_access_key=${var.aws_access_key} aws_secret_key=${var.aws_secret_key} aws_region=${var.aws_region}" -v /home/ubuntu/assessment/files/playbook.yaml 
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}
