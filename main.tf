resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

data "aws_route_table" "vpc-rt" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route" "internet_access" {
  route_table_id         = data.aws_route_table.vpc-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "subnet_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
}

# Security group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "lab2-alb-security-group"
  description = "Security group for lab2 ALB"
  vpc_id      = aws_vpc.vpc.id

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
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Security group for Launch Template
resource "aws_security_group" "labs_lt_sg" {
  name        = "labs-lt-security-group"
  description = "Security group for lab2 Launch Template"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  # Next rule is only needed for ec2 troubleshooting via SSH
  #ingress {
  #     from_port   = 22
  #     to_port     = 22
  #     protocol    = "tcp"
  #     cidr_blocks = ["0.0.0.0/0"]
  #   }
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# Create Application Load Balancer
resource "aws_lb" "labs" {
  name               = "labs-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]
}

# Create Target Group for ALB
resource "aws_lb_target_group" "labs" {
  name     = "labs-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
}
# Create HTTPS Listener
resource "aws_lb_listener" "labs_https" {
  load_balancer_arn = aws_lb.labs.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.lab2.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.labs.arn
  }
}
# Create HTTP listener with HTTP->HTTPS redirect
resource "aws_lb_listener" "labs_http" {
  load_balancer_arn = aws_lb.labs.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Create AWS ASG 
resource "aws_autoscaling_group" "labs" {
  name                = "labs-asg"
  desired_capacity    = 2
  min_size            = 1
  max_size            = 3
  vpc_zone_identifier = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]
  launch_template {
    id      = aws_launch_template.labs.id
    version = aws_launch_template.labs.latest_version
  }
  target_group_arns = [aws_lb_target_group.labs.arn]
}

# Create IAM Role and Instance Profile for EC2
resource "aws_iam_role" "lab2_ec2_role" {
  name = "lab2-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the AmazonSSMManagedInstanceCore policy to the role
resource "aws_iam_role_policy_attachment" "lab2_ec2_policy" {
  role       = aws_iam_role.lab2_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create an instance profile for the EC2 instance
resource "aws_iam_instance_profile" "lab2_ec2_profile" {
  name = "lab2-ec2-profile"
  role = aws_iam_role.lab2_ec2_role.name
}

# Create Launch template for Target Group
resource "aws_launch_template" "labs" {
  name          = "labs-lt"
  image_id      = var.ami_id
  instance_type = "t2.nano"
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 8
    }
  }
  # User data script for Nginx installation
  user_data = base64encode(<<EOF
#!/bin/bash
apt-get -y update
apt-get install -y nginx
curl -s http://169.254.169.254/latest/meta-data/instance-id > /var/www/html/index.nginx-debian.html
EOF
  )
  key_name                = var.ssh_key_name
  network_interfaces {
    security_groups             = [aws_security_group.labs_lt_sg.id]
    associate_public_ip_address = true
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.lab2_ec2_profile.name
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Create DNS A-record for site:
resource "aws_route53_record" "lab2site" {
  zone_id = var.dns_hosted_zone_id
  name    = var.dns_site_name
  type    = "A"
  alias {
    name                   = aws_lb.labs.dns_name
    zone_id                = aws_lb.labs.zone_id
    evaluate_target_health = true
  }
}
# Create and validate ACM TLS certificate
resource "aws_acm_certificate" "lab2" {
  domain_name       = var.dns_site_name
  validation_method = "DNS"
}
resource "aws_route53_record" "lab2" {
  for_each = {
    for dvo in aws_acm_certificate.lab2.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.dns_hosted_zone_id
}
resource "aws_acm_certificate_validation" "lab2" {
  certificate_arn         = aws_acm_certificate.lab2.arn
  validation_record_fqdns = [for record in aws_route53_record.lab2 : record.fqdn]
}
