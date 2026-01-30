#eks.tf
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.15.1"

  cluster_name    = "payment-eks"
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = true  # ✅ CRITICAL for OIDC provider

  eks_managed_node_groups = {
    payment_nodes = {
      instance_types = ["t3.micro"]
      desired_size   = 2
      min_size       = 1
      max_size       = 4
      subnet_ids     = module.vpc.private_subnets
    }
  }
}