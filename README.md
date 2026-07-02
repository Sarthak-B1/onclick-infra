<div align="center">

# 🚀 onclick-infra

### Monitoring Infrastructure on AWS

[![Terraform](https://img.shields.io/badge/Terraform-≥1.5.0-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Ansible](https://img.shields.io/badge/Ansible-≥2.14-EE0000?style=for-the-badge&logo=ansible&logoColor=white)](https://www.ansible.com/)
[![AWS](https://img.shields.io/badge/AWS-ap--south--1-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)](https://aws.amazon.com/)
[![Jenkins](https://img.shields.io/badge/Jenkins-CI%2FCD-D24939?style=for-the-badge&logo=jenkins&logoColor=white)](https://www.jenkins.io/)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](./LICENSE)

*Automated deployment of Prometheus + Grafana + Node Exporter using Terraform & Ansible — with a full Jenkins CI/CD pipeline.*

</div>

---

## 📐 Architecture


            <img width="908" height="557" alt="Screenshot 2026-06-09 at 11 29 38 AM" src="https://github.com/user-attachments/assets/34ecfd3c-012c-49af-9dd9-c38f47c0d7e9" />



## 📁 Project Structure

```
onclick-infra/
│
├── 📄 README.md
├── 📄 .gitignore
│
├── 📁 jenkins/
│   └── 📄 Jenkinsfile                     ← Full CI/CD pipeline
│
├── 📁 terraform/                          ← Infrastructure as Code
│   ├── 📄 main.tf                         ← Root module
│   ├── 📄 backend.tf                      ← S3 state + DynamoDB lock
│   ├── 📄 provider.tf                     ← AWS provider
│   ├── 📄 variables.tf                    ← Input variables
│   ├── 📄 outputs.tf                      ← ALB URL, IPs, EFS ID
│   ├── 📄 terraform.tfvars                ← Variable values
│   │
│   ├── 📁 bootstrap/                      ← One-time S3 + DynamoDB setup
│   │   └── 📄 main.tf
│   │
│   └── 📁 modules/
│       ├── 📁 vpc/                        ← VPC, Subnets, IGW, NAT
│       ├── 📁 security-group/             ← Bastion, ALB, Monitoring SGs
│       ├── 📁 ec2/                        ← Bastion + Prometheus + EBS
│       ├── 📁 efs/                        ← Shared EFS for Grafana
│       ├── 📁 alb/                        ← Load Balancer + Target Group
│       └── 📁 autoscaling/                ← Grafana ASG + Launch Template
│
└── 📁 ansible-monitoring-stack/           ← Configuration Management
    ├── 📄 ansible.cfg
    ├── 📄 play.yml                        ← Main playbook
    │
    ├── 📁 inventory/
    │   └── 📄 aws_ec2.yml                 ← Dynamic AWS EC2 inventory
    │
    ├── 📁 group_vars/
    │   ├── 📄 all.yml                     ← Global vars (ports, versions)
    │   └── 📁 role_bastion/vars.yml       ← Bastion SSH settings
    │
    └── 📁 roles/
        ├── 📁 common/                     ← Base packages + swap
        ├── 📁 security/                   ← Firewall (UFW / firewalld)
        ├── 📁 node_exporter/              ← Node Exporter setup
        ├── 📁 prometheus/                 ← Prometheus + EBS + EC2 SD
        ├── 📁 efs/                        ← EFS mount for Grafana
        └── 📁 grafana/                    ← Grafana install + config
```

---

## ⚡ Quick Start

### Prerequisites

| Tool | Version | Install |
|---|---|---|
| Terraform | `>= 1.5.0` | [Download](https://developer.hashicorp.com/terraform/downloads) |
| Ansible | `>= 2.14` | `pip install ansible` |
| AWS CLI | `>= 2.x` | [Download](https://aws.amazon.com/cli/) |
| Python | `>= 3.x` | [Download](https://python.org) |

---

### 🔧 Step 1 — Bootstrap (First time only)

> Creates the **S3 bucket** + **DynamoDB table** for Terraform remote state.

```bash
cd terraform/bootstrap
terraform init
terraform apply
```

---

### 🏗️ Step 2 — Provision Infrastructure

```bash
cd terraform

# Initialize providers
terraform init

# Preview what will be created
terraform plan

# Deploy to AWS
terraform apply
```

**Outputs after apply:**

```
alb_dns_name           = "monitoring-alb-xxxxxxxxx.ap-south-1.elb.amazonaws.com"
bastion_public_ip      = "x.x.x.x"
prometheus_primary_ip  = "10.0.3.10"
prometheus_replica_ip  = "10.0.4.10"
efs_id                 = "fs-xxxxxxxxx"
```

---

### ⚙️ Step 3 — Configure Servers with Ansible

```bash
cd ansible-monitoring-stack

# Set your SSH key
export SSH_KEY_FILE=~/.ssh/assignment-6.pem

# Run playbook
ansible-playbook play.yml \
  -e "ansible_ssh_private_key_file=${SSH_KEY_FILE}"
```

**Ansible will configure:**
- ✅ Common packages + Swap memory on all nodes
- ✅ Firewall rules (UFW / firewalld)
- ✅ Node Exporter on every instance
- ✅ Prometheus with EC2 auto-discovery + EBS mount
- ✅ EFS mount for Grafana shared storage
- ✅ Grafana installation + custom config

---

### 🌐 Step 4 — Access Services

| Service | URL |
|---|---|
| **Grafana** | `http://<alb_dns_name>` |
| **Prometheus** | `http://<prometheus_primary_ip>:9090` *(via Bastion tunnel)* |
| **Node Exporter** | `http://<any_node_ip>:9100/metrics` |

**Default Grafana credentials:**
```
Username: sarthak
Password: sarthak@123
```

---

## 🔄 Jenkins CI/CD Pipeline

The [`jenkins/Jenkinsfile`](./jenkins/Jenkinsfile) automates the **full end-to-end deployment**:

```
┌──────────┐   ┌───────────────┐   ┌───────────────┐   ┌──────────┐
│ Checkout │──►│  TF Init +    │──►│  TF Plan      │──►│ Approval │
│          │   │  Validate     │   │               │   │  Gate    │
└──────────┘   └───────────────┘   └───────────────┘   └────┬─────┘
                                                             │
          ┌──────────────────────────────────────────────────┘
          ▼
┌──────────────┐   ┌──────────────┐   ┌───────────────┐   ┌──────────────┐
│  TF Apply /  │──►│  Wait EC2    │──►│ Ansible Syntax│──►│   Ansible    │
│  Destroy     │   │  Boot (60s)  │   │ Check         │   │   Playbook   │
└──────────────┘   └──────────────┘   └───────────────┘   └──────────────┘
```

### Jenkins Credentials Setup

Go to: **Manage Jenkins → Credentials → Add**

| Credential ID | Type | Description |
|---|---|---|
| `ansible-ssh-key` | SSH Private Key File | EC2 SSH key (.pem) |
| `aws-access-key-id` | Secret Text | AWS Access Key ID |
| `aws-secret-access-key` | Secret Text | AWS Secret Access Key |

### Pipeline Parameters

| Parameter | Options | Default | Description |
|---|---|---|---|
| `ACTION` | `plan` / `apply` / `destroy` | `plan` | Terraform action |
| `RUN_ANSIBLE` | `true` / `false` | `true` | Run Ansible after apply |

---

## 🔐 Security

| Feature | Status |
|---|---|
| Terraform state encrypted in S3 | ✅ |
| State locking via DynamoDB | ✅ |
| All EBS volumes encrypted | ✅ |
| EFS encrypted at rest | ✅ |
| Private instances behind Bastion | ✅ |
| SSH keys excluded from Git | ✅ |
| `.pem` files in `.gitignore` | ✅ |

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Cloud** | AWS (ap-south-1) |
| **IaC** | Terraform `>= 1.5` |
| **Config Mgmt** | Ansible `>= 2.14` |
| **CI/CD** | Jenkins |
| **Monitoring** | Prometheus + Grafana + Node Exporter |
| **Storage** | EFS (Grafana) + EBS gp3 (Prometheus TSDB) |
| **Network** | VPC + Public/Private Subnets + NAT Gateway + ALB |
| **Scaling** | Auto Scaling Group (Grafana: 2–4 nodes) |

---

## 👤 Owner

**Sarthak Bhatnagar**
Project: `onclick-infra` — Monitoring Infrastructure Stack
