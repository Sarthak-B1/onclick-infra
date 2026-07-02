locals {
  common_tags = {
    Owner       = "Sarthak Bhatnagar"
    Project     = "Monitoring Infrastructure"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr         = var.vpc_cidr
  public_subnet_1  = var.public_subnet_1
  public_subnet_2  = var.public_subnet_2
  private_subnet_1 = var.private_subnet_1
  private_subnet_2 = var.private_subnet_2

  tags = local.common_tags
}

module "security_group" {
  source = "./modules/security-group"

  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = var.vpc_cidr
  allowed_ssh_cidr   = var.allowed_ssh_cidr
  prometheus_port    = var.prometheus_port
  node_exporter_port = var.node_exporter_port

  tags = local.common_tags
}

module "ec2" {
  source = "./modules/ec2"

  key_name = var.key_name

  ami_id        = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  aws_region = var.aws_region

  public_subnet_id = module.vpc.public_subnet_1_id

  prometheus_primary_subnet_id = module.vpc.private_subnet_1_id
  prometheus_replica_subnet_id = module.vpc.private_subnet_2_id

  prometheus_volume_size_gb = var.prometheus_volume_size_gb
  prometheus_volume_type    = var.prometheus_volume_type

  bastion_sg_id    = module.security_group.bastion_sg_id
  monitoring_sg_id = module.security_group.monitoring_sg_id

  tags = local.common_tags
}


module "efs" {
  source = "./modules/efs"

  private_subnet_ids = module.vpc.private_subnet_ids
  monitoring_sg_id   = module.security_group.monitoring_sg_id

  tags = local.common_tags
}

module "alb" {
  source = "./modules/alb"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id  = module.security_group.alb_sg_id

  grafana_port = var.grafana_port

  tags = local.common_tags
}

module "autoscaling" {
  source = "./modules/autoscaling"

  ami_id        = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  aws_region         = var.aws_region
  private_subnet_ids = module.vpc.private_subnet_ids
  monitoring_sg_id   = module.security_group.monitoring_sg_id

  target_group_arn   = module.alb.target_group_arn
  efs_file_system_id = module.efs.efs_id
  grafana_port       = var.grafana_port
  node_exporter_port = var.node_exporter_port
  min_size           = var.grafana_min_size
  desired_capacity   = var.grafana_desired_capacity
  max_size           = var.grafana_max_size

  key_name = var.key_name
  tags     = local.common_tags

  depends_on = [
    module.efs
  ]
}
