output "bastion_public_ip" {
  value = aws_eip.bastion.public_ip
}
output "prometheus_primary_ip" {
  value = aws_instance.prometheus_primary.private_ip
}
output "prometheus_replica_ip" {
  value = aws_instance.prometheus_replica.private_ip
}
