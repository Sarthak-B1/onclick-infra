variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "allowed_ssh_cidr" {
  type = string
}

variable "prometheus_port" {
  type = number
}

variable "node_exporter_port" {
  type = number
}

variable "tags" {
  type = map(string)
}
