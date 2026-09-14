# Password ADMIN del Autonomous DB como secreto en el vault freelz-vault
# (compartimento freelz-security-cmp), con auto-rotación nativa de OCI Vault
# (target system ADB: Vault genera la nueva password y la aplica al ADMIN del ADB).

locals {
  security_cmp_id = data.terraform_remote_state.lz.outputs.compartments["SECURITY-CMP"].id
  top_cmp_id      = data.terraform_remote_state.lz.outputs.compartments["TOP-CMP"].id
  adb_secret_name = "freelz-adb-admin-password"
}

# El vault se creó fuera de este stack: se referencia por nombre, no se gestiona aquí.
data "oci_kms_vaults" "security" {
  compartment_id = local.security_cmp_id
}

locals {
  vault = one([
    for v in data.oci_kms_vaults.security.vaults : v
    if v.display_name == var.vault_display_name && v.state == "ACTIVE"
  ])
}

resource "oci_kms_key" "secrets" {
  compartment_id      = local.security_cmp_id
  display_name        = "freelz-secrets-key"
  management_endpoint = local.vault.management_endpoint
  protection_mode     = "SOFTWARE" # las claves software no consumen la cuota Always Free de 20 versiones HSM

  key_shape {
    algorithm = "AES"
    length    = 32
  }
}

resource "oci_vault_secret" "adb_admin" {
  compartment_id = local.security_cmp_id
  vault_id       = local.vault.id
  key_id         = oci_kms_key.secrets.id
  secret_name    = local.adb_secret_name
  description    = "Password del usuario ADMIN de freelz-adb-1, rotada automáticamente por OCI Vault."

  # Requisito de la rotación con target ADB: sin auto-generación habilitada,
  # RotateSecret falla con "Secret must have auto-generation enabled".
  enable_auto_generation = true

  # Versión inicial: la password actual del ADB (random_password de db.tf),
  # para que el secreto sea válido desde el primer momento.
  secret_content {
    content_type = "BASE64"
    content      = base64encode(random_password.adb_admin.result)
    name         = "terraform-bootstrap"
    stage        = "CURRENT"
  }

  # Plantilla con la que Vault genera la nueva password en cada rotación
  # (cumple la política de passwords de Oracle DB: 12-30 chars, mayús/minús/dígito).
  secret_generation_context {
    generation_type     = "PASSPHRASE"
    generation_template = "DBAAS_DEFAULT_PASSWORD"
    passphrase_length   = 30
  }

  rotation_config {
    is_scheduled_rotation_enabled = true
    rotation_interval             = var.adb_secret_rotation_interval

    target_system_details {
      target_system_type = "ADB"
      adb_id             = oci_database_autonomous_database.free.id
    }
  }

  lifecycle {
    # Cada rotación crea versiones nuevas fuera de Terraform; la versión
    # bootstrap queda obsoleta tras la primera rotación y no debe reaplicarse.
    ignore_changes = [secret_content]
  }
}

# La rotación se ejecuta como el resource principal 'vaultsecret' del propio
# secreto: necesita leer/actualizar el secreto y aplicar la password al ADB
# (solo la acción adminPassword, sin permiso para crear/borrar bases de datos).
resource "oci_identity_policy" "adb_secret_rotation" {
  compartment_id = local.top_cmp_id
  name           = "freelz-adb-secret-rotation-policy"
  description    = "Permite al secreto de Vault rotar la password ADMIN del Autonomous DB."
  statements = [
    "Allow any-user to use secret-family in compartment id ${local.security_cmp_id} where all {request.principal.type = 'vaultsecret', request.principal.compartment.id = '${local.security_cmp_id}', target.secret.name = '${local.adb_secret_name}'}",
    "Allow any-user to use autonomous-databases in compartment id ${local.database_cmp_id} where all {request.principal.type = 'vaultsecret', request.principal.compartment.id = '${local.security_cmp_id}', request.operation.actiontype = 'adminPassword'}",
  ]
}
