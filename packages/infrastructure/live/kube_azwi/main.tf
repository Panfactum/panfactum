terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.22"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.10.1"
    }
  }
}

locals {

  name      = "azure-workload-identity-system"
  namespace = module.namespace.namespace

  labels = merge(var.kube_labels, {
    service = local.name
  })
}

module "constants" {
  source = "../../modules/constants"
  matching_labels = {
    app = "workload-identity-webhook"
  }
}

/***************************************
* Namespace
***************************************/

module "namespace" {
  source            = "../../modules/kube_namespace"
  namespace         = local.name
  admin_groups      = ["system:admins"]
  reader_groups     = ["system:readers"]
  bot_reader_groups = ["system:bot-readers"]
  kube_labels       = local.labels
}

/***************************************
* Descheduler
***************************************/

resource "helm_release" "azwi" {
  namespace       = local.namespace
  name            = "workload-identity-webhook"
  repository      = "https://azure.github.io/azure-workload-identity/charts/"
  chart           = "workload-identity-webhook"
  version         = var.azwi_version
  recreate_pods   = true
  cleanup_on_fail = true
  wait            = true
  wait_for_jobs   = true

  values = [
    yamlencode({
      azureTenantID     = var.azuread_tenant_id
      priorityClassName = module.constants.cluster_important_priority_class_name
      replicaCount      = 2
      affinity = merge(
        module.constants.controller_node_affinity_helm,
        module.constants.pod_anti_affinity_helm
      )
    })
  ]
}

resource "kubernetes_manifest" "vpa_azwi" {
  count = var.vpa_enabled ? 1 : 0
  manifest = {
    apiVersion = "autoscaling.k8s.io/v1"
    kind       = "VerticalPodAutoscaler"
    metadata = {
      name      = local.name
      namespace = local.namespace
      labels    = local.labels
    }
    spec = {
      targetRef = {
        apiVersion = "apps/v1"
        kind       = "Deployment"
        name       = "azure-wi-webhook-controller-manager"
      }
    }
  }
}
