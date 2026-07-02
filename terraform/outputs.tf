output "alb_dns_name" {

  value = module.alb.alb_dns_name
}

output "bastion_public_ip" {

  value = module.ec2.bastion_public_ip
}

output "prometheus_primary_ip" {
  value = module.ec2.prometheus_primary_ip
}

output "prometheus_replica_ip" {
  value = module.ec2.prometheus_replica_ip
}


output "efs_id" {

  value = module.efs.efs_id
}

output "grafana_asg_name" {

  value = module.autoscaling.autoscaling_group_name
}

output "project_owner" {

  value = "Sarthak Bhatnagar"
}
