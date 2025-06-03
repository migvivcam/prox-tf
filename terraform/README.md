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