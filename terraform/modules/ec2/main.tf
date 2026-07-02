data "aws_iam_policy_document" "prometheus_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "prometheus_ec2_discovery" {
  statement {
    actions = [
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "elasticfilesystem:DescribeMountTargets",
      "elasticfilesystem:DescribeFileSystems"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "prometheus" {
  name               = "prometheus-ec2-role-v5"
  assume_role_policy = data.aws_iam_policy_document.prometheus_assume_role.json
  tags               = merge(var.tags, { Name = "prometheus-ec2-role-v5" })
}

resource "aws_iam_role_policy" "prometheus_ec2_discovery" {
  name   = "prometheus-ec2-policy-v5"
  role   = aws_iam_role.prometheus.id
  policy = data.aws_iam_policy_document.prometheus_ec2_discovery.json
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_iam_instance_profile" "prometheus" {
  name = "prometheus-instance-profile-v5"
  role = aws_iam_role.prometheus.name
}

locals {
  python_install_script = <<-USERDATA
    #!/bin/bash
    exec > /var/log/python-install.log 2>&1
    set -ex
    echo "=== Installing Python 3.9 ==="
    yum makecache
    yum install -y python3
    echo "=== Python 3.9 Install Complete ==="
  USERDATA
}

resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  associate_public_ip_address = true
  key_name                    = var.key_name
  user_data                   = local.python_install_script

  vpc_security_group_ids = [var.bastion_sg_id]

  tags = merge(var.tags, {
    Name = "bastion-host"
    Role = "bastion"
  })
}

resource "aws_eip" "bastion" {
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "bastion-eip"
  })
}

resource "aws_eip_association" "bastion" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion.id
}

resource "aws_ebs_volume" "prometheus_primary" {
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = var.prometheus_volume_size_gb
  type              = var.prometheus_volume_type
  encrypted         = true
  tags = merge(var.tags, {
    Name       = "prometheus-primary-volume"
    Role       = "prometheus"
    Monitoring = "prometheus-primary"
  })
}

resource "aws_volume_attachment" "prometheus_primary" {
  device_name  = "/dev/sdf"
  volume_id    = aws_ebs_volume.prometheus_primary.id
  instance_id  = aws_instance.prometheus_primary.id
  force_detach = true
}

resource "aws_instance" "prometheus_primary" {
  ami                  = var.ami_id
  instance_type        = var.instance_type
  subnet_id            = var.prometheus_primary_subnet_id
  iam_instance_profile = aws_iam_instance_profile.prometheus.name
  key_name             = var.key_name
  private_ip           = "10.0.3.10"
  user_data            = local.python_install_script

  vpc_security_group_ids = [var.monitoring_sg_id]

  root_block_device {
    encrypted = true
  }

  tags = merge(var.tags, {
    Name       = "prometheus-primary"
    Role       = "prometheus-primary"
    Monitoring = "node-exporter"
  })
}

resource "aws_ebs_volume" "prometheus_replica" {
  availability_zone = data.aws_availability_zones.available.names[1]
  size              = var.prometheus_volume_size_gb
  type              = var.prometheus_volume_type
  encrypted         = true
  tags = merge(var.tags, {
    Name       = "prometheus-replica-volume"
    Role       = "prometheus"
    Monitoring = "prometheus-replica"
  })
}

resource "aws_volume_attachment" "prometheus_replica" {
  device_name  = "/dev/sdf"
  volume_id    = aws_ebs_volume.prometheus_replica.id
  instance_id  = aws_instance.prometheus_replica.id
  force_detach = true
}

resource "aws_instance" "prometheus_replica" {
  ami                  = var.ami_id
  instance_type        = var.instance_type
  subnet_id            = var.prometheus_replica_subnet_id
  iam_instance_profile = aws_iam_instance_profile.prometheus.name
  key_name             = var.key_name
  private_ip           = "10.0.4.10"
  user_data            = local.python_install_script

  vpc_security_group_ids = [var.monitoring_sg_id]

  root_block_device {
    encrypted = true
  }

  tags = merge(var.tags, {
    Name       = "prometheus-replica"
    Role       = "prometheus-replica"
    Monitoring = "node-exporter"
  })
}

