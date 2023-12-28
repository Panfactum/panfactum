locals {
  # Read in the configuration yaml for this particular module
  module_config    = yamldecode(file("${get_terragrunt_dir()}/module.yaml"))
  providers        = local.module_config.providers
  module_source    = local.module_config.source
  module_overrides = lookup(local.module_config, "overrides", {})

  # Read in DRY configuration yamls for this module
  # Note that file this is defined in the top-level `terragrunt.hcl`
  # it is executed inside of each module directory, and thus "parent" folders
  # are relative to each module's `terragrunt.hcl`
  global_vars = merge(
    yamldecode(file(find_in_parent_folders("global.yaml"))),
    local.module_overrides
  )
  environment_vars = merge(
    yamldecode(file(find_in_parent_folders("environment.yaml"))),
    local.module_overrides
  )
  region_vars = merge(
    yamldecode(file(find_in_parent_folders("region.yaml"))),
    local.module_overrides
  )

  # Determine the module "version" (git ref to checkout)
  # Use the following priority ordering:
  # 1. The `version` key in `module.yaml`
  # 2. The `version` key in a `version.yaml` file in one of the parent folders
  # 3. Fallback to the repo's primary branch
  primary_branch = local.global_vars.repo_primary_branch
  version_file   = find_in_parent_folders("version.yaml", "")
  version        = lookup(local.module_config, "version", local.version_file == "" ? local.primary_branch : yamldecode(file(local.version_file)).version)

  # The version_tag needs to be a commit sha
  version_hash = run_cmd("--terragrunt-quiet", "get-version-hash", local.version)

  # Defining the module source
  # NOTE: You can only use modules defined inside this repo (to use other repo's modules), define a
  # `module` block in your terraform code
  # Always use the local copy if trying to deploy to mainline branches to resolve performance and caching issues
  use_local_terraform  = contains(["latest", "local", local.primary_branch], local.version)
  terraform_path       = "/packages/infrastructure//${local.module_source}"
  module_source_string = local.use_local_terraform ? "${get_repo_root()}${local.terraform_path}" : "${local.global_vars.repo_url}${local.terraform_path}?ref=${local.version}"

  # Folder of shared snippets to generate
  shared_folder = "${get_repo_root()}/environments/shared"

  # providers
  enable_azuread       = lookup(local.providers, "azuread", false)
  enable_aws           = lookup(local.providers, "aws", false)
  enable_aws_secondary = lookup(local.providers, "aws_secondary", false)
  enable_kubernetes    = lookup(local.providers, "kubernetes", false)
  enable_helm          = lookup(local.providers, "helm", false)
  enable_github        = lookup(local.providers, "github", false)
  enable_time          = lookup(local.providers, "time", false)
  enable_random        = lookup(local.providers, "random", false)
  enable_local         = lookup(local.providers, "local", false)
  enable_tls           = lookup(local.providers, "tls", false)
  enable_vault         = lookup(local.providers, "vault", false)

  # local dev namespace
  local_dev_namespace = get_env("LOCAL_DEV_NAMESPACE", "")
  is_local            = local.environment_vars.environment == "local"

  # get vault_token
  vault_address = local.is_ci ? get_env("VAULT_ADDR") : lookup(local.region_vars, "vault_address", get_env("VAULT_ADDR"))
  vault_token   = local.enable_vault ? get_env("VAULT_TOKEN", run_cmd("--terragrunt-quiet", "get-vault-token", local.vault_address)) : ""

  # get aad service principle owners
  aad_sp_object_owners = lookup(local.environment_vars, "aad_sp_object_owners", [])

  # check if in ci system
  is_ci = get_env("CI", "false") == "true"
}

################################################################
### The main terraform source
################################################################

terraform {
  source = local.module_source_string

  # Force Terraform to keep trying to acquire a lock for
  # up to 30 minutes if someone else already has the lock
  # and disable locking entirely if running against a local environment
  # module
  extra_arguments "lock" {
    commands = get_terraform_commands_that_need_locking()
    arguments = [
      local.is_local ? "-lock=false" : "-lock-timeout=30m"
    ]
  }
}

################################################################
### Shared Global Snippets
################################################################

generate "common_vars" {
  path      = "common_vars.tf"
  if_exists = "overwrite_terragrunt"
  contents  = file("${local.shared_folder}/common_vars.tf")
}

################################################################
### Provider Configurations
################################################################

generate "azuread_provider" {
  path      = "azuread.tf"
  if_exists = "overwrite_terragrunt"
  contents  = local.enable_azuread ? file("${local.shared_folder}/azuread.tf") : ""
}

generate "aws_provider" {
  path      = "aws.tf"
  if_exists = "overwrite_terragrunt"
  contents  = local.enable_aws ? file("${local.shared_folder}/aws.tf") : ""
}

generate "aws_secondary_provider" {
  path      = "aws_secondary.tf"
  if_exists = "overwrite_terragrunt"
  contents  = local.enable_aws_secondary ? file("${local.shared_folder}/aws_secondary.tf") : ""
}

generate "kubernetes_provider" {
  path      = "kubernetes.tf"
  if_exists = "overwrite_terragrunt"
  contents  = local.enable_kubernetes || local.enable_helm ? file("${local.shared_folder}/kubernetes.tf") : ""
}

generate "helm_provider" {
  path      = "helm.tf"
  if_exists = "overwrite_terragrunt"
  contents  = local.enable_helm ? file("${local.shared_folder}/helm.tf") : ""
}

generate "github_provider" {
  path      = "github.tf"
  if_exists = "overwrite_terragrunt"
  contents  = local.enable_github ? file("${local.shared_folder}/github.tf") : ""
}

generate "time_provider" {
  path      = "time.tf"
  if_exists = "overwrite_terragrunt"
  contents  = local.enable_time ? file("${local.shared_folder}/time.tf") : ""
}

generate "random_provider" {
  path      = "random.tf"
  if_exists = "overwrite_terragrunt"
  contents  = local.enable_random ? file("${local.shared_folder}/random.tf") : ""
}

generate "local_provider" {
  path      = "local.tf"
  if_exists = "overwrite_terragrunt"
  contents  = local.enable_local ? file("${local.shared_folder}/local.tf") : ""
}

generate "tls_provider" {
  path      = "tls.tf"
  if_exists = "overwrite_terragrunt"
  contents  = local.enable_tls ? file("${local.shared_folder}/tls.tf") : ""
}

generate "vault_provider" {
  path      = "vault.tf"
  if_exists = "overwrite_terragrunt"
  contents  = local.enable_vault ? file("${local.shared_folder}/vault.tf") : ""
}
################################################################
### Remote State Configuration
################################################################

remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    profile        = local.environment_vars.tf_state_profile
    bucket         = local.environment_vars.tf_state_bucket
    key            = "${local.global_vars.repo_name}/${local.is_local ? "${local.local_dev_namespace}/" : ""}${path_relative_to_include()}/terraform.tfstate"
    region         = local.environment_vars.tf_state_region
    encrypt        = true
    dynamodb_table = local.environment_vars.tf_state_lock_table
  }
}

################################################################
### Terragrunt Configuration
################################################################

terraform_version_constraint  = "~> 1.1"
terragrunt_version_constraint = "~> 0.36"

// If running in the CI system, enable retries on all of the errors
retryable_errors         = local.is_ci ? [".*"] : []
retry_max_attempts       = 3
retry_sleep_interval_sec = 30

################################################################
### Default Module Inputs
################################################################

inputs = {

  // ensure our ECR repositories are synchronized across accounts
  ecr_repository_names = local.global_vars.ecr_repository_names

  // used for sourcing build artifacts
  version_hash = local.version_hash

  // common vars
  is_local    = local.is_local
  app         = local.global_vars.repo_name
  module      = basename(get_original_terragrunt_dir())
  environment = local.environment_vars.environment
  version_tag = local.version
  region      = local.region_vars.region

  // azuread provider
  azuread_tenant_id    = "2a66606b-17a5-47dd-94af-84f5d648ea7b"
  aad_sp_object_owners = local.aad_sp_object_owners

  // aws provider
  aws_region               = local.region_vars.aws_region
  aws_account_id           = local.environment_vars.aws_account_id
  aws_profile              = local.environment_vars.aws_profile
  aws_secondary_region     = local.region_vars.aws_secondary_region
  aws_secondary_account_id = local.environment_vars.aws_secondary_account_id
  aws_secondary_profile    = local.environment_vars.aws_secondary_profile

  // kubernetes provider
  kube_api_server     = lookup(local.region_vars, "kube_api_server", "")
  kube_config_context = lookup(local.region_vars, "kube_config_context", "")
  kube_labels = {
    app         = local.global_vars.repo_name
    module      = basename(get_original_terragrunt_dir())
    environment = local.environment_vars.environment
    version_tag = local.version
    region      = local.region_vars.region
  }

  // vault provider
  vault_address = local.vault_address
  vault_token   = local.vault_token
}
