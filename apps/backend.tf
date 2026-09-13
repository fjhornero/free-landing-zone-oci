# -----------------------------------------------------------------------------
# Backend remoto del state en OCI Object Storage (backend nativo "oci").
#
# Mismo bucket que la landing zone pero con otra "key", asi que cada stack
# tiene su state independiente:
#   free-landing-zone/terraform.tfstate  -> stack raiz (landing zone)
#   apps/terraform.tfstate               -> este stack
#
# Autentica por API key con el perfil [FREE-TIER] de ~/.oci/config, el mismo
# que usa el provider. El bloqueo de state es automatico (objeto de lock en
# el propio bucket via If-None-Match).
# -----------------------------------------------------------------------------

terraform {
  backend "oci" {
    bucket              = "oci-tfstate"
    namespace           = "axwqnihb5ohp"
    key                 = "apps/terraform.tfstate"
    region              = "eu-madrid-1"
    auth                = "APIKey"
    config_file_profile = "FREE-TIER"
  }
}
