output "vms" {
  description = "Instancias Always Free desplegadas: IP pública y privada de cada una."
  value = {
    for i in concat(oci_core_instance.amd, oci_core_instance.arm) :
    i.display_name => {
      shape      = i.shape
      public_ip  = i.public_ip
      private_ip = i.private_ip
      state      = i.state
    }
  }
}

output "adb" {
  description = "Autonomous DB Always Free: consola y cadenas de conexión."
  value = {
    db_name     = oci_database_autonomous_database.free.db_name
    workload    = oci_database_autonomous_database.free.db_workload
    state       = oci_database_autonomous_database.free.state
    console_url = oci_database_autonomous_database.free.connection_urls[0].sql_dev_web_url
    apex_url    = oci_database_autonomous_database.free.connection_urls[0].apex_url
    high_conn   = oci_database_autonomous_database.free.connection_strings[0].high
  }
}

# La password ADMIN vive ahora en OCI Vault y rota automáticamente: el valor de
# random_password queda obsoleto tras la primera rotación. Leer siempre del secreto:
#   oci secrets secret-bundle get --secret-id <ocid> --profile FREE-TIER \
#     --query 'data."secret-bundle-content".content' --raw-output | base64 -d
output "adb_admin_secret" {
  description = "OCID del secreto de Vault con la password ADMIN de la ADB (fuente de verdad tras cada rotación)."
  value       = oci_vault_secret.adb_admin.id
}

output "ssh_nsg_id" {
  description = "OCID del NSG que permite SSH desde la IP autorizada."
  value       = oci_core_network_security_group.ssh.id
}
