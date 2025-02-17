### 1. Crear el Secreto en AWS Secrets Manager
resource "aws_secretsmanager_secret" "es_credentials" {
  #name = "${var.project_name}/${var.environment}/elasticsearch/credentials"
  name = "elasticsearch/credentials"
}

resource "aws_secretsmanager_secret_version" "es_credentials" {
  secret_id = aws_secretsmanager_secret.es_credentials.id
  secret_string = jsonencode({
    username = var.username
    password = var.password
  })
}

### 2. Leer las Credenciales en Terraform
data "aws_secretsmanager_secret_version" "es_creds" {
  secret_id = aws_secretsmanager_secret.es_credentials.id
}

locals {
  es_creds = jsondecode(data.aws_secretsmanager_secret_version.es_creds.secret_string)
}

### 3. Launch Template para Elasticsearch con Autenticación
resource "aws_launch_template" "elasticsearch" {
  name_prefix   = "${var.project_name}-${var.environment}-es-"
  image_id      = "ami-0076be86944570bff"
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.elasticsearch.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.elasticsearch.name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    amazon-linux-extras install java-openjdk11 -y

    rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
    cat << REPO > /etc/yum.repos.d/elasticsearch.repo
    [elasticsearch]
    name=Elasticsearch repository
    baseurl=https://artifacts.elastic.co/packages/7.x/yum
    gpgcheck=1
    gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
    enabled=1
    REPO

    yum install -y elasticsearch-${var.elasticsearch_version}

    cat << CONF > /etc/elasticsearch/elasticsearch.yml
    cluster.name: ${var.project_name}-${var.environment}
    node.name: \$HOSTNAME
    path.data: /var/lib/elasticsearch
    path.logs: /var/log/elasticsearch
    network.host: 0.0.0.0
    discovery.seed_hosts: ["localhost"]
    cluster.initial_master_nodes: [\$HOSTNAME]
    xpack.security.enabled: true
    xpack.security.authc.api_key.enabled: true
    CONF

    systemctl daemon-reload
    systemctl enable elasticsearch.service
    systemctl start elasticsearch.service

    sleep 30

    ES_USERNAME="${local.es_creds.username}"
    ES_PASSWORD="${local.es_creds.password}"

    curl -X POST "http://localhost:9200/_security/user/\$ES_USERNAME" -H "Content-Type: application/json" -d '{
      "password": "'\$ES_PASSWORD'",
      "roles": [ "superuser" ],
      "full_name": "Elastic Admin"
    }'
  EOF
  )

  /*
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    es_cluster_name = "${var.project_name}-${var.environment}"
    es_version      = var.elasticsearch_version
    es_username     = jsondecode(aws_secretsmanager_secret_version.es_credentials.secret_string).username
    es_password     = jsondecode(aws_secretsmanager_secret_version.es_credentials.secret_string).password
  }))
  */

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
    value              = "${var.project_name}-${var.environment}-es"
    propagate_at_launch = true
  }
}



### 6. Security Groups
resource "aws_security_group" "elasticsearch" {
  name        = "${var.project_name}-${var.environment}-es-sg"
  description = "SG for Elasticsearch"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    security_groups = [aws_security_group.elasticsearch_alb.id]
    #cidr_blocks = ["0.0.0.0/0"]
    description = "Elasticsearch REST API"
  }
  
  # Elasticsearch internal comunication
  ingress {
    from_port   = 9300
    to_port     = 9300
    protocol    = "tcp"    
    self = true
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

resource "aws_security_group" "elasticsearch_alb" {
  name        = "${var.project_name}-${var.environment}-es-alb-sg"
  description = "SG for Elasticsearch ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    #security_groups = [aws_security_group.elasticsearch.id]
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-es-alb-sg"
  }
}

### 7. Acceder con Credenciales
output "es_access" {
  value = "curl -u \"${local.es_creds.username}:${local.es_creds.password}\" http://${aws_lb.elasticsearch.dns_name}:9200"
  sensitive = true
}

