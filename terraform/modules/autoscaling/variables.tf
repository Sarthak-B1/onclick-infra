variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "monitoring_sg_id" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "efs_file_system_id" {
  type = string
}

variable "grafana_port" {
  type = number
}

variable "node_exporter_port" {
  type = number
}

variable "min_size" {
  type = number
}

variable "desired_capacity" {
  type = number
}

variable "max_size" {
  type = number
}

variable "tags" {
  type = map(string)
}

variable "key_name" {
  type = string
}
variable "iam_instance_profile_name" { type = string }
