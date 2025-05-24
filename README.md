# Despliegue de Traefik en K3s con Ansible

Este proyecto instala **Traefik** como controlador de Ingress dentro de un clúster **K3s** utilizando **Helm** y **Ansible**. La instalación incluye:

- Desinstalación de Traefik por defecto (K3s).
- Instalación con Helm (versión 23.1.0).
- Habilitación de HTTPS (TLS) con Let's Encrypt (staging).
- Autenticación básica en el dashboard vía middleware.

---

## 📦 Estructura del Proyecto

```plaintext
traefik-ansible-k3s-cluster/
├── inventory.ini                     # Inventario Ansible con nodos controller y balanceadores
├── group_vars/
│   └── all.yml                      # Variables globales (namespace, versión chart, etc.)
├── files/
│   └── htpasswd.txt                # Credenciales para Basic Auth (admin)
├── playbooks/
│   └── install_traefik.yml         # Playbook principal
├── templates/
│   └── traefik/
│       └── values.yaml.j2          # Configuración de Traefik via Helm
└── README.md                        # Esta documentación
```

---

## ⚙️ Requisitos

- Ansible.
- Acceso SSH a los nodos (usando claves privadas).
- Clúster K3s ya desplegado.
- Helm instalado en el nodo de control.

---

## 🚀 Ejecución paso a paso

### 1. Configuración inicial

1. Edita tu inventario:

   ```ini
   [controller]
   10.17.4.21 ansible_user=core ansible_ssh_private_key_file=/ruta/a/id_rsa ansible_shell_executable=/bin/sh
   ```

2. Asegúrate de tener el archivo `files/htpasswd.txt` con el siguiente contenido generado por `htpasswd`:

   ```bash
   htpasswd -nb admin MiPasswordSegura > files/htpasswd.txt
   ```

### 2. Despliegue de Traefik

Ejecuta el playbook:

```bash
sudo ansible-playbook -i inventory/hosts.ini playbooks/install_traefik.yml
```

### 3. Acceso al Dashboard de Traefik

- **URL:** `https://<second_vip>/dashboard/`
- **Usuario:** `admin`
- **Contraseña:** la definida en `htpasswd.txt`.

---

## 🛠 Configuración avanzada

### Certificados reales de Let's Encrypt

Para usar certificados reales, cambia la URL del CA de staging por:

```plaintext
https://acme-v02.api.letsencrypt.org/directory
```

### Generación de archivo `htpasswd.txt`

#### Opción 1: Usar `htpasswd` (recomendado)

1. Instala `apache2-utils` (si no lo tienes):

   - En Debian/Ubuntu:

     ```bash
     sudo apt install apache2-utils
     ```

   - En CentOS/RHEL:

     ```bash
     sudo yum install httpd-tools
     ```

2. Genera el archivo:

   ```bash
   htpasswd -nb admin MiPasswordSegura
   ```

3. Guarda el contenido generado en `files/htpasswd.txt`.

#### Opción 2: Usar Python puro

Ejecuta el siguiente comando:

```bash
python3 -c "import crypt; print('admin:' + crypt.crypt('MiPasswordSegura', crypt.mksalt(crypt.METHOD_MD5)))"
```

Guarda el resultado en `files/htpasswd.txt`.

---

## 🧩 Flujo completo resumido

```plaintext
Usuario → Cloudflare (opcional) → WireGuard/VPN o red local
          ↓
    VIP 10.17.5.30 (HAProxy + Keepalived)
          ↓
      Nodo Traefik (NodePort 80/443)
          ↓
   Traefik (Ingress Controller en K3s)
          ↓
   Servicio Kubernetes (grafana, prometheus...)
```

---

## 🟢 Configuración de DNS

### CoreDNS externo

- **IP:** 10.17.3.11.
- Instalado manualmente con Ansible en AlmaLinux.
- Configurado como servicio de `systemd`.
- Corefile incluye:
  - Hosts estáticos con IPs internas y nombres bajo `.cefaslocalserver.com`.
  - Redirección al upstream público (8.8.8.8).

Configura este DNS como primario en `/etc/resolv.conf` o vía DHCP:

```bash
nameserver 10.17.3.11
nameserver 8.8.8.8
```

### CoreDNS interno (K3s)

- Resuelve solo nombres de servicios internos de Kubernetes (`.svc.cluster.local`).
- No requiere modificaciones adicionales.

---

## ✅ Conclusión

El proyecto `traefik-ansible-k3s-cluster`:

- Está **preparado para producción**, con seguridad (TLS, auth).
- Usa **Helm + Ansible** para mantener un despliegue declarativo y reproducible.
- Integra **Middleware**, `IngressRoute`, y auto TLS para prácticas modernas.

Puedes modificar el `values.yaml.j2` para añadir balanceo, rate-limiting, certificados personalizados o rutas adicionales según tus necesidades.

---

📬 ¿Tienes dudas o necesitas soporte adicional? No dudes en integrarlo con GitOps, monitoreo o alerting en próximos pasos.

