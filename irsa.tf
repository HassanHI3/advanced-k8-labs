# cert manager IRSA for service accounts - creates IAM role that the cert-manager Kubernetes service account can assume.
# hosted zone created manually in Route53.

module "cert-manager-irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"

  name                          = "cert-manager"                                         # name of the IAM role to create
  attach_cert_manager_policy    = true                                                   # Attaches the AWS permissions cert-manager needs.
  cert_manager_hosted_zone_arns = ["arn:aws:route53:::hostedzone/Z07570801AKJJJYP6TDJ1"] # Limits cert-manager permissions to this specific Route53 hosted zone only.
  # (hosted zone ID is from Route53 console) and created manually before running terraform apply.

  oidc_providers = { # Connects the IAM role to the EKS OIDC provider = allows Kubernetes service accounts to assume AWS IAM roles.
    one = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["cert-manager:cert-manager"]
    }
  }

  tags = local.tags
}

# External DNS IRSA for service accounts
# Creates an IAM role that the external-dns Kubernetes service account can assume.

module "external_dns_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"

  name                          = "external-dns" # Name of the IAM role created for external-dns.
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = ["arn:aws:route53:::hostedzone/Z07570801AKJJJYP6TDJ1"]

  oidc_providers = {
    one = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-dns:external-dns"]
    }
  }

  tags = local.tags
}
