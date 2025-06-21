# 📦 Despliegue de Traefik en K3s con Ansible

Este proyecto instala **Traefik** como controlador de Ingress dentro de un clúster **K3s** utilizando **Helm** y **Ansible**. La instalación incluye:

- Desinstalación de Traefik por defecto (K3s).
- Instalación con Helm (versión 26.1.0 o superior).
- Generación de certificados autofirmados wildcard.
- Uso de Let's Encrypt para dominios públicos.
- Configuración de VIPs gestionadas con HAProxy + Keepalived.
- Autenticación básica en el dashboard vía middleware sellado.
- Montaje de certificados desde PVC (almacenamiento persistente con Longhorn).
- Acceso externo seguro mediante dominio público con IP dinámica usando Cloudflare.
- Acceso interno vía VPN WireGuard para herramientas de administración.

---

## 📁 Estructura del Proyecto

```plaintext
traefik-ansible-k3s-cluster/
├── inventory/hosts.ini              # Inventario Ansible con nodos
├── vars/main.yml                    # Variables globales
├── playbooks/
│   ├── 1-generate-selfsigned-certs.yml
│   ├── 2-generate-internal-tls-cert.yml
│   ├── 3-create-cert-pvc.yml
│   ├── 4-seal-traefik-auth-secret.yml
│   ├── 5-install-traefik-dashboard.yml
│   ├── deploy_traefik.yml           # Despliegue completo (con PVC)
│   ├── uninstall-traefik-dashboard.yml
│   └── files/
│       └── certs/                   # Certificados generados localmente
├── templates/
│   ├── secrets/
│   │   ├── tls-secret.yaml.j2
│   │   └── traefik-dashboard-secret.yaml.j2
│   └── traefik/
│       ├── traefik-dashboard-ingressroute-internal.yaml.j2
│       ├── traefik-dashboard-middleware.yaml.j2
│       └── values_pvc.yaml.j2
├── ansible.cfg
├── README.md
└── Summary.md
```

---

## ⚙️ Requisitos

- **Ansible**: Instalado en el nodo de control.
- **Acceso SSH**: A los nodos con claves privadas.
- **Clúster K3s**: Ya desplegado con kubeconfig accesible.
- **Helm**: Instalado en el nodo de control.
- **Cloudflare**: (opcional) configurado para acceso público.

---

## 🔧 Flujo de Despliegue Paso a Paso

### 🔐 FASE 1: Generación de Certificados y Secrets

```bash
ansible-playbook playbooks/deploy_traefik.yml
```
Este playbook ejecuta en orden:

1. Generación de certificados autofirmados.
2. Creación del Secret TLS (`wildcard-socialdevs-tls`).
3. Creación del PVC de Longhorn con los certificados montados.
4. Generación y sellado del Secret `htpasswd` para el dashboard.
5. Instalación de Traefik con Helm utilizando el PVC.
6. Verificación final del dashboard de Traefik.

---

## 🌐 IPs y Asignaciones DHCP Estáticas

| Nombre           | Dirección MAC         | IP Asignada     | Rol                              |
|------------------|-----------------------|-----------------|----------------------------------|
| loadbalancer1    | 52:54:00:aa:bb:cc     | 192.168.0.30    | HAProxy + Keepalived (master)   |
| loadbalancer2    | 52:54:00:39:ae:c8     | 192.168.0.31    | HAProxy + Keepalived (backup)   |
| api_vip          | 00:00:5e:00:01:10     | 192.168.0.32    | VIP para Kubernetes API         |
| second_vip       | 00:00:5e:00:01:20     | 192.168.0.33    | VIP para Traefik Ingress HTTP/HTTPS |

Estas IPs están definidas en el router doméstico como direcciones estáticas (DHCP reservado), asegurando consistencia incluso tras reinicios.

---

## 🚦 Flujo de Red Externa e Interna

```plaintext
🖥️ Usuario externo
   │
   ├─ Acceso público:
   │    Cloudflare (DNS + HTTPS con IP dinámica)
   │       ↓
   │    Router doméstico (NAT)
   │       ↓
   │    192.168.0.33 → VIP Ingress HTTP/HTTPS (80/443)
   │       ↓
   │    HAProxy + Keepalived
   │       ↓
   │    Traefik (Ingress Controller)
   │       ↓
   │    Servicios públicos (web, API, etc.)
   │
   └─ Acceso interno (gestión):
        VPN WireGuard → Red privada (10.17.x.x)
             ↓
        192.168.0.33 → VIP Ingress HTTP/HTTPS
             ↓
        Traefik Dashboard, Grafana, Prometheus, etc.
```

⚠️ **Importante:** La VPN se utiliza exclusivamente para acceder a servicios internos de gestión (no públicos).

---

## 🔐 Acceso al Dashboard de Traefik

- **URL**: `https://traefik.socialdevs.site/dashboard/`
- **Usuario**: `admin`
- **Contraseña**: definida en `vars/main.yml` (encriptada con `htpasswd`)

### 🔏 Generación de archivo htpasswd (manual)

```bash
htpasswd -nb admin MiPasswordSegura > files/htpasswd.txt
```

O en Python:

```bash
python3 -c "import crypt; print('admin:' + crypt.crypt('MiPasswordSegura', crypt.mksalt(crypt.METHOD_MD5)))"
```

Este archivo se cifra automáticamente con `kubeseal` al ejecutar el playbook correspondiente.

---

## 🛠 Configuración avanzada

### Let's Encrypt (Producción)

Para usar certificados reales en lugar de autofirmados, cambia la URL del CA de staging por:

```plaintext
https://acme-v02.api.letsencrypt.org/directory
```

Y asegúrate de tener el `email` y `certResolver` configurados correctamente en `values_pvc.yaml.j2`.

---

### 🔄 Propósito de `uninstall-traefik-dashboard.yml`

Permite eliminar de forma segura todos los componentes de Traefik, incluyendo:

- Helm Release
- PVC de certificados
- Secrets (autenticación + TLS)
- IngressRoutes y Middlewares

#### 💡 Cuándo Usarlo

- 🔁 Resetear entornos de prueba
- 🧼 Reinstalación limpia
- 🛠 Reintento tras fallo crítico

```bash
ansible-playbook playbooks/uninstall-traefik-dashboard.yml
```

---

## 🧠 Qué Resuelve Este Setup

| Problema                          | Solución                                   |
|-----------------------------------|--------------------------------------------|
| No tienes dominio público real    | Uso de wildcard autofirmado.               |
| Necesitas HTTPS                   | Certificados autofirmados / Let's Encrypt. |
| Múltiples subdominios             | `*.socialdevs.site`.                       |
| Enrutamiento interno flexible     | Traefik + IngressRoute + Middleware.       |
| DNS interno                       | CoreDNS.                                   |

---

## 🔒 Seguridad y Buenas Prácticas

### Recomendaciones de Seguridad

| Servicio                          | Exposición                              | Protección Requerida                       |
|-----------------------------------|-----------------------------------------|--------------------------------------------|
| **Público** (APIs, webs)          | Ingress (Traefik) + VIP externo         | HTTPS + Firewall + Cloudflare              |
| **Privado** (Traefik UI, Admin)   | Solo VPN/LAN o IP filtrada              | `htpasswd`, TLS, IP allowlist              |
| **Interno** (DB, etc.)            | Solo `ClusterIP`                        | Sin exposición externa                     |

---

## ✅ Detalles Técnicos

- **Certificados:** Autofirmados wildcard `*.socialdevs.site`.
- **Dashboard:** Disponible por HTTPS en `/dashboard/`.
- **Recursos:** 1 pod, 100m CPU, 128Mi RAM aprox.
- **Proveedores habilitados:** `kubernetesIngress`, `kubernetesCRD`.
- **Puertos utilizados:** 80, 443 (websecure), 9000 (dashboard opcional).

---

# 🔐 Estrategia TLS

## Let's Encrypt

- Para dominios públicos (`home.socialdevs.site`, etc.)
- Usan `certResolver letsencrypt`
- Renovación automática habilitada

## Certificados Internos

- Wildcard para `*.socialdevs.site`
- Generados con OpenSSL (`playbooks/1-generate-selfsigned-certs.yml`)
- Renderizados como Secret con `playbooks/2-generate-internal-tls-cert.yml`
- Compartidos entre namespaces usando `TLSStore` por defecto
- Montados opcionalmente desde PVC (producción)

---

## 🧪 Comandos de prueba

```bash
curl -k -u admin:SuperPassword123 https://traefik.socialdevs.site/dashboard/

curl -k -u admin:SuperPassword123 --resolve traefik.socialdevs.site:443:10.17.4.21 \
  https://traefik.socialdevs.site/dashboard/

kubectl get svc traefik -n kube-system -o yaml | grep nodePort
```

3. Certificados “globales” en todos los Namespaces
Ya los tienes:

Secret TLS kube-system/wildcard-socialdevs-tls.

PVC kube-system/certificados-longhorn con los mismos ficheros (*.crt, *.key).

TLSStore default en Traefik apunta al certificado dentro del contenedor montado desde el PVC.

Eso permite:

yaml
Copiar
Editar
# En cualquier IngressRoute de cualquier namespace:
tls: {}                # sin secretName
Traefik usará el defaultCertificate del TLSStore global.



1. Crear el archivo .env
Primero, crea el archivo .env en el directorio donde estás trabajando. Esto es lo que debes hacer:

Abre tu terminal.

Navega al directorio donde quieres crear el archivo .env.

Crea el archivo .env con el siguiente contenido:

bash
Copiar
Editar
# Crea el archivo .env
nano .env
Añade estas líneas en el archivo .env:

text
Copiar
Editar
LONGHORN_AUTH_USER=admin
LONGHORN_AUTH_PASS=SuperSecure456
# Puedes añadir otras variables como TRAEFIK_AUTH_USER y TRAEFIK_AUTH_PASS si lo necesitas
Guarda el archivo y sal de nano presionando Ctrl + X, luego Y para confirmar y Enter.

2. Cargar las variables de entorno
Ahora, para cargar las variables de entorno definidas en el archivo .env a tu sesión de terminal y hacerlas accesibles para los playbooks de Ansible, usa el siguiente comando:

Cargar las variables de entorno:
bash
Copiar
Editar
export $(cat .env | xargs)
Esto carga las variables definidas en el archivo .env al entorno actual de la terminal. Puedes verificar que se cargaron correctamente con el comando:

bash
Copiar
Editar
echo $LONGHORN_AUTH_USER
echo $LONGHORN_AUTH_PASS
Si ves las variables correctamente, entonces las configuraste bien.

3. Ejecutar el playbook de Ansible
Ahora que las variables de entorno están cargadas, puedes ejecutar tu playbook de Ansible utilizando esas variables.

Por ejemplo, para ejecutar un playbook, usa:

bash
Copiar
Editar
ansible-playbook -i inventory/hosts.ini playbooks/02_ingress-longhorn-internal.yml
Resumen:
Crear el archivo .env con tus variables de entorno.

Cargar las variables de entorno con el comando export $(cat .env | xargs).

Ejecutar tu playbook de Ansible con las variables de entorno ya cargadas.

Con estos pasos, no es necesario declarar manualmente las variables de entorno, ya que se cargan automáticamente desde el archivo .env en tu terminal y están listas para usar en el playbook de Ansible.