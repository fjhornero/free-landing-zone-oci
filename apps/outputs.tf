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

output "ssh_nsg_id" {
  description = "OCID del NSG que permite SSH desde la IP autorizada."
  value       = oci_core_network_security_group.ssh.id
}
