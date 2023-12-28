include "shared" {
  path = find_in_parent_folders()
}

dependency "cluster" {
  config_path = "../aws_eks"
}

dependency "linkerd" {
  config_path = "../kube_linkerd"
}

locals {
  module_config = yamldecode(file("module.yaml"))
}

terraform {
  source = "github.com/Panfactum/infrastructure.git${local.module_config.source}"
}

inputs = {
  eks_cluster_name = dependency.cluster.outputs.cluster_name
  vpa_enabled      = true
}