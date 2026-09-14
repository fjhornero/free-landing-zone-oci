# IP pública actual autorizada para SSH a las VMs (actualízala si cambia tu IP).
allowed_ssh_cidr = "0.0.0.0/0"

# Clave SSH inyectada en las VMs (default: ~/.ssh/id_rsa.pub, definido en variables.tf).
# ssh_public_key_path = "~/.ssh/id_rsa.pub"

# VM Ampere A1.Flex (Ubuntu 24.04 aarch64, 4 OCPU / 24 GB Always Free)
deploy_arm = true

# AMD E2.1.Micro canceladas: solo desplegamos la Ampere A1
amd_instance_count = 0

# Rotación anual de la password ADMIN del ADB (360 días es el máximo que admite OCI Vault).
adb_secret_rotation_interval = "P360D"
