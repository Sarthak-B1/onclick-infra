# Bastion Security Group

resource "aws_security_group" "bastion_sg" {

  name   = "bastion-sg-v2"
  vpc_id = var.vpc_id

  ingress {

    description = "SSH Access"

    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {

    description = "Outbound Traffic"

    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "bastion-security-group"
    }
  )
}

# ALB Security Group

resource "aws_security_group" "alb_sg" {

  name   = "alb-sg-v2"
  vpc_id = var.vpc_id

  ingress {

    description = "HTTP Access"

    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {

    description = "HTTPS Access"

    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {

    description = "Outbound Traffic"

    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "alb-security-group"
    }
  )
}

# Monitoring Security Group

resource "aws_security_group" "monitoring_sg" {

  name   = "monitoring-sg-v2"
  vpc_id = var.vpc_id

  ingress {

    description = "Grafana Access From ALB"

    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {

    description = "Prometheus Access"

    from_port   = var.prometheus_port
    to_port     = var.prometheus_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {

    description = "EFS Mount Access"

    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {

    description = "Node Exporter Access"

    from_port   = var.node_exporter_port
    to_port     = var.node_exporter_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {

    description = "SSH From Bastion"

    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {

    description = "Outbound Traffic"

    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "monitoring-security-group"
    }
  )
}
