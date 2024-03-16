# Security group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "lab2-alb-security-group"
  description = "Security group for lab2 ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    #security_groups = [aws_security_group.labs_lt_sg.id]
  }
}

#Security group for Launch Template
resource "aws_security_group" "labs_lt_sg" {
  name        = "labs-lt-security-group"
  description = "Security group for lab2 Launch Template"
  vpc_id      = var.vpc_id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

}

resource "aws_lb" "labs" {
  name               = "labs-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.subnet_ids
}

resource "aws_lb_target_group" "labs" {
  name     = "labs-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_listener" "labs" {
  load_balancer_arn = aws_lb.labs.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.labs.arn
  }
}

resource "aws_autoscaling_group" "labs" {
  name             = "labs-asg"
  desired_capacity = 2
  min_size         = 1
  max_size         = 3
  vpc_zone_identifier  = var.subnet_ids
  launch_template {
    id      = aws_launch_template.labs.id
    version = aws_launch_template.labs.latest_version
  }
  target_group_arns    = [aws_lb_target_group.labs.arn]
}

resource "aws_launch_template" "labs" {
  name          = "labs-lt"
  image_id      = var.ami_id
  instance_type = "t2.micro"
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 8
    }
  }
  # User data script for Nginx installation
  user_data = base64encode (<<EOF
#!/bin/bash
apt-get -y update
apt-get install -y nginx
curl -s http://169.254.169.254/latest/meta-data/instance-id > /var/www/html/index.nginx-debian.html
EOF
)
  vpc_security_group_ids = [aws_security_group.labs_lt_sg.id]
  key_name = var.ssh_key_name
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "labs" {
  zone_id = var.dns_hosted_zone_id
  name    = var.dns_site_name
  type    = "A"
  alias {
    name                   = aws_lb.labs.dns_name
    zone_id                = aws_lb.labs.zone_id
    evaluate_target_health = true
  }
}
