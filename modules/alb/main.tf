resource "aws_lb" "alb" {
  name               = "monitoring-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    var.alb_sg_id
  ]

  subnets = var.subnet_ids

  enable_deletion_protection = false

  tags = merge(
    var.tags,
    {
      Name = "monitoring-alb"
    }
  )
}

resource "aws_lb_target_group" "grafana_tg" {
  name     = "grafana-target-group"
  port     = var.grafana_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  target_type = "instance"

  health_check {

    enabled             = true
    interval            = 30
    path                = "/"
    port                = tostring(var.grafana_port)
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    matcher             = "200-399"
  }

  tags = merge(
    var.tags,
    {
      Name = "grafana-target-group"
    }
  )
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {

    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana_tg.arn
  }
}
