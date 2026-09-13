# VMs Always Free sobre la landing zone:
#   - 2x VM.Standard.E2.1.Micro (AMD, 1/8 OCPU, 1 GB RAM)
#   - 1x VM.Standard.A1.Flex (Ampere ARM, 4 OCPU, 24 GB RAM)
# Se despliegan en la subred web (pública) del TT-VCN-1, en el compartimento de aplicaciones.
# SSH restringido por NSG al CIDR de var.allowed_ssh_cidr.

data "terraform_remote_state" "lz" {
  backend = "oci"
  config = {
    bucket              = "oci-tfstate"
    namespace           = "axwqnihb5ohp"
    key                 = "free-landing-zone/terraform.tfstate"
    region              = "eu-madrid-1"
    auth                = "APIKey"
    config_file_profile = "FREE-TIER"
  }
}

locals {
  app_cmp_id     = data.terraform_remote_state.lz.outputs.compartments["APP-CMP"].id
  network_cmp_id = data.terraform_remote_state.lz.outputs.compartments["NETWORK-CMP"].id
  web_subnet_id  = data.terraform_remote_state.lz.outputs.subnets["TT-VCN-1-WEB-SUBNET"].id
  vcn_id         = data.terraform_remote_state.lz.outputs.vcns["TT-VCN-1"].id
  ssh_public_key = file(pathexpand(var.ssh_public_key_path))
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = data.terraform_remote_state.lz.outputs.compartments["TOP-CMP"].id
}

locals {
  ad_name = data.oci_identity_availability_domains.ads.availability_domains[0].name
}

# --- Imágenes Oracle Linux más recientes por arquitectura ---
data "oci_core_images" "ol_amd" {
  compartment_id           = local.app_cmp_id
  operating_system         = "Oracle Linux"
  operating_system_version = "9"
  shape                    = "VM.Standard.E2.1.Micro"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

data "oci_core_images" "ubuntu_arm" {
  compartment_id           = local.app_cmp_id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# --- NSG para acceso SSH restringido (en el compartimento de red, como el resto de NSGs de la LZ) ---
resource "oci_core_network_security_group" "ssh" {
  compartment_id = local.network_cmp_id
  vcn_id         = local.vcn_id
  display_name   = "freevm-ssh-nsg"
}

resource "oci_core_network_security_group_security_rule" "ssh_ingress" {
  network_security_group_id = oci_core_network_security_group.ssh.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = var.allowed_ssh_cidr
  source_type               = "CIDR_BLOCK"
  description               = "SSH desde IP autorizada"
  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "web_ingress" {
  for_each                  = toset(["80", "443"])
  network_security_group_id = oci_core_network_security_group.ssh.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  description               = "HTTP/HTTPS publico para las webs migradas"
  tcp_options {
    destination_port_range {
      min = each.value
      max = each.value
    }
  }
}

resource "oci_core_network_security_group_security_rule" "egress_all" {
  network_security_group_id = oci_core_network_security_group.ssh.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  description               = "Egress general (actualizaciones de paquetes, etc.)"
}

# --- 2x AMD E2.1.Micro ---
resource "oci_core_instance" "amd" {
  count               = var.amd_instance_count
  compartment_id      = local.app_cmp_id
  availability_domain = local.ad_name
  display_name        = "freevm-amd-${count.index + 1}"
  shape               = "VM.Standard.E2.1.Micro"
  fault_domain        = var.fault_domains[count.index % length(var.fault_domains)]

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ol_amd.images[0].id
  }

  create_vnic_details {
    subnet_id        = local.web_subnet_id
    assign_public_ip = true
    hostname_label   = "freevm-amd-${count.index + 1}"
    nsg_ids          = [oci_core_network_security_group.ssh.id]
  }

  metadata = {
    ssh_authorized_keys = local.ssh_public_key
  }

  lifecycle {
    # source_id: no recrear la VM cuando Oracle publique una imagen más nueva.
    # fault_domain: la rotación de FDs entre reintentos no debe recrear VMs ya creadas.
    ignore_changes = [source_details[0].source_id, fault_domain]
  }
}

# --- Block volume adicional de 100 GB (Always Free: hasta 200 GB totales incluyendo boot volumes) ---
resource "oci_core_volume" "data" {
  compartment_id      = local.app_cmp_id
  availability_domain = local.ad_name
  display_name        = "freevm-arm-1-data"
  size_in_gbs         = 100
  vpus_per_gb         = 10 # Balanced, incluido en Always Free
}

resource "oci_core_volume_attachment" "data" {
  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.arm[0].id
  volume_id       = oci_core_volume.data.id
  display_name    = "freevm-arm-1-data-attach"
}

# --- 1x Ampere A1.Flex (4 OCPU / 24 GB = máximo Always Free), opcional vía deploy_arm ---
resource "oci_core_instance" "arm" {
  count               = var.deploy_arm ? 1 : 0
  compartment_id      = local.app_cmp_id
  availability_domain = local.ad_name
  display_name        = "freevm-arm-1"
  shape               = "VM.Standard.A1.Flex"
  fault_domain        = var.arm_fault_domain != "" ? var.arm_fault_domain : null

  shape_config {
    ocpus         = var.arm_ocpus
    memory_in_gbs = var.arm_memory_gbs
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu_arm.images[0].id
  }

  create_vnic_details {
    subnet_id        = local.web_subnet_id
    assign_public_ip = true
    hostname_label   = "freevm-arm-1"
    nsg_ids          = [oci_core_network_security_group.ssh.id]
  }

  metadata = {
    ssh_authorized_keys = local.ssh_public_key
  }

  lifecycle {
    # fault_domain: rotarlo entre reintentos no debe recrear la VM una vez creada.
    ignore_changes = [source_details[0].source_id, fault_domain]
  }
}
