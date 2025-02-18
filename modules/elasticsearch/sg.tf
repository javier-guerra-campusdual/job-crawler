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
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    #security_groups = [aws_security_group.elasticsearch_alb.id]
    cidr_blocks = ["0.0.0.0/0"]

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