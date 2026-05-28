
variable "project_name" {
  description = "name of the project"
  type        = string
  default     = "microservices-platform"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}


variable "budget_limit" {
  description = "monthly budget limit in USD"
  type        = number
  default     = 20

}


variable "budget_email" {
  description = "email to receive budget alerts"
  type        = list(string)
  default     = ["sameer.khan.ug22@nsut.ac.in"]
  
}





variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block e.g. 10.0.0.0/16."
  }
}

variable "azs" {
  description = "azs"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets, one per availability zone"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets, one per availability zone"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "enable_nat_gateway" {
  description = "NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "single NAT Gateway shared across all availability zones"
  type        = bool
  default     = true
}

variable "one_nat_gateway_per_az" {
  description = "one NAT Gateway per az"
  type        = bool
  default     = false
}

variable "enable_dns_hostnames" {
  description = "enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "microservices-eks-cluster"
}


variable "cluster_version" {
    description = "EKS cluster version"
    type        = string
    default     = "1.30"
  
}

variable "cluster_endpoint_public_access" {
    description = "Enable public access to the EKS cluster endpoint"
    type        = bool
    default     = true
  
}


variable "node_group_name" {
    description = "EKS node group name"
    type        = string
    default     = "microservices-node-group"
  
}

variable "node_instance_types" {
    description = "EC2 instance types for the EKS node group"
    type        = list(string)
    default     = ["t3.small"]
  
}

variable "node_desired_size" {
    description = "Desired number of nodes in the EKS node group"
    type        = number
    default     = 3
  
}


variable "node_min_size" {
    description = "Minimum number of nodes in the EKS node group"
    type        = number
    default     = 2
  
}

variable "node_max_size" {
    description = "Maximum number of nodes in the EKS node group"
    type        = number
    default     = 5
  
}

variable "node_disk_size" {
    description = "Disk size (in GB) for each node in the EKS node group"
    type        = number
    default     = 40
  
}

variable "cluster_addons" {
    description = "EKS cluster addons to enable"
    type        = list(string)
    default     = ["vpc-cni", "coredns", "kube-proxy"]
  
}



variable "microservices" {
  description = "List of microservices"
  type        = list(string)
  default = [
    "adservice",
    "cartservice",
    "checkoutservice",
    "currencyservice",
    "emailservice",
    "frontend",
    "loadgenerator",
    "paymentservice",
    "productcatalogservice",
    "recommendationservice",
    "shippingservice",
  ]
}




variable "github_account" {
  description = "GitHub account name for the project"
  type        = string
  default     = "Sameer-tec"  
}


variable "github_repo" {
  description = "GitHub repository name for the project"
  type        = string
  default     = "microservices-platform"  
}


variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  default     = "GrafanaAdmin123!"
  
}