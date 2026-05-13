resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.11.3"

  namespace        = "ingress-nginx"
  create_namespace = true

  timeout = 600
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "oci://quay.io/jetstack/charts"
  chart      = "cert-manager"
  version    = "v1.20.2"

  create_namespace = true
  namespace        = "cert-manager" # has to match the namespace in IRSA.tf for cert-manager, as the IAM role is linked to a service account in this namespace.

  # Links the cert-manager K8s service account to the AWS IAM role via OIDC

  set = [
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.cert-manager-irsa.arn
    },
    {
      name  = "crds.enabled"
      value = "true"
    }
  ]

  # this links configs from helm values to this resource block
  # reads file at plan/apply time and injects it into the helm release.
  values = [
    file("helm-values/cert_manager.yaml")
  ]
}

resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  version    = "1.15.0"

  create_namespace = true
  namespace        = "external-dns"

  values = [
    file("helm-values/external_dns.yaml")
  ]
}







# Installs cert-manager CRDs (Certificate, ClusterIssuer, Issuer etc) so we don't have to kubectl apply before installing the chart.
# without this the cert-manager chart would fail as k8 wouldn't recognise it's resource types.

#   set = [{
#     name  = "crds.enabled"
#     value = "true"
#   }]

# this links configs from helm values to this resource block
# reads file at plan/apply time and injects it into the helm release.






























# resource "helm_release" "nginx_ingress" {
#   name       = "nginx-ingress-controller"
#   repository = "https://charts.bitnami.com/bitnami"
#   chart      = "nginx-ingress-controller"
#   version    = "9.3.12"

#   #   set {
#   #     name  = "service.type"
#   #     value = "ClusterIP"
#   #   }

#   # set's the service to ClusterIP by default in K8

#   create_namespace = true
#   namespace        = "ingress-nginx"
# }

# resource "helm_release" "cert_manager" {
#   name       = "cert-manager"
#   repository = "https://charts.jetstack.io"
#   chart      = "cert-manager"

#   create_namespace = true
#   namespace        = "cert-manager"
#   version          = "v1.15.0"

#   set {
#     name  = "installCRDs"
#     value = "true"
#   }

#   set {
#     name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#     value = module.cert-manager-irsa.arn
#   }

#   values = [
#     file("helm-values/cert_manager.yaml")
#   ]
# }

# resource "helm_release" "external_dns" {
#   name       = "external-dns"
#   repository = "https://charts.bitnami.com/bitnami"
#   chart      = "external-dns"
#   version    = "5.3.0"

#   create_namespace = true
#   namespace        = "external-dns" #still using this namespace because our IAM role wont work anywhere else

#   values = [
#     "${file("helm-values/external_dns.yaml")}"
#   ]
# }






#   set = [
#     {
#       name  = "wait-for"
#       value = module.cert-manager-irsa.iam_role_arn
#     },
#     {
#       name  = "installCRDs"
#       value = "true"
#     }
#   ]