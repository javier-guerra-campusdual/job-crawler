
### 4. Configurar el ALB para Elasticsearch
resource "aws_lb" "elasticsearch" {
  name               = "${var.project_name}-${var.environment}-es-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elasticsearch_alb.id]
  subnets            = var.subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-es-alb"
  }
}

resource "aws_lb_target_group" "elasticsearch" {
  name     = "${var.project_name}-${var.environment}-es-tg"
  port     = 9200
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/_cluster/health"
    port                = "traffic-port"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-es-tg"
  }
}

resource "aws_lb_listener" "es_listener" {
  load_balancer_arn = aws_lb.elasticsearch.arn
  port              = 9200
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response {
      status_code     = "404"
      content_type    = "text/plain"
      message_body    = "Path not found"
    }
  }
}

resource "aws_lb_target_group_attachment" "my_target_group_attachment" {
  count               = 3
  target_group_arn    = aws_lb_target_group.elasticsearch.arn
  target_id           = aws_instance.elasticsearch_nodes[count.index].id
  port                = 9200
}


resource "aws_lb_listener_rule" "my_lb_listener_rule_web_foward" {
  listener_arn = aws_lb_listener.es_listener.arn
  priority     = 20  # Prioridad de la regla, asegúrate de que no se solape con otras

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.elasticsearch.arn
  }
  

  condition {
    path_pattern{
    values = ["/*"]
    }
  }
}