# Installs the ingress-nginx Helm chart.
# This creates the Ingress Controller that receives external traffic
# and routes it to the correct Kubernetes Services.

resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.11.3"

  namespace        = "ingress-nginx" # Installs ingress-nginx into its own namespace.
  create_namespace = true

  timeout = 600 # Gives Helm more time to install all resources.
}

resource "helm_release" "cert_manager" { # Installs cert-manager using Helm = cert-manager automatically creates and renews SSL/TLS certificates.
  name       = "cert-manager"
  repository = "oci://quay.io/jetstack/charts"
  chart      = "cert-manager"
  version    = "v1.20.2"

  create_namespace = true
  namespace        = "cert-manager" # Must match the namespace used in the cert-manager IRSA role. The IAM role is linked to the service account: "cert-manager:cert-manager" (namespace:serviceaccount) and if the Helm release creates the service account in a different namespace, the IAM role won't work.
  # Links the cert-manager K8s service account to the AWS IAM role via OIDC

  set = [ #This allows cert-manager to assume the AWS IAM role using IRSA/OIDC = it adds the IAM role ARN as an annotation on the cert-manager service account.
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.cert-manager-irsa.arn
    },
    {
      name  = "crds.enabled" # Installs cert-manager CRDs = CRDs allow Kubernetes to understand custom resources like : Certificate, Issuer, ClusterIssuer, etc.
      value = "true"
    }
  ]

  # Loads extra cert-manager Helm configuration from this YAML file.
  # reads file at plan/apply time and injects it into the helm release.
  values = [
    file("helm-values/cert_manager.yaml")
  ]
}

resource "helm_release" "external_dns" { # Installs external-dns using Helm
  # external-dns automatically creates/updates DNS records in Route53 - added 3 more records since **
  # based on Kubernetes Ingress or Service resources.
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  version    = "1.15.0"

  create_namespace = true
  namespace        = "external-dns"

  set = [ #This allows cert-manager to assume the AWS IAM role using IRSA/OIDC = it adds the IAM role ARN as an annotation on the cert-manager service account.
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.external_dns_irsa.arn
    },
    {
      name  = "crds.enabled" # Installs cert-manager CRDs = CRDs allow Kubernetes to understand custom resources like : Certificate, Issuer, ClusterIssuer, etc.
      value = "true"
    }
  ]

  values = [ # Loads external-dns Helm values from this YAML file.
    # reads file at plan/apply time and injects it into the helm release.
    file("helm-values/external_dns.yaml")
  ]
}

resource "helm_release" "argocd" { # Installs Argo CD using Helm.
  # Argo CD watches your Git repository and syncs Kubernetes manifests
  # into the EKS cluster.
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.24.0"
  timeout    = 600

  create_namespace = true
  namespace        = "argocd"

  values = [ # loads Argo CD Helm values from this YAML file and injects it into the helm release on plan/apply time.
    file("helm-values/argocd.yaml")
  ]

}

