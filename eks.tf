# Creates the EKS cluster using the official Terraform AWS EKS module.
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = local.name # eks.lab
  kubernetes_version = "1.33"

  endpoint_public_access       = true          # Allows access to the Kubernetes API server from the internet.
  endpoint_public_access_cidrs = ["0.0.0.0/0"] #  # For production, restrict this to my own IP instead of 0.0.0.0/0 for range for better security.

  enable_irsa = true
  # Enables IAM Roles for Service Accounts.
  # This lets Kubernetes pods use AWS IAM roles without hardcoded AWS credentials.

  enable_cluster_creator_admin_permissions = true  # Gives the Terraform/AWS identity that creates the cluster admin access.
  create_cloudwatch_log_group              = false # Useful if you want to manage the log group separately.
  enabled_log_types                        = ["api", "audit", "authenticator"]

  # EKS Provisioned - Control Plane configuration
  # 'standard' is normal/default for a production grade setup.
  control_plane_scaling_config = {
    tier = "standard"
  }

  # had issues with addons so had to add them here to get them to install properly, not sure why they weren't installing when I added them in helm.tf as helm releases.
  # Installs core EKS add-ons.
  addons = {
    coredns                = { most_recent = true }
    kube-proxy             = { most_recent = true }                        # Handles Kubernetes service networking rules on nodes.
    vpc-cni                = { most_recent = true, before_compute = true } # AWS VPC networking plugin for pods
    eks-pod-identity-agent = { most_recent = true, before_compute = true } # Lets pods use EKS Pod Identity if needed . Also installed before worker nodes.
  }
  # "before_compute" = true means install it before worker nodes are created.


  vpc_id                   = module.vpc.vpc_id          # Connects the EKS cluster to the VPC.
  subnet_ids               = module.vpc.private_subnets # Places Worker nodes in private subnets.
  control_plane_subnet_ids = module.vpc.private_subnets # #EKS control plane networking also uses private subnets.

  eks_managed_node_groups = { # Creates an EKS managed node group.
    # These are the EC2 worker nodes that run your Kubernetes pods.
    default = {
      disk_size      = 20 # Root disk size for each worker node.
      instance_types = ["t3.large"]

      desired_size = 2
      max_size     = 2
      min_size     = 2

      capacity_type = "ON_DEMAND" # Uses normal paid EC2 instances instead of Spot option here. "ON_DEMAND" =  pay for what you use.
      #"SPOT" = cheaper but can be interrupted by AWS with little notice, not ideal for production. Good for this eks-lab though.
    }
  }

  tags = local.tags
}
