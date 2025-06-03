terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "=3.0.2-rc01"
    }
  }
}

provider "proxmox" {
  pm_api_url          = "https://192.168.1.189:8006/api2/json"
  pm_api_token_id     = "terraform@pve!terraform"
  pm_api_token_secret = "7c93f4aa-185e-4755-a4f5-6a40f5022d87"
  pm_tls_insecure     = true
}


resource "proxmox_lxc" "lxc1" {
  hostname      = var.lxc_hostname
  ostemplate    = var.lxc_template
  target_node   = "sponge"
  cores         = 2
  memory        = 1024
  swap          = 512
  unprivileged  = true
  start         = true
  password      = "ciber"
  
  rootfs {
    storage = "local-lvm"
    size    = "12G"
  }

  features {
    nesting = true
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
  }
}
