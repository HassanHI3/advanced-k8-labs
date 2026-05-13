module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = local.name
  kubernetes_version = "1.33"

  endpoint_public_access       = true
  endpoint_public_access_cidrs = ["0.0.0.0/0"] # in production, you would want to restrict this to your own IP address or range for better security.

  enable_irsa = true
  # allows k8 pods to assume IAM roles and access AWS services without needing aws credentials.

  enable_cluster_creator_admin_permissions = true
  create_cloudwatch_log_group              = false
  enabled_log_types                        = ["api", "audit", "authenticator"]

  # EKS Provisioned Control Plane configuration
  control_plane_scaling_config = {
    tier = "standard"
  }

  addons = {
    coredns                = { most_recent = true }
    kube-proxy             = { most_recent = true }
    vpc-cni                = { most_recent = true, before_compute = true }
    eks-pod-identity-agent = { most_recent = true, before_compute = true }
  }


  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      disk_size      = 20
      instance_types = ["t3.large"]

      desired_size = 2
      max_size     = 2
      min_size     = 2

      capacity_type = "ON_DEMAND"
    }
  }

  tags = local.tags
}
