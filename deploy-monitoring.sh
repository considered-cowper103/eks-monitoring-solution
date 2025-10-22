#!/bin/bash

set -e

echo "=========================================="
echo "Deploying CloudWatch Container Insights"
echo "=========================================="

echo "Waiting for IRSA setup to complete..."
sleep 30

echo "Creating CloudWatch agent configuration..."
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cwagent/cwagent-configmap.yaml

echo "Deploying CloudWatch agent..."
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cwagent/cwagent-daemonset.yaml

echo "Deploying Fluent Bit for log aggregation..."
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/fluent-bit/fluent-bit.yaml

echo ""
echo "Waiting for CloudWatch agents to be ready..."
kubectl wait --for=condition=ready pod -l name=cloudwatch-agent -n amazon-cloudwatch --timeout=300s || true

echo ""
echo "=========================================="
echo "CloudWatch Container Insights Status"
echo "=========================================="
kubectl get pods -n amazon-cloudwatch

echo ""
echo "=========================================="
echo "Deploying Prometheus (Complementary)"
echo "=========================================="

helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.retention=7d \
  --set prometheus.prometheusSpec.resources.requests.memory=2Gi \
  --set grafana.enabled=true \
  --set grafana.adminPassword=admin123 \
  --wait --timeout 10m

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="

echo ""
echo "✅ CloudWatch Container Insights (PRIMARY) - Check AWS Console:"
echo "   https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#container-insights:infrastructure"
echo ""
echo "✅ Prometheus - Access via port-forward:"
echo "   kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo ""
echo "✅ Grafana - Access via port-forward:"
echo "   kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "   Username: admin | Password: admin123"
echo ""
echo "📊 View Metrics in CloudWatch:"
echo "   - Container Insights Dashboard"
echo "   - CloudWatch Logs: /aws/containerinsights/monitoring-eks-cluster/*"
echo "   - Metrics: ContainerInsights namespace"
echo ""
