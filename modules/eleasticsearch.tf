# modules/elasticsearch_ec2/variables.tf
variable "project_name" {
  type        = string
  description = "Nombre del proyecto"
}

variable "environment" {
  type        = string
  description = "Ambiente (dev/prod)"
}

variable "vpc_id" {
  type        = string
  description = "ID de la VPC"
}

variable "subnet_ids" {
  type        = list(string)
  description = "IDs de las subnets privadas"
}

variable "instance_type" {
  type        = string
  description = "Tipo de instancia EC2"
  default     = "t3.xlarge"
}

variable "elasticsearch_version" {
  type        = string
  description = "Versión de Elasticsearch"
  default     = "7.10.2"
}

variable "volume_size" {
  type        = number
  description = "Tamaño del volumen EBS en GB"
  default     = 100
}

# modules/elasticsearch_ec2/main.tf
# Security Group para Elasticsearch
resource "aws_security_group" "elasticsearch" {
  name        = "${var.project_name}-${var.environment}-es-sg"
  description = "Security group for Elasticsearch cluster"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
    description = "Elasticsearch REST API"
  }

  ingress {
    from_port   = 9300
    to_port     = 9300
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
    description = "Elasticsearch node communication"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-es-sg"
  }
}

# IAM role para EC2
resource "aws_iam_role" "elasticsearch" {
  name = "${var.project_name}-${var.environment}-es-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM instance profile
resource "aws_iam_instance_profile" "elasticsearch" {
  name = "${var.project_name}-${var.environment}-es-profile"
  role = aws_iam_role.elasticsearch.name
}

# Launch Template para Elasticsearch
resource "aws_launch_template" "elasticsearch" {
  name_prefix   = "${var.project_name}-${var.environment}-es-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = false
    security_groups            = [aws_security_group.elasticsearch.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.elasticsearch.name
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Instalar Java
              amazon-linux-extras install java-openjdk11

              # Instalar Elasticsearch
              rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
              echo "[elasticsearch]" > /etc/yum.repos.d/elasticsearch.repo
              echo "name=Elasticsearch repository" >> /etc/yum.repos.d/elasticsearch.repo
              echo "baseurl=https://artifacts.elastic.co/packages/7.x/yum" >> /etc/yum.repos.d/elasticsearch.repo
              echo "gpgcheck=1" >> /etc/yum.repos.d/elasticsearch.repo
              echo "gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch" >> /etc/yum.repos.d/elasticsearch.repo
              echo "enabled=1" >> /etc/yum.repos.d/elasticsearch.repo

              yum install -y elasticsearch-${var.elasticsearch_version}

              # Configurar Elasticsearch
              cat << 'CONF' > /etc/elasticsearch/elasticsearch.yml
              cluster.name: ${var.project_name}-${var.environment}
              node.name: ${HOSTNAME}
              path.data: /var/lib/elasticsearch
              path.logs: /var/log/elasticsearch
              network.host: 0.0.0.0
              discovery.seed_hosts: ["localhost"]
              cluster.initial_master_nodes: ["${HOSTNAME}"]
              CONF

              # Iniciar Elasticsearch
              systemctl daemon-reload
              systemctl enable elasticsearch.service
              systemctl start elasticsearch.service
              EOF
  )

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.volume_size
      volume_type = "gp3"
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-es"
  }
}

# Auto Scaling Group para Elasticsearch
resource "aws_autoscaling_group" "elasticsearch" {
  name                = "${var.project_name}-${var.environment}-es-asg"
  desired_capacity    = 3
  max_size           = 5
  min_size           = 3
  target_group_arns  = [aws_lb_target_group.elasticsearch.arn]
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.elasticsearch.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-es"
    propagate_at_launch = true
  }
}

# Application Load Balancer
resource "aws_lb" "elasticsearch" {
  name               = "${var.project_name}-${var.environment}-es-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elasticsearch_alb.id]
  subnets           = var.subnet_ids
}

# Target Group
resource "aws_lb_target_group" "elasticsearch" {
  name     = "${var.project_name}-${var.environment}-es-tg"
  port     = 9200
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher            = "200"
    path               = "/_cluster/health"
    port               = "traffic-port"
    timeout            = 5
    unhealthy_threshold = 3
  }
}

# Outputs
output "elasticsearch_endpoint" {
  value = aws_lb.elasticsearch.dns_name
}