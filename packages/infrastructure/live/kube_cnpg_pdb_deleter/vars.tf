variable "namespace" {
  description = "The namespace to deploy kubernetes resources into"
  type        = string
  default     = "cnpg-deleter"
}

variable "schedule" {
  description = "The schedule to run this on"
  type        = string
  default     = ""
}

variable "image_repo" {
  description = "The image to use for the deployment"
  type        = string
  default     = "487780594448.dkr.ecr.us-east-2.amazonaws.com/ci"
}

variable "image_version" {
  description = "The version of the image to use for the deployment"
  type        = string
}

