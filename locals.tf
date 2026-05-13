locals {
  name        = "eks-lab"
  domain_name = "lab.hassanhome.com"
  region      = "eu-west-2"
  vpc_name    = "my-vpc"
  environment = "sandbox"

  tags = {
    project     = "EKS Advanced Lab"
    Environment = "sandbox"
  }

}