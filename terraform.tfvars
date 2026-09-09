# -----------------------------------------------------------------------------
# Despliegue Core Landing Zone sobre tenancy OCI Free Tier
# Perfil de credenciales: [FREE-TIER] (~/.oci/config)
# -----------------------------------------------------------------------------

# --- Entorno / autenticación ---
tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaaa4vyvxislrb6is2fizcj2kerqdlj4il2bous7i2yotl3g3jbxmsga"
user_ocid        = "ocid1.user.oc1..aaaaaaaaagblxtbgiubniuhbj75ybpbg6pfdsvxavyi6qh2ekf5aisnu2dka"
fingerprint      = "c7:dc:b3:da:5f:23:04:46:e9:2f:81:01:82:ad:29:9d"
private_key_path = "/Users/fran/.oci/oci_api_key.pem"
region           = "eu-madrid-1"

# --- General ---
service_label   = "freelz"
is_free_tenancy = true # Free tier: no despliega Cloud Guard ni Security Zones (no disponibles)
cis_level       = "1"  # Nivel 1: sin Vault ni claves gestionadas por cliente (evita costes)

# --- Notificaciones (requieren confirmar la suscripción por email) ---
network_admin_email_endpoints  = ["goran.sole@asesormasmovil.es"]
security_admin_email_endpoints = ["goran.sole@asesormasmovil.es"]

# --- Red: una VCN three-tier standalone (recursos de red sin coste) ---
define_net  = true
add_tt_vcn1 = true
# Defaults aplicados: CIDR 10.0.0.0/20, subred web pública + app/db privadas,
# sin DRG ni Hub VCN (hub_deployment_option = "No cross-VCN or on-premises connectivity")
