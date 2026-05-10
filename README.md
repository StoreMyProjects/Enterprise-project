# Enterprise-project 🚀

A production-ready Infrastructure-as-Code (IaC) repository for provisioning enterprise-grade AWS infrastructure with Kubernetes (EKS) and cloud-native tooling using Terraform.

---

## 📋 Table of Contents

- [Services Overview](#services-overview)
- [Data Flow Architecture](#data-flow-architecture)
- [Prerequisites](#prerequisites)
- [Deployment Steps](#deployment-steps)
- [Configuration](#configuration)
- [Accessing Services](#accessing-services)
- [Project Structure](#project-structure)
- [Cleanup](#cleanup)

---

## 🔧 Services Overview

### AWS Services Used

| Service | Purpose | Module |
|---------|---------|--------|
| **VPC** | Virtual Private Cloud with subnets | vpc |
| **Subnets** | Public & Private subnets across AZs | vpc |
| **Internet Gateway** | Public internet access | vpc |
| **NAT Gateway** | Outbound internet for private subnets | vpc |
| **Route Tables** | Network routing | vpc |
| **EKS** | Managed Kubernetes cluster | eks |
| **EC2 Auto Scaling** | Node group scaling | eks |
| **IAM** | Identity & access management | eks, addons |
| **ACM** | SSL/TLS certificates for ALB | platform |
| **ALB** | Application Load Balancer for ingress | addons |
| **S3** | Terraform state backend | platform |

### Kubernetes Services Deployed

| Service | Purpose | Namespace |
|---------|---------|-----------|
| **AWS Load Balancer Controller** | Manages ALB/NLB for K8s Ingress | kube-system |
| **EBS CSI Driver** | Persistent storage for pods | kube-system |
| **Metrics Server** | Pod resource metrics for HPA | kube-system |
| **ArgoCD** | GitOps continuous deployment | argocd |
| **Prometheus** | Metrics collection & monitoring | monitoring |
| **Grafana** | Visualization & dashboards | monitoring |
| **Argo Rollouts** | Progressive deployments | argo-rollouts |
| **Alertmanager** | Alert routing (Slack integration) | monitoring |

---

## 🔄 Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          AWS Account (ap-south-1)                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  VPC (10.0.0.0/16)                                             │ │
│  │                                                                │ │
│  │  ┌──────────────────┐          ┌──────────────────┐           │ │
│  │  │ Public Subnet    │          │ Public Subnet    │           │ │
│  │  │ (ap-south-1a)    │          │ (ap-south-1b)    │           │ │
│  │  │ 10.0.1.0/24      │          │ 10.0.2.0/24      │           │ │
│  │  │                  │          │                  │           │ │
│  │  │ IGW + NAT GW     │          │ NAT GW           │           │ │
│  │  └──────────────────┘          └──────────────────┘           │ │
│  │           ↓                              ↓                     │ │
│  │  ┌──────────────────┐          ┌──────────────────┐           │ │
│  │  │ Private Subnet   │          │ Private Subnet   │           │ │
│  │  │ (ap-south-1a)    │          │ (ap-south-1b)    │           │ │
│  │  │ 10.0.11.0/24     │          │ 10.0.12.0/24     │           │ │
│  │  │                  │          │                  │           │ │
│  │  │ EKS Nodes        │          │ EKS Nodes        │           │ │
│  │  └──────────────────┘          └──────────────────┘           │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                      ↓                              │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  EKS Cluster (devops-eks)                                      │ │
│  │  • Control Plane: Managed by AWS                               │ │
│  │  • Node Groups: 3 nodes (Min: 2, Max: 5)                       │ │
│  │                                                                │ │
│  │  ┌────────────────────────────────────────────────────────┐   │ │
│  │  │  Kubernetes Services & Add-ons                         │   │ │
│  │  │                                                        │   │ │
│  │  │  kube-system namespace:                                │   │ │
│  │  │  ├─ AWS Load Balancer Controller → ALB                │   │ │
│  │  │  ├─ EBS CSI Driver → Storage                          │   │ │
│  │  │  └─ Metrics Server → HPA Metrics                      │   │ │
│  │  │                                                        │   │ │
│  │  │  argocd namespace:                                     │   │ │
│  │  │  └─ ArgoCD Server (ClusterIP) → ALB Ingress           │   │ │
│  │  │                                                        │   │ │
│  │  │  monitoring namespace:                                 │   │ │
│  │  │  ├─ Prometheus → Metrics Collection                    │   │ │
│  │  │  ├─ Grafana (ClusterIP) → ALB Ingress                 │   │ │
│  │  │  └─ Alertmanager → Slack Webhooks                     │   │ │
│  │  │                                                        │   │ │
│  │  │  argo-rollouts namespace:                              │   │ │
│  │  │  └─ Argo Rollouts → Progressive Deployments           │   │ │
│  │  └────────────────────────────────────────────────────────┘   │ │
│  │                                                                │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                           ↓                                         │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  AWS Load Balancer (ALB)                                       │ │
│  │  • Custom Domain: argocd.yourdomain.com (ACM Cert)             │ │
│  │  • Custom Domain: grafana.yourdomain.com (ACM Cert)            │ │
│  │  • Security Groups: Managed by AWS LB Controller               │ │
│  │  • Target Groups: K8s Services                                 │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘

Data Flow:
1. User requests ArgoCD/Grafana → Route53 (DNS) → ALB
2. ALB terminates SSL/TLS using ACM Certificate
3. ALB routes to K8s Ingress Controller
4. Ingress routes to ArgoCD/Grafana Services
5. Services communicate with pods
6. Monitoring: Prometheus scrapes metrics → Grafana visualizes
7. Alerts: Alertmanager routes critical alerts → Slack webhooks
```

---

## 📦 Prerequisites

### Required Tools

```bash
# Terraform >= 1.0
terraform --version

# AWS CLI v2
aws --version
aws configure

# kubectl
kubectl version --client

# Helm >= 3.0
helm version

# jq (optional, for JSON processing)
jq --version
```

### AWS Account Requirements

- ✅ VPC, Subnet, Route Table, NAT Gateway creation permissions
- ✅ EKS cluster and node group management
- ✅ IAM role and policy creation
- ✅ S3 bucket access for Terraform state
- ✅ ACM certificate creation (or existing certificate ARN)
- ✅ ALB creation and management

### Pre-requisite Setup

1. **AWS Credentials**
   ```bash
   aws configure
   # Enter: Access Key ID, Secret Access Key, Region (ap-south-1)
   ```

2. **S3 Bucket for Terraform State**
   ```bash
   aws s3api create-bucket \
     --bucket amrendra-terraform-state \
     --region ap-south-1 \
     --create-bucket-configuration LocationConstraint=ap-south-1
   
   # Enable versioning
   aws s3api put-bucket-versioning \
     --bucket amrendra-terraform-state \
     --versioning-configuration Status=Enabled
   ```

3. **ACM Certificates (for ArgoCD & Grafana)**
   ```bash
   # Request certificate for custom domain
   aws acm request-certificate \
     --domain-name argocd.yourdomain.com \
     --subject-alternative-names grafana.yourdomain.com \
     --region ap-south-1
   
   # Get certificate ARN
   aws acm list-certificates --region ap-south-1
   ```

---

## 🚀 Deployment Steps

### **Step 1: Clone Repository**

```bash
git clone https://github.com/StoreMyProjects/Enterprise-project.git
cd Enterprise-project
```

### **Step 2: Deploy Infrastructure Layer (VPC + EKS)**

```bash
cd infra/envs/dev/infra

# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Apply changes (takes ~20-25 minutes)
terraform apply

# Note the outputs:
# - vpc_id
# - private_subnet_ids
# - cluster_name
# - cluster_endpoint
# - oidc_provider_arn
# - oidc_provider_url
```

**What gets created:**
- VPC with 2 public subnets + 2 private subnets
- Internet Gateway + NAT Gateways
- EKS cluster "devops-eks"
- 3 EC2 nodes (Min: 2, Max: 5 auto-scaling)
- OIDC provider for IRSA

### **Step 3: Update kubeconfig**

```bash
aws eks update-kubeconfig \
  --region ap-south-1 \
  --name devops-eks

# Verify cluster access
kubectl get nodes
kubectl get pod -A
```

### **Step 4: Configure Custom Domains**

Update `infra/envs/dev/platform/argocd-ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-ingress
  namespace: argocd
  annotations:
    cert-arn: arn:aws:acm:ap-south-1:ACCOUNT_ID:certificate/CERT_ID
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-TLS-1-2-2017-01
spec:
  ingressClassName: alb
  rules:
  - host: argocd.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 443
```

Update `infra/envs/dev/platform/grafana-ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana-ingress
  namespace: monitoring
  annotations:
    cert-arn: arn:aws:acm:ap-south-1:ACCOUNT_ID:certificate/CERT_ID
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-TLS-1-2-2017-01
spec:
  ingressClassName: alb
  rules:
  - host: grafana.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kube-prometheus-stack-grafana
            port:
              number: 80
```

### **Step 5: Deploy Platform Layer (Add-ons)**

```bash
cd ../platform

# Configure Slack webhooks in main.tf:
# slack_warning_webhook_url = "https://hooks.slack.com/services/..."
# slack_critical_webhook_url = "https://hooks.slack.com/services/..."

# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Apply changes (takes ~10-15 minutes)
terraform apply
```

**What gets created:**
- AWS Load Balancer Controller
- EBS CSI Driver
- Metrics Server
- ArgoCD with HTTPS (ACM cert)
- Prometheus + Grafana with HTTPS (ACM cert)
- Argo Rollouts
- Alertmanager with Slack integration

### **Step 6: Verify All Services**

```bash
# Check all namespaces
kubectl get namespaces

# Check services in kube-system
kubectl get pods -n kube-system

# Check ArgoCD
kubectl get pods -n argocd
kubectl get svc -n argocd

# Check Monitoring
kubectl get pods -n monitoring
kubectl get svc -n monitoring

# Check Ingress resources
kubectl get ingress -A
```

### **Step 7: Update Route53 (DNS)**

Get ALB DNS name:
```bash
kubectl get ingress -A
# or
aws elbv2 describe-load-balancers --region ap-south-1
```

Create Route53 records:
```bash
# For ArgoCD
aws route53 change-resource-record-sets \
  --hosted-zone-id ZONE_ID \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "argocd.yourdomain.com",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [{"Value": "ALB-DNS-NAME"}]
      }
    }]
  }'

# For Grafana
aws route53 change-resource-record-sets \
  --hosted-zone-id ZONE_ID \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "grafana.yourdomain.com",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [{"Value": "ALB-DNS-NAME"}]
      }
    }]
  }'
```

---

## ⚙️ Configuration

### VPC Configuration

Edit `infra/envs/dev/infra/main.tf`:

```hcl
module "vpc" {
  source = "../../../modules/vpc"

  name   = "devops"
  region = "ap-south-1"

  vpc_cidr = "10.0.0.0/16"
  azs      = ["ap-south-1a", "ap-south-1b"]

  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]

  enable_nat_gateway = true

  tags = {
    Environment = "dev"
    Owner       = "amrendra"
  }
}
```

### EKS Configuration

Edit `infra/envs/dev/infra/main.tf`:

```hcl
module "eks" {
  source = "../../../modules/eks"

  name   = "devops-eks"
  region = "ap-south-1"

  desired_capacity = 3    # Current nodes
  max_capacity     = 5    # Max auto-scaling
  min_capacity     = 2    # Min nodes

  endpoint_public_access = true
  public_access_cidrs    = ["106.192.114.117/32"]  # Your IP

  tags = {
    Environment = "dev"
    Owner       = "amrendra"
  }
}
```

### ACM Certificate Configuration

Edit `infra/envs/dev/platform/main.tf`:

```hcl
# Get your certificate ARN
output "acm_certificate_arn" {
  value = "arn:aws:acm:ap-south-1:ACCOUNT_ID:certificate/CERT_ID"
}
```

---

## 🌐 Accessing Services

### ArgoCD

**URL:** https://argocd.yourdomain.com  
**Default Username:** admin  
**Password:** Get from:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

### Grafana

**URL:** https://grafana.yourdomain.com  
**Username:** admin  
**Password:** admin123 (or configured value)

**Pre-configured Dashboards:**
- Kubernetes Cluster Overview
- Node Exporter Full
- Prometheus Overview

### Prometheus

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Access: http://localhost:9090
```

### Alertmanager

Alerts route to Slack:
- ⚠️ **Warnings** → `#alerts-warning`
- 🚨 **Critical** → `#alerts-critical`

---

## 📁 Project Structure

```
Enterprise-project/
├── README.md
├── .gitignore
└── infra/
    ├── modules/
    │   ├── vpc/          # VPC, subnets, NAT, routes
    │   ├── eks/          # EKS cluster, nodes, OIDC
    │   └── addons/       # K8s add-ons, Helm charts
    └── envs/
        └── dev/
            ├── infra/    # VPC + EKS layer
            └── platform/ # Add-ons + Ingress layer
```

---

## 🧹 Cleanup

To destroy all infrastructure (⚠️ **Irreversible**):

```bash
# Destroy add-ons first
cd infra/envs/dev/platform
terraform destroy

# Then destroy infrastructure
cd ../infra
terraform destroy

# Remove kubeconfig entry
kubectl config delete-context arn:aws:eks:ap-south-1:ACCOUNT_ID:cluster/devops-eks
```

---

## 📊 Estimated Costs (Monthly)

| Component | Cost |
|-----------|------|
| 3x t3.medium EC2 nodes | $45 |
| NAT Gateway (data processing) | $32 |
| ALB | $16 |
| EBS storage (30GB) | $3 |
| Data transfer (out) | $5 |
| **Total (Approximate)** | **~$100** |

---

## 🔒 Security Best Practices

✅ **Implemented:**
- Private subnets for EKS nodes
- IMDSv2 enforced on EC2 instances
- OIDC provider for IRSA
- ALB with ACM SSL/TLS certificates
- VPC Flow Logs

⚠️ **Additional Recommendations:**
- Enable EKS audit logging
- Use AWS Secrets Manager for sensitive data
- Implement network policies
- Use Pod Security Policies
- Enable container image scanning
- Regular backup of Kubernetes resources

---

## 🐛 Troubleshooting

### Nodes not ready
```bash
kubectl describe nodes
kubectl logs -n kube-system -l k8s-app=aws-node
```

### ALB not creating
```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

### ArgoCD/Grafana not accessible
```bash
kubectl get ingress -A
kubectl describe ingress -n argocd argocd-ingress
```

### Slack alerts not working
```bash
kubectl describe secret -n monitoring alertmanager-config
kubectl logs -n monitoring alertmanager-0
```

---

## 📧 Support & Contributions

**Project Owner:** Amrendra  
**Region:** AWS Asia Pacific (Mumbai) - ap-south-1  
**Environment:** Development  

For issues or questions, review logs and check Terraform state files.

---

**Last Updated:** May 10, 2026  
**Repository:** https://github.com/StoreMyProjects/Enterprise-project