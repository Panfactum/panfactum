################################################
# Imports
################################################
load('ext://uibutton', 'cmd_button')
load('packages/tilt/common.tiltfile', 'REGISTRY', 'NAMESPACE', 'TF_ROOT_DIR')

################################################
# INIT
################################################
allow_k8s_contexts('development-primary')
if k8s_context() != 'development-primary':
  fail("You can only use the 'development-primary' context when using Tilt. Switch by running 'kubectx development-primary'")

default_registry (REGISTRY)
update_settings ( max_parallel_updates = 3 , k8s_upsert_timeout_secs = 900 , suppress_unused_image_warnings = None )

include('./packages/primary-api/Tiltfile')
include('./packages/public-app/Tiltfile')

################################################
# Global resources
################################################
local_resource(
  "pgadmin4",
  "",
  serve_cmd="pgadmin4",
  auto_init = True,
  allow_parallel = True,
  readiness_probe = probe(
   http_get = http_get_action(5050, path = "/misc/ping")
  ),
  labels=['local'],
  links=["http://localhost:5050"]
)

local_resource(
  "pnpm",
  "pnpm install",
  auto_init = True,
  allow_parallel = True,
  deps = [
    ".npmrc",
    "pnpm-lock.yaml",
    "pnpm-workspace.yaml",
    "packages/build/package.json",
    "packages/build/pnpm-lock.yaml",
    "packages/eslint/package.json",
    "packages/eslint/pnpm-lock.yaml",
    "packages/internal-docs/package.json",
    "packages/internal-docs/pnpm-lock.yaml",
    "packages/primary-api/package.json",
    "packages/primary-api/pnpm-lock.yaml",
    "packages/public-app/package.json",
    "packages/public-app/pnpm-lock.yaml",
    "pnpm-workspace.yaml",
    "package"
  ],
  labels=['local'],
  links=["http://localhost:5050"]
)

