# -----------------------------------------------------------------------------
# Private Service Access (PSA) hacia Object Storage desde la subred web.
#
# Sustituye al Service Gateway como via de acceso al Object Storage: el
# endpoint recibe una IP privada propia dentro de la subred web y los FQDN del
# servicio (objectstorage / compat.objectstorage / swiftobjectstorage de la
# region) resuelven a esa IP, asi que el trafico no sale de la VCN ni depende
# de la OSN-RULE de la route table.
#
# Sin coste: PSA no tiene cargo por hora de conexion ni por byte procesado, y
# los componentes de VCN no se facturan en Always Free.
# -----------------------------------------------------------------------------

resource "oci_psa_private_service_access" "object_storage" {
  count          = var.define_net && var.add_tt_vcn1 ? 1 : 0
  compartment_id = local.network_compartment_id
  subnet_id      = module.lz_network.provisioned_networking_resources.subnets["TT-VCN-1-WEB-SUBNET"].id
  service_id     = "object-storage"
  display_name   = "${var.service_label}-psa-objectstorage"
  freeform_tags  = local.landing_zone_tags
}

output "psa_object_storage" {
  description = "PSA endpoint de Object Storage: IP privada y FQDNs que resuelven a ella."
  value = length(oci_psa_private_service_access.object_storage) > 0 ? {
    id    = oci_psa_private_service_access.object_storage[0].id
    ip    = oci_psa_private_service_access.object_storage[0].ipv4ip
    fqdns = oci_psa_private_service_access.object_storage[0].fqdns
  } : null
}

variable "tt_vcn1_web_subnet_object_storage_via_psa" {
  description = "Cuando es true, la subred web del TT-VCN-1 accede a Object Storage por el endpoint PSA y se retira la OSN-RULE que enrutaba ese trafico por el Service Gateway."
  type        = bool
  default     = false
}
