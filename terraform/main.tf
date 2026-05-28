
resource "aws_budgets_budget" "monthly" {
  name         = "${var.project_name}-monthly-budget"
  budget_type  = "COST"
  limit_amount = var.budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_email
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.budget_email
  }
}



module "vpc" {
    source = "terraform-aws-modules/vpc/aws"
    version = "~> 5.0"
    name = "${var.project_name}-vpc"
    cidr = var.vpc_cidr
    azs = var.azs
    public_subnets = var.public_subnet_cidrs
    private_subnets = var.private_subnet_cidrs
    enable_nat_gateway = var.enable_nat_gateway
    single_nat_gateway = var.single_nat_gateway
    one_nat_gateway_per_az = var.one_nat_gateway_per_az
    enable_dns_hostnames = var.enable_dns_hostnames
    enable_dns_support = var.enable_dns_support
     map_public_ip_on_launch = true
    public_subnet_tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/elb"                        = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"               = "1"
  }

  tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }
}




module "eks" {
    source = "terraform-aws-modules/eks/aws"
    version = "~> 20.0"
    cluster_name = var.eks_cluster_name
    cluster_version = var.cluster_version
    subnet_ids = module.vpc.private_subnets
    vpc_id = module.vpc.vpc_id
    cluster_endpoint_public_access = var.cluster_endpoint_public_access
    eks_managed_node_groups = {
        main = {
            desired_size = var.node_desired_size
            max_size     = var.node_max_size
            min_size     = var.node_min_size
            instance_types = var.node_instance_types
            disk_size = var.node_disk_size            
        }
    }
    cluster_addons = {
  coredns    = { most_recent = true }
  kube-proxy = { most_recent = true }
  vpc-cni    = { most_recent = true 
       before_compute = true
       }
  

}

 bootstrap_self_managed_addons = false

enable_cluster_creator_admin_permissions = true
 
}






resource "aws_ecr_repository" "microservices" {
  for_each = toset(var.microservices)
  

  name                 = "${var.project_name}/${each.key}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Lifecycle policy
resource "aws_ecr_lifecycle_policy" "microservices" {
  for_each   = aws_ecr_repository.microservices
  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}














resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # GitHub's stable thumbprint
}

# 2. Create the IAM Role for GitHub Actions (with jsonencode Trust Policy)
resource "aws_iam_role" "github_actions" {
  name        = "${var.project_name}-github-actions-role"
  description = "IAM role assumed by GitHub Actions for CI/CD deployments"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_account}/${var.github_repo}:*"
          }
        }
      }
    ]
  })
}

# 3. Create the IAM Permissions Policy (with jsonencode AWS permissions)
resource "aws_iam_policy" "github_actions" {
  name        = "${var.project_name}-github-actions-policy"
  description = "Permissions for GitHub Actions to push images to ECR and read EKS cluster details"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:BatchDeleteImage"
        ]
        Resource = [for repo in aws_ecr_repository.microservices : repo.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["eks:DescribeCluster"]
        Resource = [module.eks.cluster_arn]
      }
    ]
  })
}

# 4. Attach the Permissions Policy to the IAM Role
resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}

# 5. Register the GitHub IAM Role as an authorized EKS Access Entry
resource "aws_eks_access_entry" "github_actions" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_iam_role.github_actions.arn
  type          = "STANDARD"
}

# 6. Grant Cluster Admin permissions inside Kubernetes to the Access Entry
resource "aws_eks_access_policy_association" "github_actions" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_iam_role.github_actions.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}







resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack" 
  namespace  = "monitoring"
  
  
  
  
  set_sensitive =[ {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }
  ]
}