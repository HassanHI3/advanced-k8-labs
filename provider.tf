terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket       = "eks-tfstate-bucket-has"
    key          = "eks-lab/terraform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true # native s3 state locking
    encrypt      = true # state file is encrypted at rest in S3 (contains secrets!)
  }
}

provider "aws" {
  region = "eu-west-2"
}

# data "aws_eks_cluster" "cluster" { # this data block pulls the EKS-lab cluster info so terraform & resource blocks can reference it.
#   name = module.eks.cluster_name
# }

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.region]
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", "eu-west-2"]
    }
  }
}


# The command it runs is:
#   aws eks get-token --cluster-name eks-lab
# which returns a temporary bearer token (valid ~15 mins)
# tied to your local AWS credentials (IAM user/role).