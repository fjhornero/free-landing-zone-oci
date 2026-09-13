# -----------------------------------------------------------------------------
# Backend remoto del state en OCI Object Storage (backend nativo "oci").
#
# Autenticacion por API key, reutilizando el perfil [FREE-TIER] de ~/.oci/config
# (mismo usuario/tenancy/clave que el provider en terraform.tfvars). No hace
# falta Customer Secret Key: eso solo aplica al backend "s3" compatible.
#
# El bloqueo de state es automatico: el backend crea un objeto de lock en el
# mismo bucket usando If-None-Match, asi que dos "apply" simultaneos no pueden
# pisarse.
# -----------------------------------------------------------------------------

terraform {
  backend "oci" {
    bucket              = "oci-tfstate"
    namespace           = "axwqnihb5ohp"
    key                 = "free-landing-zone/terraform.tfstate"
    region              = "eu-madrid-1"
    auth                = "APIKey"
    config_file_profile = "FREE-TIER"
  }
}
