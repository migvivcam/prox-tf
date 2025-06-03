# terraform/terraform.tfvars.example
# Copia este archivo como terraform.tfvars y completa los valores

# Configuración de Proxmox
proxmox_api_url      = "https://YOUR_PROXMOX_IP:8006/api2/json"
proxmox_user         = "YOUR_USERNAME@pam"
proxmox_password     = "YOUR_PASSWORD"
proxmox_tls_insecure = true

# Configuración del nodo y template
target_node   = "YOUR_PROXMOX_NODE_NAME"
template_name = "ubuntu-cloud-template"

# Configuración de VMs
vm_count       = 3
vm_name_prefix = "ansible-vm"
vm_memory      = 2048
vm_cores       = 2
vm_disk_size   = "20G"

# Configuración de red
network_bridge = "vmbr0"
ip_base        = "192.168.1"
ip_start       = 100
gateway        = "192.168.1.1"
dns_servers    = "8.8.8.8,8.8.4.4"

# Usuario y SSH
default_user     = "ansible"
ssh_public_key   = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB... your-key-here user@hostname"

---

# .gitignore
# Terraform
*.tfstate
*.tfstate.*
*.tfvars
.terraform/
.terraform.lock.hcl
crash.log
crash.*.log

# Ansible
ansible_inventory.ini
*.retry

# SSH keys
*.pem
*.key

---

# README.md
# Terraform Proxmox VM Deployment

Este esquema de Terraform automatiza el despliegue de máquinas virtuales en Proxmox, configuradas para ser gestionadas con Ansible.

## Prerequisitos

1. **Terraform instalado** (versión >= 1.0)
2. **Proxmox VE** con API habilitada
3. **Template de VM** preparado con cloud-init (Ubuntu recomendado)
4. **Clave SSH** generada

## Preparación del Template

Antes de usar este script, necesitas preparar un template en Proxmox:

```bash
# En el nodo de Proxmox, descargar imagen de Ubuntu
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Crear VM y configurarla como template
qm create 9000 --name ubuntu-cloud-template --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1
qm template 9000
```

## Configuración

1. **Copiar el archivo de variables:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Editar terraform.tfvars** con tus valores:
   - Credenciales de Proxmox
   - Nombre del nodo
   - Configuración de red
   - Tu clave pública SSH

3. **Generar clave SSH** (si no la tienes):
   ```bash
   ssh-keygen -t rsa -b 4096 -C "ansible@proxmox-vms"
   ```

## Uso

1. **Inicializar Terraform:**
   ```bash
   terraform init
   ```

2. **Planificar el despliegue:**
   ```bash
   terraform plan
   ```

3. **Aplicar la configuración:**
   ```bash
   terraform apply
   ```

4. **Ver las VMs creadas:**
   ```bash
   terraform output vm_info
   ```

## Características

- **IPs estáticas:** Las VMs reciben IPs incrementales automáticamente
- **Nombres incrementales:** ansible-vm-01, ansible-vm-02, etc.
- **SSH configurado:** Clave pública instalada automáticamente
- **Inventario de Ansible:** Se genera automáticamente
- **Cloud-init:** Configuración automática del SO

## Conexión SSH

Una vez desplegadas las VMs, puedes conectarte así:

```bash
ssh ansible@192.168.1.100  # Primera VM
ssh ansible@192.168.1.101  # Segunda VM
# etc.
```

## Ansible

El script genera automáticamente un inventario de Ansible en `ansible_inventory.ini`:

```bash
ansible -i ansible_inventory.ini proxmox_vms -m ping
```

## Limpieza

Para destruir todas las VMs:

```bash
terraform destroy
```

## Personalización

Puedes ajustar las variables en `terraform.tfvars`:

- `vm_count`: Número de VMs a crear
- `vm_memory`: RAM por VM (MB)
- `vm_cores`: CPUs por VM
- `ip_start`: IP inicial para el rango
- `vm_name_prefix`: Prefijo para nombres de VM

## Troubleshooting

- Verificar que el template existe en Proxmox
- Comprobar conectividad a la API de Proxmox
- Asegurar que el rango de IPs está disponible
- Verificar permisos del usuario en Proxmox
