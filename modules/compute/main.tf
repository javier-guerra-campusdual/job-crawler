data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_launch_template" "compute" {
  name_prefix   = "${var.project_name}-${var.environment}-compute-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = false
    security_groups            = [aws_security_group.compute.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.compute.name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y python3 python3-pip git jq
    pip3 install requests elasticsearch boto3 warcio
    
    # Configurar las credenciales de Elasticsearch
    mkdir -p /opt/crawler/config
    aws secretsmanager get-secret-value --secret-id elasticsearch/credentials \
      --query SecretString --output text > /opt/crawler/config/es_credentials.json
  EOF
  )

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
      volume_type = "gp3"
      encrypted   = true
    }
  }

  tags = local.common_tags
}

resource "aws_autoscaling_group" "compute" {
  name                = "${var.project_name}-${var.environment}-compute-asg"
  desired_capacity    = 2
  max_size           = 6
  min_size           = 2
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.compute.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value              = "${var.project_name}-${var.environment}-compute"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "compute" {
  name        = "${var.project_name}-${var.environment}-compute-sg"
  description = "Security group for compute nodes"
  vpc_id      = var.vpc_id
  /*ingress{
    from_port=9200
    to_port=9200
    protocol="tcp"
    security_groups=[]
  }
  ingress{
    from_port=9300
    to_port=9300
    protocol="tcp"
    security_groups=[aws_security_group.compute.id]
  }*/
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}


locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

data "aws_region" "current" {}
