terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0" # Helm provider v3 changed syntax based on version i'm using.
    }
  }
  backend "s3" {
    bucket       = "eks-tfstate-bucket-has"    # created this s3 bucket manually before running terraform init
    key          = "eks-lab/terraform.tfstate" # path within the bucket where the state file will be stored
    region       = "eu-west-2"
    use_lockfile = true # native s3 state locking , prevents 2 terraform apply's running at the same time and corrupting the state file.
    encrypt      = true # state file is encrypted at rest in S3 (contains secrets!)
  }
}

provider "aws" {
  region = "eu-west-2"
}

# data "aws_eks_cluster" "cluster" { # this data block pulls the EKS-lab cluster info so terraform & resource blocks can reference it.
#   name = module.eks.cluster_name
# }

provider "kubernetes" {                                                                # provider lets terraform connect to EKS cluster and manage K8s resources.
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data) # lets terraform verify it is connecting to the real EKS cluster and EKS.tf module gives value as base64, so we decode it first.
  host                   = module.eks.cluster_endpoint                                 # The Kubernetes API server endpoint - This tells Terraform WHERE the EKS cluster is.

  exec { # Exec = Terraform will run a command - gets temporary login token for the EKS cluster.
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", "eu-west-2"]
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint                                 # The Kubernetes API server endpoint - This tells Terraform WHERE the EKS cluster is.
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data) # lets terraform verify it is connecting to the real EKS cluster and EKS.tf module gives value as base64, so we decode it first.

    exec = { # Exec = Terraform will run a command - gets temporary login token for the EKS cluster.
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", "eu-west-2"]
    }
  }
}

# aws eks get-token --cluster-name eks-lab
# AWS CLI command returns a temporary bearer token (valid ~15 mins) for the EKS cluster & Terraform uses this token to authenticate with Kubernetes.

# tied to your local AWS credentials (IAM user/role).