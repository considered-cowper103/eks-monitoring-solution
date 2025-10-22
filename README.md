# EKS Monitoring with CloudWatch Container Insights and Prometheus

Production-grade monitoring solution for Amazon EKS using CloudWatch Container Insights as the primary monitoring platform and Prometheus/Grafana as complementary tooling.

## Overview

This project implements comprehensive observability for Kubernetes workloads on Amazon EKS, combining native AWS monitoring (CloudWatch Container Insights) with open-source tools (Prometheus, Grafana).

**Key Components:**
- CloudWatch Container Insights (EKS addon) - Primary monitoring
- Prometheus + Grafana - Complementary metrics and visualization
- Fluent Bit - Log aggregation
- Multi-AZ VPC with EKS cluster
- IRSA (IAM Roles for Service Accounts) for secure AWS API access

## Architecture

The infrastructure consists of:
- **VPC**: Multi-AZ setup with public, private-app, private-data, and private-monitoring subnets
- **EKS Cluster**: Kubernetes 1.31 with 2 node groups (monitoring: t3.large, applications: t3.medium)
- **Monitoring Stack**:
  - CloudWatch Container Insights addon
  - Prometheus Operator with Alertmanager
  - Grafana with pre-built dashboards
  - Node exporters for host metrics

## Prerequisites

- AWS CLI configured
- Terraform >= 1.9.0
- kubectl >= 1.29
- Helm >= 3.0
- eksctl (for IRSA setup)

## Quick Start

### 1. Deploy Infrastructure

```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

### 2. Configure kubectl

```bash
aws eks update-kubeconfig --name monitoring-eks-cluster --region us-east-1
```

### 3. Install CloudWatch Container Insights

Using EKS addon (recommended):

```bash
# Create IAM role for CloudWatch agent
eksctl create iamserviceaccount \
  --name cloudwatch-agent \
  --namespace amazon-cloudwatch \
  --cluster monitoring-eks-cluster \
  --attach-policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy \
  --approve \
  --override-existing-serviceaccounts

# Install the addon
aws eks create-addon \
  --cluster-name monitoring-eks-cluster \
  --addon-name amazon-cloudwatch-observability \
  --service-account-role-arn <ROLE_ARN>
```

### 4. Install Prometheus Stack

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.retention=7d \
  --set grafana.enabled=true \
  --set grafana.adminPassword=admin123
```

### 5. Deploy Sample Application

```bash
kubectl apply -f sample-app.yaml
```

## Accessing Monitoring Tools

### CloudWatch Container Insights

Access via AWS Console:
1. Navigate to CloudWatch > Container Insights > Performance monitoring
2. Select cluster: `monitoring-eks-cluster`
3. View metrics for cluster, nodes, pods, and containers

### Grafana

```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```
Access at http://localhost:3000 (admin/admin123)

### Prometheus

```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```
Access at http://localhost:9090

## Verification

Check all components are running:

```bash
# CloudWatch Container Insights
kubectl get pods -n amazon-cloudwatch

# Prometheus Stack
kubectl get pods -n monitoring

# Sample Application
kubectl get pods -n default
```

Verify metrics in CloudWatch:

```bash
aws cloudwatch list-metrics \
  --namespace ContainerInsights \
  --dimensions Name=ClusterName,Value=monitoring-eks-cluster
```

## Infrastructure Details

**VPC Configuration:**
- CIDR: 10.0.0.0/16
- Availability Zones: 3
- NAT Gateways: 3 (one per AZ)
- VPC Endpoints: ECR, S3, CloudWatch Logs

**EKS Configuration:**
- Version: 1.31
- Node Groups: 2 (monitoring, applications)
- Total Nodes: 4
- OIDC Provider: Enabled for IRSA

**Monitoring:**
- CloudWatch agents: 4 (DaemonSet, one per node)
- Fluent Bit: 4 (DaemonSet for logs)
- Prometheus replicas: 2
- Grafana replicas: 3

## Cost Considerations

- EKS cluster: ~$0.10/hour
- EC2 instances: 2x t3.large + 2x t3.medium
- NAT Gateways: 3x $0.045/hour
- CloudWatch metrics: Pay per metric ingested
- VPC endpoints reduce data transfer costs

## Security

- IRSA used for CloudWatch agent (no static credentials)
- Private subnets for workloads
- Security groups restrict traffic
- CloudWatch Logs encrypted at rest
- IAM roles follow least privilege principle

## Cleanup

```bash
# Delete sample application
kubectl delete -f sample-app.yaml

# Uninstall Prometheus
helm uninstall prometheus -n monitoring

# Delete CloudWatch addon
aws eks delete-addon --cluster-name monitoring-eks-cluster --addon-name amazon-cloudwatch-observability

# Destroy infrastructure
cd terraform/
terraform destroy
```

## Troubleshooting

**CloudWatch agent not running:**
```bash
kubectl logs -n amazon-cloudwatch -l app.kubernetes.io/name=cloudwatch-agent
kubectl describe pod -n amazon-cloudwatch -l app.kubernetes.io/name=cloudwatch-agent
```

**No metrics in CloudWatch:**
- Verify IRSA is configured correctly
- Check IAM role trust policy includes OIDC provider
- Wait 5-10 minutes for initial metric propagation

**Prometheus targets down:**
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Check http://localhost:9090/targets
```

## Project Structure

```
monitoring/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   └── modules/
│       ├── vpc/
│       └── eks/
├── deploy-monitoring.sh
├── install-container-insights.sh
├── sample-app.yaml
├── cloudwatch-policy.json
└── README.md
```

## License

MIT License - See LICENSE file for details.
