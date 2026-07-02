output "efs_id" {
  value = aws_efs_file_system.grafana_efs.id
}

output "efs_dns_name" {
  value = aws_efs_file_system.grafana_efs.dns_name
}

output "efs_mount_target_ids" {
  value = values(aws_efs_mount_target.grafana)[*].id
}
