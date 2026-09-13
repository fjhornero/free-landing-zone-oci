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
  nsg_ids        = [oci_core_network_security_group.psa_object_storage[0].id]
  freeform_tags  = local.landing_zone_tags
}

# El endpoint es una VNIC en la subred: sin NSG propio queda sujeto a la
# security list por defecto de la VCN, que solo admite ICMP tipo 3, y las
# conexiones HTTPS al servicio no llegan. Este NSG abre el 443 al endpoint
# desde la VCN.
resource "oci_core_network_security_group" "psa_object_storage" {
  count          = var.define_net && var.add_tt_vcn1 ? 1 : 0
  compartment_id = local.network_compartment_id
  vcn_id         = module.lz_network.provisioned_networking_resources.vcns["TT-VCN-1"].id
  display_name   = "${var.service_label}-psa-objectstorage-nsg"
  freeform_tags  = local.landing_zone_tags
}

resource "oci_core_network_security_group_security_rule" "psa_object_storage_https" {
  count                     = var.define_net && var.add_tt_vcn1 ? 1 : 0
  network_security_group_id = oci_core_network_security_group.psa_object_storage[0].id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = var.tt_vcn1_cidrs[0]
  source_type               = "CIDR_BLOCK"
  description               = "HTTPS hacia el endpoint PSA de Object Storage desde la VCN"
  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

# Un NSG sin reglas de egress lo bloquea por completo, asi que el trafico de
# vuelta del endpoint necesita esta regla.
resource "oci_core_network_security_group_security_rule" "psa_object_storage_egress" {
  count                     = var.define_net && var.add_tt_vcn1 ? 1 : 0
  network_security_group_id = oci_core_network_security_group.psa_object_storage[0].id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  description               = "Egress del endpoint PSA"
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
