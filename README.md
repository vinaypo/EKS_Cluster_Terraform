# AWS EKS End-to-End Platform

A production-grade Amazon EKS platform provisioned with Terraform, managed via GitOps with ArgoCD, and fully observable with Prometheus, Grafana, and the Elastic Cloud on Kubernetes (ECK) stack.

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Project Structure](#project-structure)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [1. GitHub OIDC Setup](#1-github-oidc-setup)
  - [2. VPC & Bastion Host](#2-vpc--bastion-host)
  - [3. EKS Cluster](#3-eks-cluster)
  - [4. Gateway API & Ingress](#4-gateway-api--ingress)
  - [5. ArgoCD](#5-argocd)
  - [6. Observability](#6-observability)
  - [7. Logging (ECK)](#7-logging-eck)
- [Security](#security)
- [Cost Optimization](#cost-optimization)
- [Cleanup](#cleanup)
- [License](#license)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AWS Cloud (us-east-1)                           │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                          VPC (3 AZs)                               │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │   │
│  │  │  Public Subnet │  │  Public Subnet │  │  Public Subnet │             │   │
│  │  │   (ALB/NLB)    │  │   (ALB/NLB)    │  │   (ALB/NLB)    │             │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘             │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │   │
│  │  │ Private Subnet │  │ Private Subnet │  │ Private Subnet │             │   │
│  │  │  (EKS Nodes)   │  │  (EKS Nodes)   │  │  (EKS Nodes)   │             │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘             │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │   │
│  │  │ Bastion+Runner │  │ Bastion+Runner │  │ Bastion+Runner │             │   │
│  │  │  (Jump Box +   │  │  (Jump Box +   │  │  (Jump Box +   │             │   │
│  │  │ Self-Hosted)   │  │ Self-Hosted)   │  │ Self-Hosted)   │             │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘             │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         EKS Cluster (Control Plane)                  │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────────┐ │   │
│  │  │  Gateway API │  │   ArgoCD    │  │ Prometheus  │  │  Grafana  │ │   │
│  │  │  (AWS LBC)   │  │  (GitOps)   │  │  + Alertmgr │  │ Dashboard │ │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └───────────┘ │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────────┐ │   │
│  │  │ ExternalDNS  │  │  ECK Stack  │  │  Filebeat   │  │  Kibana   │ │   │
│  │  │  (Route 53)  │  │Elasticsearch│  │  (Logging)  │  │  (Logs)   │ │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └───────────┘ │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    GitHub Actions (CI/CD)                          │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │   │
│  │  │   VPC Plan   │  │   VPC Apply  │  │  EKS Deploy  │              │   │
│  │  │   (OIDC)     │  │   (OIDC)     │  │  (Bastion as │              │   │
│  │  │              │  │              │  │ Self-Hosted   │              │   │
│  │  │              │  │              │  │    Runner)    │              │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘              │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Project Structure

```
EKS_Cluster_Terraform/
│
├── .github/workflows/          # GitHub Actions CI/CD pipelines
│   ├── eks.yaml                # EKS cluster deployment workflow
│   └── vpc-ec2.yaml            # VPC, Bastion, and Runner deployment workflow
│
├── eks/                        # EKS cluster Terraform configuration
│   ├── backend.tf              # S3 remote state backend
│   ├── eks.tf                  # EKS cluster root module
│   ├── gather.tf               # Data sources for VPC/Subnets/Security Groups
│   ├── helm-argocd.tf          # ArgoCD Helm release via Terraform
│   ├── helm-external-dns.tf    # ExternalDNS Helm release
│   ├── helm-lb-controller.tf   # AWS Load Balancer Controller Helm release
│   ├── helm-metrics-server.tf  # Metrics Server Helm release
│   ├── helm-prometheus.tf      # kube-prometheus-stack Helm release
│   ├── kubernetes-external-dns.tf    # ExternalDNS IAM + Pod Identity
│   ├── kubernetes-sa-lb-controller.tf  # LB Controller IAM + Pod Identity
│   ├── providers.tf            # Terraform providers (AWS, Kubernetes, Helm)
│   ├── variables.tf            # Input variables
│   └── .terraform/             # Terraform plugins & state cache
│
├── modules/                    # Reusable Terraform modules
│   ├── ec2/                    # EC2 instance module (Bastion + Runner)
│   ├── eks/                    # EKS cluster module
│   └── vpc/                    # VPC module
│
├── vpc-ec2/                    # VPC, Bastion Host & Self-Hosted Runner root
│   ├── backend.tf              # S3 remote state backend
│   ├── ec2.tf                  # EC2 module call (Bastion + Runner)
│   ├── providers.tf            # AWS provider configuration
│   ├── variables.tf            # Root module variables
│   ├── vpc.tf                  # VPC module call
│   └── .terraform/
│
├── gatewayapi/                 # Gateway API CRDs & configuration
│   ├── alb-config.yaml         # AWS Load Balancer Configuration (TLS cert)
│   ├── gateway.yaml            # Gateway resource definition
│   ├── gatewayclass.yaml       # GatewayClass for AWS LBC
│   └── gatewayinstallsteps.sh  # Script to install Gateway API CRDs
│
├── github-oidc/                # GitHub OIDC authentication setup
│   ├── configure-oidc-github.sh # Script to create OIDC provider & IAM role
│   └── trust-policy.json       # Trust policy for GitHubActionsEKSDeployRole
│
├── argocd/                     # ArgoCD-specific configurations
│   └── targetconfig.yaml       # TargetGroupConfiguration for ArgoCD
│
├── observability/              # Monitoring & alerting manifests
│   ├── HTTPRoute-alertmanager.yaml
│   ├── HTTPRoute-grafana.yaml
│   ├── HTTPRoute-kibana.yaml
│   ├── HTTPRoute-prometheus.yaml
│   ├── storageclass.yaml       # EBS StorageClass for Elasticsearch
│   ├── targetgroup-alertmanager.yaml
│   ├── targetgroup-grafana.yaml
│   ├── targetgroup-kibana.yaml
│   └── targetgroup-prometheus.yaml
│
├── values/                     # Helm values files
│   ├── argocd/
│   │   ├── argocd-image-updater-values-1.2.2.yaml
│   │   └── argocd-values-9.4.0.yaml
│   ├── external-dns/
│   │   └── external-dns-values-1.20.0.yaml
│   └── observability/
│       ├── eck-beats-0.18.0.yaml
│       ├── eck-elasticsearch-0.18.0.yaml
│       ├── eck-kibana-0.18.0.yaml
│       └── kube-prom-stack-81.6.3.yaml
│
├── prod/                       # Production environment scripts & variables
│   ├── install.sh
│   ├── install.sh.tpl          # Cloud-init template (injects github_pat)
│   ├── jenkins-tools-install.sh
│   └── prod.tfvars             # Production tfvars
│
└── project/                    # Project-level configurations
```

---

## Tech Stack

| Category | Technology | Purpose |
|----------|------------|---------|
| **IaC** | Terraform >= 1.10.5 | Infrastructure provisioning |
| **Container Orchestration** | Amazon EKS v1.31+ | Kubernetes cluster management |
| **CI/CD** | GitHub Actions | Automated pipelines with OIDC auth |
| **GitOps** | ArgoCD v9.4.0 | Declarative application deployment |
| **Ingress** | Gateway API v1.3.0 + AWS Load Balancer Controller v3.0.0 | TLS-terminated traffic routing |
| **DNS** | ExternalDNS v1.20.0 + Route 53 | Automated DNS record management |
| **Monitoring** | kube-prometheus-stack v81.6.3 | Metrics, dashboards & alerts |
| **Alerting** | Alertmanager + Slack Webhooks | Alert notifications |
| **Logging** | ECK v3.3.0 (Elasticsearch + Filebeat + Kibana) | Centralized log aggregation |
| **Storage** | Amazon EBS CSI Driver v1.60.0 | Persistent volume provisioning |
| **Security** | GitHub OIDC, IRSA, EKS Pod Identity, RBAC, NetworkPolicies | Zero-trust security model |
| **Cost Optimization** | Hybrid On-Demand + Spot Instances | Cost-efficient compute |

---

## Prerequisites

- AWS Account with appropriate IAM permissions
- GitHub Account & Repository
- AWS CLI configured locally
- Terraform >= 1.10.5
- kubectl
- helm
- A registered domain name (for ExternalDNS & Gateway API)
- An ACM certificate ARN (for HTTPS termination)
- Slack workspace (for Alertmanager notifications)
- GitHub Personal Access Token (PAT) for self-hosted runner registration

---

## Getting Started

### 1. GitHub OIDC Setup

Configure GitHub Actions to authenticate with AWS without storing long-lived credentials.

```bash
cd github-oidc/
# Review the trust policy
cat trust-policy.json
# Run the OIDC setup script
./configure-oidc-github.sh
```

This creates:
- An **OIDC Identity Provider** for GitHub in AWS IAM
- An **IAM Role** (`GitHubActionsEKSDeployRole`) with a trust policy that only allows the `vinaypo/EKS_Cluster_Terraform` repository to assume it via `sts:AssumeRoleWithWebIdentity`

**`github-oidc/trust-policy.json`**:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::741448944841:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:vinaypo/EKS_Cluster_Terraform:*"
                },
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                }
            }
        }
    ]
}
```

**`github-oidc/configure-oidc-github.sh`**:
```bash
#!/bin/bash
set -e

export OIDC_PROVIDER="token.actions.githubusercontent.com"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

export GITHUB_ORG="vinaypo"
export GITHUB_REPO="EKS_Cluster_Terraform"

# Create the OIDC provider
aws iam create-open-id-connect-provider \
  --url https://$OIDC_PROVIDER \
  --client-id-list sts.amazonaws.com

# Create IAM Role for GitHub Actions
aws iam create-role \
  --role-name GitHubActionsEKSDeployRole \
  --assume-role-policy-document file://trust-policy.json

# Attach AdministratorAccess policy to the role
aws iam attach-role-policy \
  --role-name GitHubActionsEKSDeployRole \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

---

### 2. VPC & Bastion Host

Deploy the VPC, subnets, NAT gateways, bastion host, and self-hosted GitHub Actions runner.

#### GitHub Actions Workflow

**`.github/workflows/vpc-ec2.yaml`**:
```yaml
name: "Infra Bootstrap (VPC + Bastion + Runner)"

on:
  workflow_dispatch:
    inputs:
      environment:
        type: choice
        options: [dev, stage, prod]
        required: true
        default: dev
      action:
        type: choice
        options: [plan, apply, destroy]
        required: true
        default: plan

permissions:
  id-token: write
  contents: read

jobs:
  vpc:
    runs-on: ubuntu-latest

    defaults:
      run:
        working-directory: vpc-ec2

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/GitHubActionsEKSDeployRole
          role-session-name: github-actions
          aws-region: us-east-1

      - name: Verify AWS Credentials
        run: aws sts get-caller-identity

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Init
        run: terraform init

      - name: Terraform Workspace
        run: |
          terraform workspace select ${{ github.event.inputs.environment }} || \
          terraform workspace new ${{ github.event.inputs.environment }}

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan
        if: ${{ github.event.inputs.action != 'destroy' }}
        run: |
          terraform plan \
          -var-file="../${{ github.event.inputs.environment }}/${{ github.event.inputs.environment }}.tfvars" \
          -var="github_pat=${{ secrets.GH_PAT }}"

      - name: Terraform Apply
        if: ${{ github.event.inputs.action == 'apply' }}
        run: |
          terraform apply -auto-approve \
          -var-file="../${{ github.event.inputs.environment }}/${{ github.event.inputs.environment }}.tfvars" \
          -var="github_pat=${{ secrets.GH_PAT }}"

      - name: Terraform Destroy Plan
        if: ${{ github.event.inputs.action == 'destroy' }}
        run: |
          terraform plan -destroy \
          -var-file="../${{ github.event.inputs.environment }}/${{ github.event.inputs.environment }}.tfvars" \
          -var="github_pat=${{ secrets.GH_PAT }}"

      - name: Terraform Destroy
        if: ${{ github.event.inputs.action == 'destroy' }}
        run: |
          terraform destroy -auto-approve \
          -var-file="../${{ github.event.inputs.environment }}/${{ github.event.inputs.environment }}.tfvars" \
          -var="github_pat=${{ secrets.GH_PAT }}"
```

> **Note:** The `github_pat` variable is passed via `-var="github_pat=${{ secrets.GH_PAT }}"` in the workflow. For manual runs, pass it the same way: `terraform plan -var="github_pat=ghp_xxx" -var-file=../prod/prod.tfvars`

**What gets created:**
- VPC across 3 AZs with public & private subnets
- Internet Gateway, NAT Gateways, Route Tables
- Bastion Host (EC2) in public subnet — serves dual purpose as:
  - SSH jump box for secure cluster access
  - Self-Hosted GitHub Actions Runner for EKS deployment workflows

The instance uses a **GitHub Personal Access Token (PAT)** injected via the `install.sh.tpl` cloud-init template to register itself as a self-hosted runner with your repository.

---

### 3. EKS Cluster

#### GitHub Actions Workflow

**`.github/workflows/eks.yaml`**:
```yaml
name: "EKS Bootstrap (Helm + Addons)"

on:
  workflow_dispatch:
    inputs:
      environment:
        type: choice
        options: [dev, stage, prod]
        required: true
      action:
        type: choice
        options: [plan, apply, destroy]
        required: true
        default: plan

permissions:
  id-token: write
  contents: read

jobs:
  eks:
    runs-on: [self-hosted, eks]

    defaults:
      run:
        working-directory: eks

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/GitHubActionsEKSDeployRole
          role-session-name: github-actions
          aws-region: us-east-1

      - name: Verify AWS Credentials
        run: aws sts get-caller-identity

      - name: Terraform Init
        run: terraform init -upgrade

      - name: Terraform Workspace
        run: |
          terraform workspace select ${{ github.event.inputs.environment }} || \
          terraform workspace new ${{ github.event.inputs.environment }}

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan
        if: ${{ github.event.inputs.action != 'apply' }}
        run: |
          terraform plan \
          -var-file="../${{ github.event.inputs.environment }}/${{ github.event.inputs.environment }}.tfvars"

      - name: Terraform Apply
        if: ${{ github.event.inputs.action == 'apply' }}
        run: |
          terraform apply -auto-approve \
          -var-file="../${{ github.event.inputs.environment }}/${{ github.event.inputs.environment }}.tfvars"

      - name: Terraform Destroy Plan
        if: ${{ github.event.inputs.action == 'destroy' }}
        run: |
          terraform plan -destroy \
          -var-file="../${{ github.event.inputs.environment }}/${{ github.event.inputs.environment }}.tfvars"

      - name: Terraform Destroy
        if: ${{ github.event.inputs.action == 'destroy' }}
        run: |
          terraform destroy -auto-approve \
          -var-file="../${{ github.event.inputs.environment }}/${{ github.event.inputs.environment }}.tfvars"
```

> **Note:** The EKS workflow runs on `[self-hosted, eks]` runners (the bastion host), enabling secure access to the EKS cluster API without exposing it to the public internet.

#### Cluster Access (Manual)

SSH into the bastion host and configure cluster access:

```bash
# SSH into bastion
ssh -i your-key.pem ec2-user@<bastion-public-ip>

# Clone the repository inside the bastion
git clone https://github.com/vinaypo/EKS_Cluster_Terraform.git
cd EKS_Cluster_Terraform/eks/

# Configure AWS profile for cluster access
aws configure --profile User1

# Assume the cluster admin role
aws sts assume-role \
  --role-arn arn:aws:iam::<account-id>:role/<cluster-admin-role> \
  --role-session-name test \
  --profile User1

# Update kubeconfig
aws eks update-kubeconfig \
  --region us-east-1 \
  --name <cluster-name> \
  --role-arn <cluster-admin-role-arn> \
  --alias admin \
  --user-alias eks-admin \
  --profile User1

# Verify access
kubectl auth can-i '*' '*'
```

**What gets created:**
- EKS Control Plane (managed by AWS)
- Managed Node Groups (Hybrid On-Demand + Spot across 3 AZs)
- EKS Add-ons (EBS CSI Driver, CoreDNS, kube-proxy, VPC CNI, EKS Pod Identity Agent)
- IRSA & EKS Pod Identity for workload IAM roles
- EKS Access Entries for cluster administrators, developers, and managers

---

### 4. Gateway API & Ingress

Install the Gateway API CRDs and configure the AWS Load Balancer Controller.

**`gatewayapi/gatewayinstallsteps.sh`**:
```bash
#!/usr/bin/env bash

set -e

echo "Installing Gateway API v1.3.0 (standard)..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml

echo "Installing Gateway API v1.3.0 (experimental)..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/experimental-install.yaml

echo "Installing AWS Gateway API CRDs..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/refs/heads/main/config/crd/gateway/gateway-crds.yaml

echo "Done."
```

```bash
cd gatewayapi/

# Install Gateway API CRDs
./gatewayinstallsteps.sh

# Apply Gateway resources
kubectl apply -f gatewayclass.yaml
kubectl apply -f gateway.yaml

# Configure ALB with your ACM certificate ARN
# Edit alb-config.yaml and replace <certificate arn> with your ACM cert ARN
kubectl apply -f alb-config.yaml
```

**`gatewayapi/gatewayclass.yaml`**:
```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: GatewayClass
metadata:
  name: aws-alb-gateway-class
spec:
  controllerName: gateway.k8s.aws/alb
```

**`gatewayapi/gateway.yaml`**:
```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: app-alb-gateway
  namespace: default
spec:
  gatewayClassName: aws-alb-gateway-class
  infrastructure:
    parametersRef:
      kind: LoadBalancerConfiguration
      name: app-gw-lbconfig
      group: gateway.k8s.aws
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      hostname: "*.thedevopsnow.online"
      allowedRoutes:
        namespaces:
          from: All
    - name: https
      protocol: HTTPS
      hostname: "*.thedevopsnow.online"
      port: 443
      allowedRoutes:
        namespaces:
          from: All
```

**`gatewayapi/alb-config.yaml`**:
```yaml
apiVersion: gateway.k8s.aws/v1beta1
kind: LoadBalancerConfiguration
metadata:
  name: app-gw-lbconfig
  namespace: default
spec:
  scheme: internet-facing
  listenerConfigurations:
    - protocolPort: HTTPS:443
      defaultCertificate: <certificate arn>
```

**Key concepts:**
- **GatewayClass**: Defines the controller (AWS Load Balancer Controller)
- **Gateway**: Defines listeners (HTTP on port 80, HTTPS on port 443)
- **LoadBalancerConfiguration**: Defines how the AWS ALB is built (TLS cert, scheme, subnets)
- **TargetGroupConfiguration**: Defines where traffic is routed (IP target type)

---

### 5. ArgoCD

Deploy ArgoCD via Helm and expose it through the Gateway API.

```bash
# ArgoCD is installed via Terraform (helm-argocd.tf)
# Apply the target group configuration for ArgoCD
kubectl apply -f argocd/targetconfig.yaml
```

**`argocd/targetconfig.yaml`**:
```yaml
apiVersion: gateway.k8s.aws/v1beta1
kind: TargetGroupConfiguration
metadata:
  name: argo-tg-config
  namespace: argocd
spec:
  targetReference:
    name: argocd-server
  defaultConfiguration:
    targetType: ip
```

```bash
# Create the HTTPRoute for ArgoCD (defined in values/argocd/argocd-values-9.4.0.yaml)
# ExternalDNS will automatically create the Route 53 record

# Get the ArgoCD admin password
kubectl get secret -n argocd argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d

# Access ArgoCD at: https://argocd.yourdomain.com
```

---

### 6. Observability

#### 6.1 Setup Slack Webhook

1. Go to [https://api.slack.com/apps](https://api.slack.com/apps)
2. Create a New App **From Scratch**
3. Name it (e.g., `EKS-Alerts`) and select your workspace
4. Navigate to **Incoming Webhooks** → Turn ON → **Add New Webhook to Workspace**
5. Select your `#alertmanager` channel and authorize
6. Copy the webhook URL

#### 6.2 Create Kubernetes Secret

```bash
kubectl create secret generic alertmanager-slack-webhook \
  --from-literal=slack-webhook-url="https://hooks.slack.com/services/YOUR/WEBHOOK/URL" \
  -n monitoring
```

#### 6.3 Install kube-prometheus-stack

```bash
# Add Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install with custom values
cd values/observability/
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -f kube-prom-stack-81.6.3.yaml \
  -n monitoring \
  --create-namespace
```

The `alertmanagerSpec` in the values file mounts the Slack webhook secret into the Alertmanager pod.

#### 6.4 Expose Grafana & Prometheus

```bash
# Apply HTTPRoutes and TargetGroupConfigurations
kubectl apply -f observability/HTTPRoute-prometheus.yaml
kubectl apply -f observability/HTTPRoute-grafana.yaml
kubectl apply -f observability/targetgroup-prometheus.yaml
kubectl apply -f observability/targetgroup-grafana.yaml

# ExternalDNS will automatically create DNS records
```

**`observability/HTTPRoute-prometheus.yaml`**:
```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: prometheus-route
  namespace: monitoring
spec:
  hostnames:
    - "prometheus.thedevopsnow.online"
  parentRefs:
    - group: gateway.networking.k8s.io
      namespace: default
      kind: Gateway
      name: app-alb-gateway
      sectionName: http
    - group: gateway.networking.k8s.io
      namespace: default
      kind: Gateway
      name: app-alb-gateway
      sectionName: https
  rules:
    - backendRefs:
        - name: monitoring-kube-prometheus-prometheus
          port: 9090
```

**`observability/HTTPRoute-grafana.yaml`**:
```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: grafana-route
  namespace: monitoring
spec:
  hostnames:
    - "grafana.thedevopsnow.online"
  parentRefs:
    - group: gateway.networking.k8s.io
      namespace: default
      kind: Gateway
      name: app-alb-gateway
      sectionName: http
    - group: gateway.networking.k8s.io
      namespace: default
      kind: Gateway
      name: app-alb-gateway
      sectionName: https
  rules:
    - backendRefs:
        - name: monitoring-grafana
          port: 80
```

**`observability/targetgroup-prometheus.yaml`**:
```yaml
apiVersion: gateway.k8s.aws/v1beta1
kind: TargetGroupConfiguration
metadata:
  name: prometheus-tg-config
  namespace: monitoring
spec:
  targetReference:
    name: monitoring-kube-prometheus-prometheus
  defaultConfiguration:
    targetType: ip
```

**`observability/targetgroup-grafana.yaml`**:
```yaml
apiVersion: gateway.k8s.aws/v1beta1
kind: TargetGroupConfiguration
metadata:
  name: grafana-tg-config
  namespace: monitoring
spec:
  targetReference:
    name: monitoring-grafana
  defaultConfiguration:
    targetType: ip
```

#### 6.5 Access Grafana

```bash
# Get Grafana admin password
kubectl get secret -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath='{.data.admin-password}' | base64 -d

# Access at: https://grafana.yourdomain.com
```

---

### 7. Logging (ECK)

#### 7.1 Prerequisites

Ensure the **EBS CSI Driver** EKS add-on is installed and linked to an IAM role via EKS Pod Identity (configured in Terraform).

```bash
# Create logging namespace
kubectl create ns logging
```

#### 7.2 Install ECK Operator

```bash
helm repo add elastic https://helm.elastic.co
helm repo update

helm install eck-operator elastic/eck-operator \
  --version 3.3.0 \
  -n logging
```

#### 7.3 Create StorageClass

```bash
kubectl apply -f observability/storageclass.yaml
```

**`observability/storageclass.yaml`**:
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-aws
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.aws.com
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
```

#### 7.4 Install Elasticsearch

```bash
cd values/observability/
helm install eck-elasticsearch elastic/eck-elasticsearch \
  --version 0.18.0 \
  -n logging
```

#### 7.5 Install Filebeat (eck-beats)

```bash
helm install eck-beats elastic/eck-beats \
  --version 0.18.0 \
  -f eck-beats-0.18.0.yaml \
  -n logging
```

#### 7.6 Install Kibana

```bash
helm install eck-kibana elastic/eck-kibana \
  --version 0.18.0 \
  -f eck-kibana-0.18.0.yaml \
  -n logging
```

#### 7.7 Expose Kibana

```bash
kubectl apply -f observability/HTTPRoute-kibana.yaml
kubectl apply -f observability/targetgroup-kibana.yaml
```

**`observability/HTTPRoute-kibana.yaml`**:
```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: kibana-route
  namespace: logging
spec:
  hostnames:
    - "kibana.thedevopsnow.online"
  parentRefs:
    - group: gateway.networking.k8s.io
      namespace: default
      kind: Gateway
      name: app-alb-gateway
      sectionName: http
    - group: gateway.networking.k8s.io
      namespace: default
      kind: Gateway
      name: app-alb-gateway
      sectionName: https
  rules:
    - backendRefs:
        - name: eck-kibana-kb-http
          port: 5601
```

**`observability/targetgroup-kibana.yaml`**:
```yaml
apiVersion: gateway.k8s.aws/v1beta1
kind: TargetGroupConfiguration
metadata:
  name: kibana-tg-config
  namespace: logging
spec:
  targetReference:
    name: eck-kibana-kb-http
  defaultConfiguration:
    targetType: ip
    protocol: HTTPS
    healthCheckConfig:
      healthCheckProtocol: HTTPS
      healthCheckPath: /api/status
```

#### 7.8 Access Kibana

```bash
# Get Elasticsearch credentials
kubectl get secret eck-elasticsearch-es-elastic-user -n logging \
  -o go-template='{{"{{"}}.data.elastic | base64decode{{"}}"}}'

# Username: elastic
# Access at: https://kibana.yourdomain.com
```

---

## Security

| Layer | Implementation |
|-------|----------------|
| **CI/CD Authentication** | GitHub OIDC (no long-lived AWS credentials) |
| **Cluster Access** | EKS Access Entries + IAM Roles (Admin, Developer, Manager) |
| **Workload Identity** | IRSA + EKS Pod Identity (LB Controller, ExternalDNS, EBS CSI) |
| **Network Security** | Subnet-level Security Groups + SSH restricted to my IP |
| **RBAC** | Kubernetes RBAC via EKS Access Policies (ClusterAdmin, View) |
| **Secrets** | Kubernetes Secrets (Slack webhook) mounted into pods |
| **TLS** | ACM certificates + Gateway API HTTPS listeners |
| **Bastion Access** | SSH key-based access to jump box only |
| **Self-Hosted Runners** | Deployed in private subnets for secure EKS API access |

---

## Cost Optimization

- **Hybrid Node Strategy**: Mix of On-Demand (baseline) and Spot Instances (burstable workloads)
- **Multi-AZ Distribution**: High availability without over-provisioning
- **NAT Gateway Optimization**: Shared NAT Gateways across AZs where possible
- **Right-sizing**: Node groups configured for actual workload requirements

---

## Cleanup

```bash
# Destroy EKS resources
cd eks/
terraform destroy

# Destroy VPC & EC2 resources
cd ../vpc-ec2/
terraform destroy

# Delete OIDC provider and IAM role (manual or via script)
```

---

## License

This project is for educational and personal use. Feel free to fork and adapt for your own infrastructure needs.

---

## Acknowledgments

- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Gateway API](https://gateway-api.sigs.k8s.io/)
- [ArgoCD](https://argo-cd.readthedocs.io/)
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Elastic Cloud on Kubernetes (ECK)](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-overview.html)
