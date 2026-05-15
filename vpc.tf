module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.name
  cidr = "10.0.0.0/16"

  azs             = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"] # in production, you would want to use more than 3 subnets and spread them across more availability zones for high availability and fault tolerance.

  enable_nat_gateway   = true # Lets private subnets reach the internet (e.g. pulling container images)
  single_nat_gateway   = true # ONE NAT gateway shared by all AZs — cheap for labs, but a single point of failure.
  # In prod, set this to false so each AZ gets its own NAT (more $$, but HA).

  enable_dns_hostnames = true  # this is required so EC2 instances/EKS nodes get DNS names
  enable_dns_support   = true  # Required for VPC-internal DNS resolution (and for EKS to work properly)

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared" # Marks this subnet as usable by the named EKS cluster
    "kubernetes.io/role/elb"              = "1" # "1" = put internal (private) load balancers here
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/internal-elb"     = "1"
  }

  tags = local.tags
}