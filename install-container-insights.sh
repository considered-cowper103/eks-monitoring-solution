#!/bin/bash

CLUSTER_NAME="monitoring-eks-cluster"
REGION="us-east-1"

echo "======================================"
echo "Installing CloudWatch Container Insights using AWS Official Method"
echo "Cluster: $CLUSTER_NAME"
echo "Region: $REGION"
echo "======================================"
echo ""

ClusterName=$CLUSTER_NAME
RegionName=$REGION
FluentBitHttpPort='2020'
FluentBitReadFromHead='Off'
[[ ${FluentBitReadFromHead} = 'On' ]] && FluentBitReadFromTail='Off'|| FluentBitReadFromTail='On'
[[ -z ${FluentBitHttpPort} ]] && FluentBitHttpServer='Off' || FluentBitHttpServer='On'

echo "Deploying CloudWatch agent with IRSA..."
curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cwagent/cwagent-serviceaccount.yaml | kubectl apply -f - 

kubectl annotate serviceaccount cloudwatch-agent -n amazon-cloudwatch \
  eks.amazonaws.com/role-arn=arn:aws:iam::092382576187:role/eksctl-monitoring-eks-cluster-addon-iamservic-Role1-L2SouRYAUBaq \
  --overwrite

echo ""
echo "Deploying CloudWatch agent DaemonSet..."
curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cwagent/cwagent-configmap.yaml | sed "s/{{cluster_name}}/${ClusterName}/;s/{{region_name}}/${RegionName}/" | kubectl apply -f -

curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cwagent/cwagent-daemonset.yaml | sed "s/{{cluster_name}}/${ClusterName}/;s/{{region_name}}/${RegionName}/" | kubectl apply -f -

echo ""
echo "Waiting for CloudWatch agent pods to be ready..."
sleep 10
kubectl wait --for=condition=ready pod -l name=cloudwatch-agent -n amazon-cloudwatch --timeout=120s

echo ""
echo "======================================"
echo "CloudWatch Container Insights Status"
echo "======================================"
kubectl get pods -n amazon-cloudwatch -l name=cloudwatch-agent
kubectl get sa cloudwatch-agent -n amazon-cloudwatch -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}'
echo ""
echo ""
echo "Checking CloudWatch agent logs..."
kubectl logs -n amazon-cloudwatch -l name=cloudwatch-agent --tail=10 | tail -20

echo ""
echo "======================================"
echo "Container Insights deployed successfully!"
echo "Metrics will appear in CloudWatch Console in 2-5 minutes"
echo "Navigate to: CloudWatch > Container Insights > Performance monitoring"
echo "======================================"
