variable "ssh_public_key_path" {
  description = "Ruta a la clave pública SSH que se inyecta en las VMs."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "allowed_ssh_cidr" {
  description = "CIDR con permiso de acceso SSH (puerto 22) a las VMs. No usar 0.0.0.0/0 (regla CIS de la landing zone)."
  type        = string
}

variable "amd_instance_count" {
  description = "Número de VMs AMD VM.Standard.E2.1.Micro (máx. 2 en Always Free)."
  type        = number
  default     = 2
}

variable "adb_workload" {
  description = "Workload de la Autonomous DB Always Free: OLTP (ATP), DW (ADW), AJD (JSON) o APEX."
  type        = string
  default     = "OLTP"
  validation {
    condition     = contains(["OLTP", "DW", "AJD", "APEX"], var.adb_workload)
    error_message = "adb_workload debe ser OLTP, DW, AJD o APEX."
  }
}

variable "fault_domains" {
  description = "Fault domains a los que se asignan las VMs (amd[i] usa el elemento i mod N). Se rota entre reintentos para sondear capacidad."
  type        = list(string)
  default     = ["FAULT-DOMAIN-1", "FAULT-DOMAIN-2", "FAULT-DOMAIN-3"]
}

variable "deploy_arm" {
  description = "Si true, despliega también la VM Ampere A1.Flex. Desactivada por defecto por falta de capacidad free tier en eu-madrid-1."
  type        = bool
  default     = false
}

variable "arm_ocpus" {
  description = "OCPUs de la VM Ampere A1 (máx. 4 gratis en total)."
  type        = number
  default     = 4
}

variable "arm_memory_gbs" {
  description = "Memoria (GB) de la VM Ampere A1 (máx. 24 gratis en total)."
  type        = number
  default     = 24
}
