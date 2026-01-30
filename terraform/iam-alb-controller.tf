# iam-alb-controller.tf
# ⚠️ This file MUST be processed AFTER eks.tf
# Terraform processes files alphabetically, so rename to z-iam-alb-controller.tf
# OR keep as-is but ensure eks.tf exists first

data "aws_iam_openid_connect_provider" "eks" {
  url = module.eks.oidc_provider_url
}

locals {
  oidc_sub_key = "${replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
}

resource "aws_iam_role" "alb_controller" {
  name = "eks-alb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_sub_key}" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLoadBalancerControllerIAMPolicy"
}