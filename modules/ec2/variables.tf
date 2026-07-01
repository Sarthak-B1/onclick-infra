variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "prometheus_primary_subnet_id" {
  type = string
}

variable "prometheus_replica_subnet_id" {
  type = string
}

variable "prometheus_volume_size_gb" {
  type = number
}

variable "prometheus_volume_type" {
  type = string
}


variable "bastion_sg_id" {
  type = string
}

variable "monitoring_sg_id" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "key_name" {
  type = string
}