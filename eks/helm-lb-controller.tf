# assoon as the alb is setup install gateway api from the folder gatewayapi.

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "3.0.0"
  namespace  = "kube-system"

  set = [
    {
      name  = "clusterName"
      value = module.eks.cluster-name
    },
    {
      name  = "serviceAccount.create"
      value = "true"
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
    },
    {
      name  = "controllerConfig.featureGates.ALBGatewayAPI"
      value = "true"
    },
    {
      name  = "controllerConfig.featureGates.NLBGatewayAPI"
      value = "true"
    }
  ]
  depends_on = [aws_eks_pod_identity_association.lb-controller-association]
}
