# onclick-infra — Monitoring Infrastructure Stack

> **Production-grade monitoring infrastructure on AWS** using Terraform (IaC) and Ansible (Configuration Management).

---

## 📐 Architecture Overview

```
                         ┌──────────────────────────────────┐
                         │           AWS (ap-south-1)        │
                         │                                   │
  Internet ──────────────►  ALB (port 80)                   │
                         │     │                             │
                         │     ▼                             │
              ┌──────────┤  Grafana ASG (2–4 nodes)         │
              │          │     │ EFS Mount /var/lib/grafana  │
              │          │     ▼                             │
              │          │  EFS (Shared Grafana DB)          │
              │          │                                   │
              │  Bastion ◄──── SSH Jump Host (Public)        │
              │  Host    │     │                             │
              │          │     ├──► Prometheus Primary       │
              │          │     │     └─ EBS 50GB TSDB        │
              │          │     └──► Prometheus Replica       │
              │          │           └─ EBS 50GB TSDB        │
              │          │                                   │
              │          │  Node Exporter (all nodes)        │
              └──────────┴──────────────────────────────────┘
```

---

## 📁 Project Structure

```
onclick-infra/
│
├── 📄 README.md                       # Project documentation
├── 📄 .gitignore
│
├── 📁 jenkins/                        # Jenkins CI/CD
│   └── Jenkinsfile                    # Full pipeline (Terraform + Ansible)
│
├── 📁 terraform/                      # Terraform Infrastructure Code
│   ├── backend.tf                     # S3 remote backend + DynamoDB lock
│   ├── provider.tf                    # AWS provider config
│   ├── main.tf                        # Root module: calls all sub-modules
│   ├── variables.tf                   # All input variables
│   ├── outputs.tf                     # Key outputs (ALB URL, IPs, EFS ID)
│   ├── terraform.tfvars               # Variable values
│   │
│   ├── bootstrap/                     # One-time S3 + DynamoDB setup
│   │   └── main.tf
│   │
│   └── modules/                       # Reusable Terraform modules
│       ├── vpc/                       # VPC, Subnets, IGW, NAT, Route Tables
│       ├── security-group/            # Bastion, ALB, Monitoring SGs
│       ├── ec2/                       # Bastion + Prometheus EC2 + EBS volumes
│       ├── efs/                       # EFS Filesystem + Mount Targets
│       ├── alb/                       # Application Load Balancer + Target Group
│       └── autoscaling/               # Grafana Auto Scaling Group + Launch Template
│
└── ansible-monitoring-stack/          # Ansible Configuration Management
    ├── ansible.cfg                    # Ansible settings
    ├── play.yml                       # Main playbook
    │
    ├── inventory/
    │   ├── aws_ec2.yml                # Dynamic AWS EC2 inventory (auto-discovers hosts)
    │   └── hosts                      # Static hosts (empty — dynamic only)
    │
    ├── group_vars/
    │   ├── all.yml                    # Global variables (ports, versions, paths)
    │   └── role_bastion/vars.yml      # Bastion-specific SSH settings
    │
    └── roles/
        ├── common/                    # Base packages + swap setup
        ├── security/                  # UFW / firewalld configuration
        ├── node_exporter/             # Prometheus Node Exporter
        ├── prometheus/                # Prometheus server + EBS mount + EC2 SD
        ├── efs/                       # EFS mount for Grafana shared storage
        └── grafana/                   # Grafana install + config + systemd
```

---

## 🚀 Deployment Guide

### Prerequisites
| Tool | Version |
|---|---|
| Terraform | >= 1.5.0 |
| Ansible | >= 2.14 |
| AWS CLI | >= 2.x |
| Python | >= 3.x |

### Step 1 — Bootstrap (First time only)
Create the S3 bucket and DynamoDB lock table for Terraform remote state:
```bash
cd terraform/bootstrap
terraform init
terraform apply
```

### Step 2 — Provision Infrastructure
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Step 3 — Configure Servers with Ansible
```bash
cd ansible-monitoring-stack

# Set your SSH key path
export SSH_KEY_FILE=~/.ssh/assignment-6.pem

# Run the playbook
ansible-playbook play.yml \
  -e "ansible_ssh_private_key_file=${SSH_KEY_FILE}"
```

### Step 4 — Access Services
After deployment, Terraform will output:
| Service | URL |
|---|---|
| **Grafana** | `http://<alb_dns_name>` |
| **Prometheus** | `http://<prometheus_primary_ip>:9090` (via Bastion tunnel) |

---

## ⚙️ Jenkins CI/CD Pipeline

The [Jenkinsfile](./Jenkinsfile) automates the full deployment:

```
Checkout → Terraform Init → Terraform Plan → Approval → Terraform Apply
       → Wait EC2 Boot → Ansible Syntax Check → Ansible Playbook
```

### Jenkins Credentials Required
Add these credentials in Jenkins (`Manage Jenkins → Credentials`):

| ID | Type | Description |
|---|---|---|
| `ansible-ssh-key` | SSH Private Key | EC2 SSH key (assignment-6.pem) |
| `aws-access-key-id` | Secret Text | AWS Access Key ID |
| `aws-secret-access-key` | Secret Text | AWS Secret Access Key |

### Pipeline Parameters
| Parameter | Options | Default |
|---|---|---|
| `ACTION` | `plan`, `apply`, `destroy` | `plan` |
| `RUN_ANSIBLE` | `true`, `false` | `true` |

---

## 🔐 Security Notes
- All `.pem` keys are excluded from git via `.gitignore`
- Terraform state is stored encrypted in S3 with DynamoDB locking
- Private instances are only accessible via Bastion SSH jump host
- All EBS volumes and EFS filesystem are encrypted at rest

---

## 👤 Owner
**Sarthak Bhatnagar** | Project: Monitoring Infrastructure
