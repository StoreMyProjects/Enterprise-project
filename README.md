# Enterprise-project 🚀

A production-ready Infrastructure-as-Code repository for provisioning enterprise-grade AWS infrastructure with Kubernetes (EKS) and cloud-native tooling using Terraform. This project automates the complete deployment of a scalable, monitored, and managed Kubernetes cluster in AWS with GitOps capabilities.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Services Deployed](#services-deployed)
- [Data Flow](#data-flow)
- [Prerequisites](#prerequisites)
- [Deployment Steps](#deployment-steps)
- [Accessing Services](#accessing-services)
- [Module Details](#module-details)
- [Cleanup](#cleanup)

---

## 🎯 Overview

**Enterprise-project** provides a complete infrastructure automation solution that deploys:

- **Networking**: AWS VPC with public and private subnets across multiple availability zones
- **Kubernetes**: Amazon EKS (Elastic Kubernetes Service) cluster with auto-scaling node groups
- **Container Networking**: AWS Load Balancer Controller for Ingress management
- **Storage**: EBS CSI Driver for persistent storage in containers
- **GitOps**: ArgoCD for continuous deployment workflows
- **Monitoring**: Prometheus for metrics collection and Grafana for visualization
- **Progressive Deployments**: Argo Rollouts for advanced deployment strategies
- **DNS**: ExternalDNS for automatic DNS record management
- **Alerting**: AlertManager with Slack integration for notifications

**Project Owner**: Amrendra  
**AWS Region**: Asia Pacific (Mumbai) - ap-south-1  
**Environment**: Development  
**Custom Domains**: argocd.testpro.in and grafana.testpro.in with ACM SSL/TLS certificates  

---

## 🏗️ Architecture

The infrastructure follows a three-layer architecture:

**Layer 1: Networking (VPC Module)**
- Creates isolated virtual network environment
- Provisions public subnets for NAT gateways and internet access
- Provisions private subnets for Kubernetes node deployment
- Configures Internet Gateway for public access
- Deploys NAT Gateways for outbound traffic from private subnets
- Manages routing tables and network associations

**Layer 2: Kubernetes (EKS Module)**
- Provisions managed Kubernetes control plane via AWS EKS
- Creates EC2 node groups with auto-scaling capabilities
- Configures IAM roles and policies for cluster and nodes
- Enables OIDC provider for IAM Roles for Service Accounts (IRSA)
- Implements security group policies
- Sets up cluster endpoints with public/private access options

**Layer 3: Platform Services (Helm Module)**
- Deploys AWS Load Balancer Controller for ingress routing
- Installs EBS CSI Driver for dynamic persistent volumes
- Configures Prometheus and Grafana for monitoring
- Deploys ArgoCD for GitOps workflows
- Installs Argo Rollouts for progressive deployments
- Configures ExternalDNS for automatic Route53 management
- Sets up AlertManager with Slack webhooks

**Load Balancing & SSL/TLS**
- AWS Application Load Balancer terminates HTTPS traffic
- ACM certificates secure custom domains
- Ingress resources route traffic to Kubernetes services
- ALB integrates with AWS LB Controller for automatic provisioning

---

## 📁 Project Structure

Enterprise-project is organized into modular components for reusability and maintainability:

**Root Level**
- `.gitignore`: Specifies files excluded from version control (Terraform state, override files, credentials)
- `README.md`: Project documentation

**Infrastructure Directory (`infra/`)**
Contains all Terraform configurations organized by modules and environments.

**Modules Directory (`infra/modules/`)**

*VPC Module* (`infra/modules/vpc/`)
- `main.tf`: VPC, subnets, Internet Gateway, NAT Gateways, routing tables
- `variables.tf`: Input variables for VPC configuration (name, CIDR blocks, AZs, tags)
- `outputs.tf`: Exports VPC ID, public subnet IDs, private subnet IDs
- `endpoints.tf`: VPC endpoints configuration
- `flowlogs.tf`: VPC Flow Logs for network monitoring
- `security.tf`: Security group definitions
- `versions.tf`: Terraform and provider versions
- `.terraform.lock.hcl`: Dependency lock file

*EKS Module* (`infra/modules/eks/`)
- `main.tf`: EKS cluster, node groups, IAM roles, launch templates, OIDC provider
- `variables.tf`: Input variables for cluster configuration (name, capacity, instance types, CIDR access)
- `outputs.tf`: Exports cluster name, endpoint, CA certificate, OIDC provider details
- `.terraform.lock.hcl`: Dependency lock file

*Helm Module* (`infra/modules/helm/`)
- `alb-controller.tf`: AWS Load Balancer Controller IAM role and Helm chart deployment
- `argo-rollouts.tf`: Argo Rollouts Helm chart for progressive deployments
- `argocd.tf`: ArgoCD Helm chart with service configuration
- `external-dns.tf`: ExternalDNS IAM role, service account, and Helm chart with Route53 integration
- `monitoring.tf`: Prometheus and Grafana Helm charts with AlertManager configuration
- `alb_controller_iam_policy.json`: IAM policy for ALB controller permissions
- `providers.tf`: Kubernetes and Helm provider configuration
- `variables.tf`: Input variables for cluster details and credentials
- `outputs.tf`: Module outputs
- `.terraform.lock.hcl`: Dependency lock file

**Environments Directory (`infra/envs/`)**

*Development Infrastructure Layer* (`infra/envs/dev/infra/`)
- `main.tf`: Instantiates VPC and EKS modules with dev environment settings
- `providers.tf`: AWS provider configuration with S3 backend for state management
- `outputs.tf`: Re-exports cluster and OIDC provider outputs
- `.terraform.lock.hcl`: Dependency lock file

*Development Platform Layer* (`infra/envs/dev/platform/`)
- `main.tf`: Instantiates Helm module with data source to fetch infrastructure layer outputs
- `providers.tf`: Kubernetes and Helm provider configuration with S3 backend
- Provides values for Slack webhook URLs and Grafana credentials
- `.terraform.lock.hcl`: Dependency lock file

**Ingresses Directory (`ingresses/`)**

*ArgoCD Ingress* (`ingresses/argocd-ingress.yaml`)
- Creates Kubernetes Ingress resource for ArgoCD
- Configures ALB with ACM certificate for argocd.testpro.in
- Enables HTTPS redirect and health checks
- Routes traffic to argocd-server service on port 80
- Enables External DNS annotation for automatic Route53 registration

*Grafana Ingress* (`ingresses/grafana-ingress.yaml`)
- Creates Kubernetes Ingress resource for Grafana
- Configures ALB with ACM certificate for grafana.testpro.in
- Sets HTTP health check path to /api/health
- Routes traffic to kube-prometheus-stack-grafana service on port 80
- Enables External DNS annotation for automatic Route53 registration

---

## 🔧 Services Deployed

### AWS Services

| Service | Purpose | Module |
|---------|---------|--------|
| VPC | Virtual Private Cloud networking | vpc |
| Subnets | Public and private network segmentation | vpc |
| Internet Gateway | Public internet access | vpc |
| NAT Gateway | Outbound internet for private resources | vpc |
| Route Tables | Network routing rules | vpc |
| EKS | Managed Kubernetes service | eks |
| EC2 Auto Scaling | Node group capacity management | eks |
| IAM Roles | Service authentication and authorization | eks, helm |
| ACM | SSL/TLS certificates for domains | helm |
| ALB | Application Load Balancer for ingress | helm |
| S3 | Terraform state backend storage | provider |
| Route53 | DNS management | external-dns |

### Kubernetes Services

| Service | Purpose | Namespace | Deployment Method |
|---------|---------|-----------|-------------------|
| AWS Load Balancer Controller | ALB/NLB provisioning for ingress | kube-system | Helm |
| EBS CSI Driver | Persistent storage for containers | kube-system | EKS Add-on |
| Metrics Server | Resource metrics for HPA scaling | kube-system | Helm |
| ArgoCD | GitOps continuous deployment | argocd | Helm |
| Prometheus | Metrics collection and storage | monitoring | Helm |
| Grafana | Metrics visualization and dashboards | monitoring | Helm |
| AlertManager | Alert routing and aggregation | monitoring | Helm |
| Argo Rollouts | Progressive deployment orchestration | argo-rollouts | Helm |
| ExternalDNS | Automatic DNS record management | external-dns | Helm |

---

## 🔄 Data Flow

**User Access Path**
1. User requests argocd.testpro.in or grafana.testpro.in
2. DNS query resolves to ALB IP via Route53 (managed by ExternalDNS)
3. ALB receives request and terminates HTTPS using ACM certificate
4. ALB routes to appropriate Kubernetes Ingress controller
5. Ingress controller routes to service based on hostname
6. Service load balances traffic to application pods
7. Response flows back through the same path with SSL/TLS encryption

**Monitoring Data Path**
1. Prometheus scrapes metrics from endpoints across cluster
2. Pod metrics collected from Metrics Server
3. Node metrics collected from kubelet
4. Application metrics collected from instrumented services
5. Grafana queries Prometheus for visualization
6. AlertManager evaluates alert rules based on metrics
7. Critical or warning alerts route to Slack channels

**DNS Management Path**
1. Ingress resources created with External DNS annotations
2. ExternalDNS pod watches Ingress resources
3. ExternalDNS creates/updates Route53 records
4. ExternalDNS creates TXT records for resource ownership

**GitOps Workflow Path**
1. Application configurations stored in Git repository
2. ArgoCD monitors Git repository for changes
3. ArgoCD detects configuration drift in cluster
4. ArgoCD applies changes automatically
5. Argo Rollouts manages progressive deployment strategies

---

## 📋 Prerequisites

**Required Tools**
- Terraform version 1.0 or higher for infrastructure provisioning
- AWS CLI v2 for AWS account access and credential management
- kubectl for Kubernetes cluster interaction
- Helm version 3.0 or higher for package management
- jq for JSON parsing (optional but recommended)

**AWS Account Requirements**
- Permissions to create VPC, subnets, route tables, NAT gateways
- Permissions to create and manage EKS clusters and node groups
- Permissions to create and attach IAM roles and policies
- Permissions to create and manage S3 buckets for Terraform state
- Permissions to create ACM certificates
- Permissions to create and configure ALB
- Permissions to create and manage Route53 hosted zones

**Domain Requirements**
- A registered domain (testpro.in is configured in this example)
- Route53 hosted zone for the domain
- Ability to request ACM certificates for custom subdomains

**S3 State Backend**
- S3 bucket named "amrendra-terraform-state" in ap-south-1 region
- Versioning enabled on the bucket
- Server-side encryption enabled
- DynamoDB table optional but recommended for state locking

**ACM Certificates**
- Certificate for argocd.testpro.in
- Certificate for grafana.testpro.in
- Both certificates in the ap-south-1 region
- Certificate ARNs needed for Ingress resources

---

## 🚀 Deployment Steps

### Step 1: Repository Setup

Clone the repository and navigate to the infrastructure layer directory to begin deployment.

### Step 2: Infrastructure Layer Deployment

Navigate to the infrastructure layer environment directory. Initialize Terraform to download required providers and modules. Run plan to review resources that will be created. Execute apply to provision the VPC, EKS cluster, node groups, and OIDC provider. This step typically takes 20-25 minutes to complete.

Outputs from this step include:
- VPC ID and subnet IDs
- EKS cluster name and endpoint
- OIDC provider ARN and URL
- Cluster CA certificate

Save these outputs as they are required for the platform layer deployment.

### Step 3: Configure Kubernetes Access

Update local kubeconfig to connect to the newly created EKS cluster. Verify cluster connectivity by checking nodes and existing pods. Ensure all nodes are in Ready status before proceeding.

### Step 4: Prepare Custom Domain Configuration

Update the Ingress manifests in the ingresses directory with your custom domain names if different from testpro.in. Ensure ACM certificate ARNs are correct for your environment. Verify the certificate ARNs correspond to the domains in the Ingress resources.

### Step 5: Platform Layer Deployment

Navigate to the platform layer environment directory. Initialize Terraform with the infrastructure layer state. Update Slack webhook URLs in the variables or as Terraform inputs for alerting configuration. Update Grafana admin password if desired (default is admin123). Execute apply to deploy all Kubernetes services and applications. This step typically takes 10-15 minutes to complete.

This deployment includes:
- AWS Load Balancer Controller
- EBS CSI Driver
- Prometheus and Grafana
- ArgoCD
- Argo Rollouts
- ExternalDNS
- AlertManager with Slack integration

### Step 6: Verify Deployments

Check that all namespaces are created. Verify pods are running in kube-system, argocd, monitoring, argo-rollouts, and external-dns namespaces. Confirm that Ingress resources are created and ALB is provisioned. Check that ExternalDNS has created Route53 records for custom domains.

### Step 7: Access Applications

Once ExternalDNS creates Route53 records, applications become accessible at their custom domains with SSL/TLS encryption. ArgoCD is accessible at argocd.testpro.in. Grafana is accessible at grafana.testpro.in. Default credentials and access instructions are in the "Accessing Services" section.

---

## 🌐 Accessing Services

### ArgoCD (GitOps Platform)

ArgoCD is accessible at https://argocd.testpro.in and provides a web UI for managing continuous deployments.

The default admin username is "admin". The initial password is automatically generated during deployment and must be retrieved from Kubernetes secrets. The interface allows for repository connections, application definitions, and deployment synchronization.

### Grafana (Monitoring Dashboard)

Grafana is accessible at https://grafana.testpro.in and provides visualization of cluster metrics.

The default username is "admin" and the password is "admin123" (or as configured). Pre-configured dashboards are available for Kubernetes cluster overview, node metrics, and pod resource usage. The interface allows for creating custom dashboards, setting up alerting rules, and data source configuration.

### Prometheus (Metrics Database)

Prometheus runs in the monitoring namespace and collects metrics from all cluster components.

Access Prometheus through port-forwarding to query metrics, view scrape targets, and verify metric collection. The database stores 15 days of metrics by default and can be queried using PromQL.

### AlertManager (Alert Routing)

AlertManager routes alerts to Slack channels based on severity.

Warning alerts route to the #alerts-warning channel. Critical alerts route to the #alerts-critical channel. Alerts include notification title, severity level, and affected resource information. Alert routing rules are configured in the AlertManager configuration secret.

### Service Access URLs

All services are secured with ACM SSL/TLS certificates. External DNS automatically creates Route53 records for Ingress resources. Load Balancer Controller provisions AWS ALBs for traffic routing. Each service is accessible via its configured custom domain.

---

## 🔐 Module Details

### VPC Module

The VPC module creates the network foundation for the entire infrastructure. It provisions a VPC with configurable CIDR block and creates subnets across specified availability zones. Public subnets have Internet Gateway access and map public IPs automatically. Private subnets have NAT Gateway access for outbound traffic. The module manages route tables separately for public and private networks with proper associations.

**Key Features**: Multi-AZ deployment, VPC Flow Logs for network monitoring, DNS support enabled, flexible CIDR configuration, optional NAT Gateway deployment.

### EKS Module

The EKS module provisions a managed Kubernetes cluster with production-ready configuration. It creates IAM roles for cluster control plane and node groups with appropriate policies. EC2 node groups use launch templates with IMDSv2 enforcement for security. Auto-scaling is configured with minimum, desired, and maximum capacity. The module creates an OIDC provider for IAM Roles for Service Accounts (IRSA) to enable fine-grained IAM permissions for pods.

**Key Features**: Managed control plane, auto-scaling node groups, OIDC provider for IRSA, IMDSv2 enforcement, security group management, configurable public/private API endpoint access.

### Helm Module

The Helm module deploys all Kubernetes applications and platform services using Helm charts. It manages AWS Load Balancer Controller with IRSA permissions for ALB provisioning. Prometheus is deployed with node exporters and service monitors. Grafana is configured with admin credentials and Prometheus data source. ArgoCD is deployed in insecure mode with ClusterIP service (accessed via Ingress). AlertManager is configured with Slack webhook URLs for notifications. ExternalDNS is configured with Route53 provider and domain filters. Argo Rollouts enables advanced deployment strategies like canary and blue-green deployments.

**Key Features**: IRSA for all AWS-integrated services, namespace management, service account creation, role-based access control, configurable values for each service, dependency management between services.

---

## 🧹 Cleanup

To remove all infrastructure and services from AWS (this action is irreversible):

First, destroy the platform layer services by navigating to the platform environment directory and executing terraform destroy. This removes all Kubernetes applications, services, and the ALB.

Then, destroy the infrastructure layer by navigating to the infrastructure environment directory and executing terraform destroy. This removes the EKS cluster, node groups, VPC, subnets, and all networking resources.

Finally, remove local kubeconfig entries for the cluster to clean up local configuration.

**Estimated Cleanup Time**: 15-20 minutes total

**Important Notes**: Ensure all data is backed up before cleanup. Persistent volumes may be retained if deletion protection is enabled. Load balancer may take time to fully delete. AWS charges continue until resources are completely removed.

---

## 📊 Estimated AWS Costs

| Component | Estimated Monthly Cost |
|-----------|------------------------|
| 3 × t3.small EC2 nodes | 45 USD |
| NAT Gateway (1 per AZ) | 32 USD |
| Application Load Balancer | 16 USD |
| EBS storage (30 GB) | 3 USD |
| Data transfer (100 GB out) | 5 USD |
| **Approximate Total** | **101 USD** |

Note: Costs vary by region, usage patterns, and AWS pricing changes. Use AWS Pricing Calculator for accurate estimates based on your specific configuration.

---

## 🔒 Security Considerations

**Implemented Security Features**
- Private subnets for EKS node groups (no direct internet exposure)
- IMDSv2 enforced on EC2 instances (prevents metadata service attacks)
- OIDC provider for IRSA (fine-grained IAM permissions for pods)
- ALB with ACM SSL/TLS certificates (encrypted traffic)
- VPC Flow Logs enabled (network monitoring)
- Security groups restrict traffic to required ports only
- Sensitive variables marked as sensitive in Terraform

**Recommended Additional Security Measures**
- Enable EKS audit logging to CloudWatch
- Use AWS Secrets Manager for credential management
- Implement Kubernetes network policies
- Enable Pod Security Policies
- Use container image scanning in ECR
- Implement RBAC for cluster access
- Enable encryption at rest for persistent volumes
- Use private hosted zones in Route53
- Implement WAF rules on ALB
- Enable GuardDuty for threat detection

---

## 🐛 Troubleshooting

**Cluster Access Issues**
- Verify kubeconfig is updated correctly
- Check AWS credentials and permissions
- Verify public access CIDR blocks allow your IP
- Check security groups for proper inbound rules

**Ingress Not Creating ALB**
- Verify AWS Load Balancer Controller is running
- Check controller logs for errors
- Verify IAM permissions for controller role
- Check Ingress annotations are correct

**Pods Not Reaching Internet**
- Verify NAT Gateway is deployed and healthy
- Check route tables have proper routes
- Verify security group rules allow egress
- Check node IAM role has required permissions

**DNS Not Resolving**
- Verify ExternalDNS pod is running
- Check ExternalDNS logs for Route53 API errors
- Verify hosted zone ID is correct
- Check Route53 records were created
- Verify TTL settings in DNS configuration

**Monitoring Data Missing**
- Verify Prometheus pod is running
- Check scrape targets in Prometheus UI
- Verify service monitors are created
- Check node exporter pods are running
- Verify network policies allow traffic

**Slack Alerts Not Working**
- Verify webhook URLs are correct and active
- Check AlertManager pod logs
- Verify alert rules are firing
- Check Slack channel permissions
- Verify firewall allows outbound HTTPS

---

## 📧 Support & Documentation

**Project Information**
- Owner: Amrendra
- Region: AWS Asia Pacific (Mumbai) - ap-south-1
- Environment: Development
- Repository: https://github.com/StoreMyProjects/Enterprise-project

**Documentation References**
- Terraform: https://www.terraform.io/docs
- AWS EKS: https://docs.aws.amazon.com/eks/
- Kubernetes: https://kubernetes.io/docs/
- ArgoCD: https://argo-cd.readthedocs.io/
- Prometheus: https://prometheus.io/docs/
- Grafana: https://grafana.com/docs/
- Helm: https://helm.sh/docs/

---

**Last Updated**: May 10, 2026  
**Repository Status**: Active  
**License**: Private - All Rights Reserved