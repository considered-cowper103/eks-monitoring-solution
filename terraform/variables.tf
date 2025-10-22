variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}


variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "monitoring"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
}


variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}


variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "monitoring-eks-cluster"
}

variable "eks_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.34"
}

variable "eks_node_groups" {
  description = "EKS node group configurations"
  type = map(object({
    desired_size   = number
    min_size       = number
    max_size       = number
    instance_types = list(string)
    capacity_type  = optional(string, "ON_DEMAND")
    disk_size      = optional(number, 50)
    labels         = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  default = {
    monitoring = {
      desired_size   = 3
      min_size       = 2
      max_size       = 5
      instance_types = ["m6i.xlarge"]
      disk_size      = 100
      labels = {
        role = "monitoring"
      }
    }
    applications = {
      desired_size   = 3
      min_size       = 2
      max_size       = 10
      instance_types = ["c6i.2xlarge"]
      disk_size      = 50
      labels = {
        role = "applications"
      }
    }
  }
}


variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "monitoring-ecs-cluster"
}

variable "ecs_launch_types" {
  description = "ECS launch types to enable"
  type        = list(string)
  default     = ["FARGATE", "EC2"]
}

variable "ecs_ec2_instance_types" {
  description = "Instance types for ECS EC2 capacity provider"
  type        = list(string)
  default     = ["c6i.large", "c6i.xlarge"]
}

variable "ecs_ec2_desired_capacity" {
  description = "Desired number of ECS EC2 instances"
  type        = number
  default     = 3
}

variable "ecs_ec2_min_capacity" {
  description = "Minimum number of ECS EC2 instances"
  type        = number
  default     = 1
}

variable "ecs_ec2_max_capacity" {
  description = "Maximum number of ECS EC2 instances"
  type        = number
  default     = 10
}


variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = true
}

variable "enable_prometheus" {
  description = "Enable Prometheus monitoring"
  type        = bool
  default     = true
}

variable "enable_grafana" {
  description = "Enable Grafana dashboards"
  type        = bool
  default     = true
}

variable "enable_thanos" {
  description = "Enable Thanos for long-term storage"
  type        = bool
  default     = true
}

variable "enable_loki" {
  description = "Enable Loki for log aggregation"
  type        = bool
  default     = true
}

variable "enable_xray" {
  description = "Enable AWS X-Ray for distributed tracing"
  type        = bool
  default     = true
}

# Storage Retention Configuration
variable "prometheus_retention_days" {
  description = "Prometheus data retention in days"
  type        = number
  default     = 15
}

variable "thanos_retention_days" {
  description = "Thanos long-term storage retention in days"
  type        = number
  default     = 365
}

variable "loki_retention_days" {
  description = "Loki log retention in days"
  type        = number
  default     = 30
}

variable "cloudwatch_retention_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 7
}

# Alerting Configuration
variable "alert_email" {
  description = "Email address for alert notifications"
  type        = string
  default     = ""
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = ""
  sensitive   = true
}

variable "pagerduty_key" {
  description = "PagerDuty integration key"
  type        = string
  default     = ""
  sensitive   = true
}

# Resource Tags
variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "Monitoring"
    ManagedBy   = "Terraform"
    Environment = "Production"
  }
}

# Cost Optimization
variable "enable_spot_instances" {
  description = "Enable spot instances for cost savings"
  type        = bool
  default     = true
}

variable "spot_instance_pools" {
  description = "Number of spot instance pools"
  type        = number
  default     = 3
}

# Security Configuration
variable "enable_encryption" {
  description = "Enable encryption for resources"
  type        = bool
  default     = true
}

variable "kms_key_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 30
}

# Backup Configuration
variable "enable_backups" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Backup retention in days"
  type        = number
  default     = 30
}
