# terraform/main.tf

terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc9"
    }
  }
}

# Configuración del provider de Proxmox
provider "proxmox" {
  pm_api_url      = var.proxmox_api_url
  pm_user         = var.proxmox_user
  pm_password     = var.proxmox_password
  pm_tls_insecure = var.proxmox_tls_insecure
}

# Definición de variables
variable "proxmox_api_url" {
  description = "URL de la API de Proxmox"
  type        = string
  default     = "https://YOUR_PROXMOX_IP:8006/api2/json"
}

variable "proxmox_user" {
  description = "Usuario de Proxmox"
  type        = string
  default     = "YOUR_USERNAME@pam"
}

variable "proxmox_password" {
  description = "Contraseña de Proxmox"
  type        = string
  sensitive   = true
  default     = "YOUR_PASSWORD"
}

variable "proxmox_tls_insecure" {
  description = "Permitir conexiones TLS inseguras"
  type        = bool
  default     = true
}

variable "vm_count" {
  description = "Número de VMs a crear"
  type        = number
  default     = 1
}

variable "vm_name_prefix" {
  description = "Prefijo para el nombre de las VMs"
  type        = string
  default     = "ansible-vm"
}

variable "target_node" {
  description = "Nodo de Proxmox donde crear las VMs"
  type        = string
  default     = "YOUR_PROXMOX_NODE"
}

variable "template_name" {
  description = "Nombre del template base"
  type        = string
  default     = "ubuntu-cloud-template"
}

variable "vm_memory" {
  description = "Memoria RAM en MB"
  type        = number
  default     = 2048
}

variable "vm_cores" {
  description = "Número de cores de CPU"
  type        = number
  default     = 2
}

variable "vm_disk_size" {
  description = "Tamaño del disco en GB"
  type        = string
  default     = "20G"
}

variable "network_bridge" {
  description = "Bridge de red"
  type        = string
  default     = "vmbr0"
}

variable "ip_base" {
  description = "Base de IP (ej: 192.168.1)"
  type        = string
  default     = "192.168.1"
}

variable "ip_start" {
  description = "IP inicial para las VMs"
  type        = number
  default     = 100
}

variable "gateway" {
  description = "Gateway de red"
  type        = string
  default     = "192.168.1.1"
}

variable "dns_servers" {
  description = "Servidores DNS"
  type        = string
  default     = "8.8.8.8,8.8.4.4"
}

variable "ssh_public_key" {
  description = "Clave pública SSH para acceso a las VMs"
  type        = string
  default     = "ssh-rsa YOUR_PUBLIC_KEY_HERE user@hostname"
}

variable "default_user" {
  description = "Usuario por defecto para las VMs"
  type        = string
  default     = "ansible"
}

variable "default_password" {
  description = "Contraseña por defecto para las VMs"
  type        = string
  default     = "change_me_please"
}

# Creación de las máquinas virtuales
resource "proxmox_vm_qemu" "vm_instances" {
  count       = var.vm_count
  name        = "${var.vm_name_prefix}-${format("%02d", count.index + 1)}"
  target_node = var.target_node
  clone       = var.template_name
  full_clone  = true
  vmid        = 250 + count.index

  # Configuración de hardware
  memory  = var.vm_memory
  hotplug = "network,disk,usb"
  cpu {
    cores   = var.vm_cores
    sockets = 1
    type    = "host"
  }
  vga {
    type = "std"
  }

  # Configuración básica del sistema
  bootdisk = "scsi0"
  scsihw   = "virtio-scsi-pci"
  agent    = 1

  # Configuración de disco
  disk {
    storage = "local-lvm"
    type    = "disk"
    size    = var.vm_disk_size
    slot    = "scsi0"
  }

  disk {
    storage = "local-lvm"
    type    = "cloudinit"
    slot    = "ide2"
  }

  # Configuración de red
  network {
    id       = 0
    model    = "virtio"
    bridge   = var.network_bridge
    firewall = false
  }

  # Cloud-init configuration
  os_type    = "cloud-init"
  ciuser     = var.default_user
  cipassword = var.default_password
  sshkeys    = var.ssh_public_key

  # Configuración de IP estática
  ipconfig0 = "ip=${var.ip_base}.${var.ip_start + count.index}/24,gw=${var.gateway}"

  # Configuración DNS y dominio
  searchdomain = "local"
  nameserver   = var.dns_servers

  # Lifecycle management
  lifecycle {
    ignore_changes = [
      network,
      cipassword,
    ]
  }

  # No usar provisioner local-exec aquí para evitar problemas
  # En su lugar, usar depends_on si es necesario

  tags = "terraform,ansible-ready"
}

# Output con información de las VMs creadas
output "vm_info" {
  description = "Información de las VMs creadas"
  value = {
    for idx, vm in proxmox_vm_qemu.vm_instances : vm.name => {
      id          = vm.vmid
      name        = vm.name
      ip_address  = "${var.ip_base}.${var.ip_start + idx}"
      ssh_command = "ssh ${var.default_user}@${var.ip_base}.${var.ip_start + idx}"
    }
  }
}

# Generar inventario de Ansible directamente
resource "local_file" "ansible_inventory" {
  content  = <<-EOF
[proxmox_vms]
%{for idx, vm in proxmox_vm_qemu.vm_instances~}
${vm.name} ansible_host=${var.ip_base}.${var.ip_start + idx} ansible_user=${var.default_user} ansible_ssh_private_key_file=~/.ssh/id_rsa
%{endfor~}

[proxmox_vms:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
ansible_python_interpreter=/usr/bin/python3
EOF
  filename = "${path.module}/ansible_inventory.ini"
}
