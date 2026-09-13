# Stack de aplicaciones sobre la Core Landing Zone free tier.
# Autenticación vía perfil [FREE-TIER] de ~/.oci/config.

terraform {
  required_version = ">= 1.12.0" # el backend nativo "oci" existe desde 1.12
  required_providers {
    oci = {
      source = "oracle/oci"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

provider "oci" {
  config_file_profile = "FREE-TIER"
}
