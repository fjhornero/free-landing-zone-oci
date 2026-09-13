# Compartment quotas que acotan el tenancy a los límites Always Free.
# A diferencia del budget (que solo avisa), las quotas BLOQUEAN la creación
# de recursos que las excedan. Las familias de pago quedan a cero y las que
# usa la landing zone se fijan exactamente en el máximo Always Free.
# Nota: las quotas limitan la CREACIÓN de recursos; no aplican a consumo
# (p. ej. egress de red) de recursos ya existentes.

resource "oci_limits_quota" "free_tier_cap" {
  compartment_id = var.tenancy_ocid # las quotas siempre viven en el compartimento raíz
  name           = "${var.service_label}-free-tier-cap"
  description    = "Acota el tenancy a los limites Always Free: compute A1 4 OCPU/24GB, 200GB block storage, 2 ADB free; resto de familias de pago a cero."

  statements = [
    # Compute: solo Ampere A1 hasta el máximo Always Free (4 OCPU / 24 GB)
    "zero compute-core quotas in tenancy",
    "set compute-core quota standard-a1-core-count to 4 in tenancy",
    "zero compute-memory quotas in tenancy",
    "set compute-memory quota standard-a1-memory-count to 24 in tenancy",

    # Block storage: 200 GB totales y 5 backups (límite Always Free)
    "zero block-storage quotas in tenancy",
    "set block-storage quota total-storage-gb to 200 in tenancy",
    "set block-storage quota backup-count to 5 in tenancy",

    # Base de datos: solo Autonomous Database Always Free (máximo 2)
    "zero database quotas in tenancy",
    "set database quota adb-free-count to 2 in tenancy",

    # Familias de pago que no usa la landing zone: bloqueadas por completo
    "zero load-balancer quotas in tenancy",
    "zero filesystem quotas in tenancy",
  ]
}
