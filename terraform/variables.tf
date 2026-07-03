variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "ap-south-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d{1}$", var.aws_region))
    error_message = "AWS region must be a valid region format (e.g., ap-south-1)."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC. Must be a valid IPv4 CIDR block."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_1" {
  description = "CIDR block for public subnet 1."
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrhost(var.public_subnet_1, 0))
    error_message = "Public subnet 1 CIDR must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_2" {
  description = "CIDR block for public subnet 2."
  type        = string
  default     = "10.0.2.0/24"

  validation {
    condition     = can(cidrhost(var.public_subnet_2, 0))
    error_message = "Public subnet 2 CIDR must be a valid IPv4 CIDR block."
  }
}

variable "private_subnet_1" {
  description = "CIDR block for private subnet 1."
  type        = string
  default     = "10.0.3.0/24"

  validation {
    condition     = can(cidrhost(var.private_subnet_1, 0))
    error_message = "Private subnet 1 CIDR must be a valid IPv4 CIDR block."
  }
}

variable "key_name" {
  type = string
}


variable "private_subnet_2" {
  description = "CIDR block for private subnet 2."
  type        = string
  default     = "10.0.4.0/24"

  validation {
    condition     = can(cidrhost(var.private_subnet_2, 0))
    error_message = "Private subnet 2 CIDR must be a valid IPv4 CIDR block."
  }
}

variable "instance_type" {
  description = "EC2 instance type for monitoring servers."
  type        = string
  default     = "t3.micro"

  validation {
    condition     = can(regex("^t[2-3]\\.(nano|micro|small|medium|large)$", var.instance_type))
    error_message = "Instance type must be a valid t2 or t3 type (nano, micro, small, medium, large)."
  }
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the bastion host."
  type        = string
  default     = "203.0.113.10/32"

  validation {
    condition     = can(cidrhost(var.allowed_ssh_cidr, 0))
    error_message = "Allowed SSH CIDR must be a valid IPv4 CIDR block, for example 203.0.113.10/32."
  }
}

variable "grafana_port" {
  description = "Grafana HTTP port."
  type        = number
  default     = 3000

  validation {
    condition     = var.grafana_port > 0 && var.grafana_port < 65536
    error_message = "Grafana port must be between 1 and 65535."
  }
}

variable "prometheus_port" {
  description = "Prometheus HTTP port."
  type        = number
  default     = 9090

  validation {
    condition     = var.prometheus_port > 0 && var.prometheus_port < 65536
    error_message = "Prometheus port must be between 1 and 65535."
  }
}

variable "alertmanager_port" {
  description = "Alertmanager HTTP port."
  type        = number
  default     = 9093

  validation {
    condition     = var.alertmanager_port > 0 && var.alertmanager_port < 65536
    error_message = "Alertmanager port must be between 1 and 65535."
  }
}

variable "node_exporter_port" {
  description = "Node Exporter HTTP port."
  type        = number
  default     = 9100

  validation {
    condition     = var.node_exporter_port > 0 && var.node_exporter_port < 65536
    error_message = "Node Exporter port must be between 1 and 65535."
  }
}

variable "prometheus_volume_size_gb" {
  description = "Prometheus local EBS volume size (GB)."
  type        = number
  default     = 50

  validation {
    condition     = var.prometheus_volume_size_gb >= 20
    error_message = "Prometheus volume size must be at least 20 GB."
  }
}

variable "prometheus_volume_type" {
  description = "Prometheus local EBS volume type."
  type        = string
  default     = "gp3"

  validation {
    condition     = var.prometheus_volume_type == "gp3"
    error_message = "Prometheus volume type must be gp3."
  }
}

variable "grafana_min_size" {
  description = "Minimum number of Grafana instances in the Auto Scaling Group."
  type        = number
  default     = 2

  validation {
    condition     = var.grafana_min_size >= 1
    error_message = "Grafana minimum size must be at least 1."
  }
}

variable "grafana_desired_capacity" {
  description = "Desired number of Grafana instances in the Auto Scaling Group."
  type        = number
  default     = 1

  validation {
    condition     = var.grafana_desired_capacity >= 1
    error_message = "Grafana desired capacity must be at least 1."
  }
}

variable "grafana_max_size" {
  description = "Maximum number of Grafana instances in the Auto Scaling Group."
  type        = number
  default     = 1

  validation {
    condition     = var.grafana_max_size >= 1
    error_message = "Grafana maximum size must be at least 1."
  }
}
