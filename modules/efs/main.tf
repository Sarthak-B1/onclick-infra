resource "aws_efs_file_system" "grafana_efs" {
  creation_token = "grafana-efs"
  encrypted      = true

  throughput_mode = "bursting"

  tags = merge(
    var.tags,
    {
      Name = "grafana-efs"
    }
  )
}

resource "aws_efs_mount_target" "grafana" {
  # Use a map keyed by index so keys are known during planning
  for_each = {
    for idx, subnet_id in var.private_subnet_ids : tostring(idx) => subnet_id
  }

  file_system_id = aws_efs_file_system.grafana_efs.id
  subnet_id      = each.value

  security_groups = [var.monitoring_sg_id]

  depends_on = [aws_efs_file_system.grafana_efs]
}
