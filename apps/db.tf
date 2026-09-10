# Autonomous Database Always Free (1 OCPU / 20 GB) en el compartimento de BD de la landing zone.
# Acceso por endpoint público con ACL: solo la IP autorizada y la VCN de la LZ.

locals {
  database_cmp_id = data.terraform_remote_state.lz.outputs.compartments["DATABASE-CMP"].id
}

resource "random_password" "adb_admin" {
  length           = 20
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  special          = true
  override_special = "#_-" # subconjunto seguro: ADB no admite comillas ni algunos simbolos
}

resource "oci_database_autonomous_database" "free" {
  compartment_id = local.database_cmp_id
  db_name        = "freelzadb1"
  display_name   = "freelz-adb-1"
  db_workload    = var.adb_workload
  is_free_tier   = true

  cpu_core_count           = 1
  data_storage_size_in_tbs = 1 # ignorado en free tier: se aprovisionan 20 GB

  admin_password = random_password.adb_admin.result

  # ACL: tu IP publica y cualquier recurso dentro de la VCN de la landing zone
  whitelisted_ips = [var.allowed_ssh_cidr, local.vcn_id]

  lifecycle {
    ignore_changes = [admin_password] # no rotar la contraseña en applies posteriores
  }
}
