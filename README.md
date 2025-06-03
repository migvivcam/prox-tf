# PoC - Proxmox - Terraform

Automatización de la infraestructura usando **Proxmox**, **Terraform**, **Ansible** y **Jenkins**.  
Este proyecto permite la instalación y configuración de un servidor Proxmox, la provisión de máquinas virtuales mediante Terraform, su configuración automática con Ansible, y la orquestación del proceso completo usando una pipeline de Jenkins.

---

## Estructura del repositorio

```
prox-tf/
├── ansible/        # Playbooks y roles para configuración de VMs
├── imgs/           # Imágenes y capturas usadas en la documentación
├── jenkins/        # Archivos relacionados con la pipeline de Jenkins
├── terraform/      # Código de infraestructura como código para Proxmox
└── README.md       # Documentación del proyecto
```

---

## Requisitos previos

- Un servidor físico con Proxmox VE instalado.
- Acceso al usuario administrador de Proxmox (por IP o dominio).
- Terraform ≥ v1.0
- Ansible ≥ v2.10
- Jenkins instalado y funcionando (puede ser en contenedor, VM o máquina local).
- Acceso a red entre Jenkins, Proxmox y las VMs generadas.
- Claves SSH configuradas para acceso sin contraseña desde Jenkins y/o tu host.

---

## 1. Instalación de Proxmox

> ⚠️ Completa esta sección con los pasos seguidos para instalar Proxmox.  
Puedes incluir comandos, links oficiales, y/o capturas de pantalla desde `imgs/`.

### Pasos:
1. Descargar la ISO de Proxmox desde [proxmox.com](https://www.proxmox.com/en/downloads).
2. Crear un USB booteable o usar una solución virtual.
3. Instalar el sistema y configurar la red básica.
4. Acceder a la interfaz web vía `https://<IP>:8006`.

---

## 2. Configuración de Terraform

> ⚠️ Describe cómo usar Terraform para conectarse a Proxmox y crear máquinas virtuales.

### 2.1 Configuración inicial

```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars
```

Edita `terraform.tfvars` con tus datos (host, usuario, clave, plantillas, etc.).

### 2.2 Comandos básicos

```bash
terraform init
terraform plan
terraform apply
```

---

## 3. Automatización con Ansible

> ⚠️ Explica cómo Ansible se conecta a las VMs creadas y qué configuraciones realiza.

### 3.1 Inventario dinámico o estático

Ejemplo de `inventory.ini`:

```ini
[web]
192.168.1.100 ansible_user=root

[db]
192.168.1.101 ansible_user=root
```

### 3.2 Ejecución de playbooks

```bash
cd ansible/
ansible-playbook -i inventory.ini site.yml
```

---

## 4. Integración con Jenkins

> ⚠️ Detalla cómo se usa Jenkins para orquestar el proceso completo.

### 4.1 Instalación de plugins necesarios

- Git
- Pipeline
- Ansible
- Terraform (opcional)
- SSH Agent

### 4.2 Pipeline de ejemplo (`jenkins/Jenkinsfile`)

```groovy
pipeline {
    agent any

    stages {
        stage('Terraform Init') {
            steps {
                sh 'cd terraform && terraform init'
            }
        }
        stage('Terraform Apply') {
            steps {
                sh 'cd terraform && terraform apply -auto-approve'
            }
        }
        stage('Ansible Config') {
            steps {
                sh 'cd ansible && ansible-playbook -i inventory.ini site.yml'
            }
        }
    }
}
```

---

## 5. Imágenes y ejemplos

> Puedes referenciar imágenes incluidas en `imgs/` aquí.

![Dashboard Proxmox](imgs/proxmox-dashboard.png)
![Pipeline Jenkins](imgs/jenkins-pipeline.png)

---

## 6. Notas finales

- Recuerda asegurar el acceso SSH a tus VMs desde Jenkins y Ansible.
- Usa variables y secretos con cuidado en Jenkins (Credentials Binding).
- Puedes extender el proyecto para incluir monitoreo, backups, etc.

---

## Autor

Tu Nombre – [Tu Email o LinkedIn]  
Proyecto realizado como parte del módulo de bastionado de sistemas y redes.
