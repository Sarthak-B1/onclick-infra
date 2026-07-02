resource "aws_launch_template" "grafana_lt" {
  name_prefix   = "grafana-launch-template"
  image_id      = var.ami_id
  instance_type = var.instance_type

  key_name = var.key_name

  update_default_version = true

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  vpc_security_group_ids = [
    var.monitoring_sg_id
  ]

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tftpl", {
    aws_region         = var.aws_region
    efs_file_system_id = var.efs_file_system_id
    grafana_port       = var.grafana_port
    node_exporter_port = var.node_exporter_port
  }))

  tag_specifications {

    resource_type = "instance"

    tags = merge(
      var.tags,
      {
        Name       = "grafana-asg-instance"
        Role       = "grafana"
        Monitoring = "node-exporter"
      }
    )
  }

  tags = merge(
    var.tags,
    {
      Name = "grafana-launch-template"
    }
  )
}

resource "aws_autoscaling_group" "grafana_asg" {
  name = "grafana-asg-v5"

  desired_capacity = var.desired_capacity
  max_size         = var.max_size
  min_size         = var.min_size

  vpc_zone_identifier = var.private_subnet_ids

  target_group_arns = var.target_group_arn != "" ? [var.target_group_arn] : []

  health_check_type         = "ELB"
  health_check_grace_period = 900
  protect_from_scale_in     = false

  launch_template {
    id      = aws_launch_template.grafana_lt.id
    version = aws_launch_template.grafana_lt.latest_version
  }

  wait_for_capacity_timeout = "0"

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["tag"]
  }

  tag {

    key                 = "Name"
    value               = "grafana-asg"
    propagate_at_launch = true
  }

  tag {

    key                 = "Environment"
    value               = "Production"
    propagate_at_launch = true
  }

  tag {

    key                 = "ManagedBy"
    value               = "Terraform"
    propagate_at_launch = true
  }

  tag {

    key                 = "Owner"
    value               = "Sarthak Bhatnagar"
    propagate_at_launch = true
  }

  tag {

    key                 = "Project"
    value               = "Monitoring Infrastructure"
    propagate_at_launch = true
  }

  tag {

    key                 = "Role"
    value               = "grafana"
    propagate_at_launch = true
  }

  tag {

    key                 = "Monitoring"
    value               = "node-exporter"
    propagate_at_launch = true
  }
}
