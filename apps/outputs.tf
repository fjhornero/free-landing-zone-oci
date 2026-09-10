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

output "adb_admin_password" {
  description = "Contraseña del usuario ADMIN de la ADB (leer con: terraform output -raw adb_admin_password)."
  value       = random_password.adb_admin.result
  sensitive   = true
}

output "ssh_nsg_id" {
  description = "OCID del NSG que permite SSH desde la IP autorizada."
  value       = oci_core_network_security_group.ssh.id
}
