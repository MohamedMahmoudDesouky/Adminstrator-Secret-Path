# # terraform/alb-controller.tf
# provider "helm" {
#   kubernetes = {
#     host                   = data.aws_eks_cluster.this.endpoint
#     cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
#     token                  = data.aws_eks_cluster_auth.this.token
#   }
# }

# resource "helm_release" "alb_controller" {
#   name       = "aws-load-balancer-controller"
#   namespace  = "kube-system"
#   repository = "https://aws.github.io/eks-charts"  # ✅ NO TRAILING SPACES
#   chart      = "aws-load-balancer-controller"
#   version    = "1.8.1"

#   set {
#     name  = "clusterName"
#     value = module.eks.cluster_name
#   }

#   set {
#     name  = "region"
#     value = "us-west-2"
#   }

#   set {
#     name  = "vpcId"
#     value = module.vpc.vpc_id
#   }

#   set {
#     name  = "serviceAccount.create"
#     value = "true"
#   }

#   set {
#     name  = "serviceAccount.name"
#     value = "aws-load-balancer-controller"
#   }

#   set {
#     name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#     value = aws_iam_role.alb_controller.arn
#   }

#   depends_on = [
#     module.eks,
#     aws_iam_role.alb_controller
#   ]
# }# iam-alb-controller.tf
# # ⚠️ This file MUST be processed AFTER eks.tf
# # Terraform processes files alphabetically, so rename to z-iam-alb-controller.tf
# # OR keep as-is but ensure eks.tf exists first

# data "aws_iam_openid_connect_provider" "eks" {
#   url = module.eks.oidc_provider_url
# }

# locals {
#   oidc_sub_key = "${replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
# }

# resource "aws_iam_role" "alb_controller" {
#   name = "eks-alb-controller-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = {
#         Federated = data.aws_iam_openid_connect_provider.eks.arn
#       }
#       Action = "sts:AssumeRoleWithWebIdentity"
#       Condition = {
#         StringEquals = {
#           "${local.oidc_sub_key}" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
#         }
#       }
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "alb_controller" {
#   role       = aws_iam_role.alb_controller.name
#   policy_arn = "arn:aws:iam::aws:policy/AWSLoadBalancerControllerIAMPolicy"
# }#main.tf

# data "aws_eks_cluster" "this" {
#   name = module.eks.cluster_name
# }

# data "aws_eks_cluster_auth" "this" {
#   name = module.eks.cluster_name
# }

# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.this.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.this.token
# }

# resource "kubernetes_manifest" "payment" {
#   depends_on = [
#     helm_release.alb_controller,
#     module.eks
#   ]

#   for_each = fileset("${path.module}/k8s", "*.yaml")
#   manifest = yamldecode(file("${path.module}/k8s/${each.value}"))
# }

# # resource "kubernetes_manifest" "payment" {
# #   depends_on = [
# #     module.eks
# #   ]

# #   for_each = fileset("${path.module}/k8s", "*.yaml")

# #   manifest = yamldecode(
# #     file("${path.module}/k8s/${each.value}")
# #   )
# # }
# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "6.28.0"
#     }
#     kubernetes = {
#       source  = "hashicorp/kubernetes"
#       version = "~> 3.0"
#     }
#     helm = {
#       source  = "hashicorp/helm"
#       version = "~> 3.1"
#     }
#     cloudinit = {
#       source  = "hashicorp/cloudinit"
#       version = "~> 2.3"
#     }
#     null = {
#       source  = "hashicorp/null"
#       version = "~> 3.2"
#     }
#   }
#   backend "s3" {
#     bucket = "payment-terraform-state-bucket"
#     key    = "eks/terraform.tfstate"
#     region = "us-west-2"
#   }
# }


# provider "aws" {
#   region = "us-west-2"
# }

# # vpc.tf
# module "vpc" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "5.1.0"

#   name = "payment-vpc"
#   cidr = "10.0.0.0/16"

#   azs             = ["us-west-2a", "us-west-2b"]
#   private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
#   public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

#   public_subnet_tags = {
#     "kubernetes.io/role/elb" = "1"
#   }

#   private_subnet_tags = {
#     "kubernetes.io/role/internal-elb" = "1"
#   }

#   enable_nat_gateway = true
#   single_nat_gateway = true
# }#eks.tf
# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "21.15.1"

#   cluster_name    = "payment-eks"
#   cluster_version = "1.29"

#   vpc_id     = module.vpc.vpc_id
#   subnet_ids = module.vpc.private_subnets

#   enable_irsa = true  # ✅ CRITICAL for OIDC provider

#   eks_managed_node_groups = {
#     payment_nodes = {
#       instance_types = ["t3.micro"]
#       desired_size   = 2
#       min_size       = 1
#       max_size       = 4
#       subnet_ids     = module.vpc.private_subnets
#     }
#   }
# }