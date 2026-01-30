#main.tf

data "aws_eks_cluster" "this" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

resource "kubernetes_manifest" "payment" {
  depends_on = [
    helm_release.alb_controller,
    module.eks
  ]

  for_each = fileset("${path.module}/k8s", "*.yaml")
  manifest = yamldecode(file("${path.module}/k8s/${each.value}"))
}

# resource "kubernetes_manifest" "payment" {
#   depends_on = [
#     module.eks
#   ]

#   for_each = fileset("${path.module}/k8s", "*.yaml")

#   manifest = yamldecode(
#     file("${path.module}/k8s/${each.value}")
#   )
# }
