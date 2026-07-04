aws_region = "ap-south-1"

vpc_cidr = "10.0.0.0/16"

key_name = "assignment-6"

public_subnet_1 = "10.0.1.0/24"
public_subnet_2 = "10.0.2.0/24"

private_subnet_1 = "10.0.3.0/24"
private_subnet_2 = "10.0.4.0/24"

instance_type = "t3.micro"

# Replace this with your public IP address before applying, for example "198.51.100.25/32".
allowed_ssh_cidr = "0.0.0.0/0"

grafana_port       = 3000
prometheus_port    = 9090
node_exporter_port = 9100

grafana_min_size         = 1
grafana_desired_capacity = 1
grafana_max_size         = 4
