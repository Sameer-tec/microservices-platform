
output "ecr_repository_urls" {
  description = "ecr repository URLs"
  value = {
    for name, repo in aws_ecr_repository.microservices :
    name => repo.repository_url
  }
}

output "kubeconfig_command" {
  description = "to configure kubectl after apply"
  value       = "aws eks update-kubeconfig --name ${var.eks_cluster_name} --region ${var.region}"
}


output "github_actions_role_arn" {
  description = "Paste this into GitHub Secrets as AWS_ROLE_ARN"
  value       = aws_iam_role.github_actions.arn
}