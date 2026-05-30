# Microservices Platform on AWS EKS

[![Terraform](https://img.shields.io/badge/Infrastructure_as_Code-Terraform-7B42BC?logo=terraform)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/Orchestration-Kubernetes-326CE5?logo=kubernetes)](https://kubernetes.io/)
[![AWS](https://img.shields.io/badge/Cloud-AWS-232F3E?logo=amazon-aws)](https://aws.amazon.com/)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub_Actions-2088FF?logo=githubactions)](https://github.com/features/actions)

An enterprise-grade, highly available deployment of an 11-service polyglot microservices application running on a fully managed Amazon Elastic Kubernetes Service (EKS) cluster. This project leverages Infrastructure as Code (IaC) for deterministic environment provisioning, a keyless OpenID Connect (OIDC) identity boundary for pipeline security, and a cloud-native Prometheus/Grafana observability engine for millisecond-level telemetry tracking.

## 🏗️ Architectural Overview

The infrastructure layout isolates computing boundaries from edge-ingress paths, ensuring a zero-trust network profile inside the AWS public cloud ecosystem.

* **Networking (VPC Tier):** Deployed across 3 Availability Zones (AZs) containing 3 public subnets for public internet-facing application load balancers and a single NAT Gateway, alongside 3 highly isolated private subnets hosting the EKS managed node group instances.
* **Compute Layer (EKS):** A managed Kubernetes cluster orchestrating a 4-node Amazon Linux 2 (RHEL-based) EC2 compute pool executing worker workloads.
* **Storage Registry:** 11 decoupled Amazon Elastic Container Registry (ECR) repositories configured with immutable image tags and automated security vulnerabilities scanning on push policies.

## 🛠️ Tech Stack & Core Tools

* **Cloud Platform:** Amazon Web Services (VPC, EKS, ECR, IAM, Route53, SNS)
* **Infrastructure Provisioning:** Terraform (v1.5+) utilizing official community verified upstream modules
* **Orchestration & Packages:** Kubernetes Core API, Helm v3 Engine
* **CI/CD Platform:** GitHub Actions Engine utilizing OpenID Connect (OIDC) trust brokers
* **Telemetry Matrix:** Prometheus Operator Stack, Grafana Dashboard Engine, Alertmanager Alerting Rules

## 🔐 CI/CD & Pipeline Security Integration

The deployment workflow eliminates the dangerous dependency of storing static, long-lived AWS IAM User Access Keys (`AWS_ACCESS_KEY_ID`) inside GitHub repository secrets. 

Instead, an **OpenID Connect (OIDC) Federated Trust** handshake is established between GitHub Actions runner nodes and AWS Security Token Service (STS). GitHub tokens pass an encrypted validation assertion containing a `StringLike` evaluation rule scoped directly to the repository's main operational branch (`token.actions.githubusercontent.com:sub` $\rightarrow$ `repo:Sameer-tec/*`).

Upon authorization, short-lived IAM session profile permissions are assumed on-the-fly. The pipeline subsequently executes parallelized multi-stage container compilation tracks, pushing built artifacts simultaneously to their respective ECR targets and finishing continuous rolling update rollouts for all 11 microservices in **under 5 minutes total**.

## 📊 Observability, Telemetry & Incident Alerts

```text
[ Pod Metric Ingestion ] ──> [ Prometheus Server ] ──> [ Grafana Engine ] ──> 4 Custom Dashboards
                                       │
                                       └──> [ Alertmanager Engine ] ──> [ Amazon SNS ] ──> Alerting Channels