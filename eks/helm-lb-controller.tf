
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.4.1"
  namespace  = "kube-system"

  set = [
    {
      name  = "clusterName"
      value = "${local.env}-${var.cluster-name}"
    },
    {
      name  = "serviceAccount.create"
      value = "false"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    {
      name  = "region"
      value = var.aws-region
    },
    {
      name  = "vpcId"
      value = data.aws_vpc.vpc.id
    }
  ]
  depends_on = [kubernetes_service_account.lb-controller-sa]
}
