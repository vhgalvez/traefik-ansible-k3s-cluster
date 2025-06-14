# 📦 Despliegue de Traefik en K3s con Ansible

Este proyecto instala **Traefik** como controlador de Ingress dentro de un clúster **K3s** utilizando **Helm** y **Ansible**. La instalación incluye:

- Desinstalación de Traefik por defecto (K3s).
- Instalación con Helm (versión 26.1.0 o superior).
- Generación de certificados autofirmados o reales.
- Configuración de VIPs gestionadas con HAProxy + Keepalived.
- Autenticación básica en el dashboard vía middleware.
- Exposición externa segura usando dominio público + IP dinámica con Cloudflare.
- Acceso a servicios internos mediante VPN WireGuard.

---

## 📁 Estructura del Proyecto

```plaintext
traefik-ansible-k3s-cluster/
├── inventory/hosts.ini              # Inventario Ansible con nodos
├── vars/main.yml                    # Variables globales
├── files/
│   ├── traefik-dashboard-ingressroute.yaml
│   ├── traefik-dashboard-sealed.yaml
│   └── traefik-dashboard-secret.yaml
├── playbooks/
│   ├── deploy_traefik.yml           # Fase 1 y 2: Secret + Traefik sin PVC
│   ├── deploy_traefik_pvc.yml       # Fase 3: Instalación con PVC
│   ├── generate_traefik_secrets.yml
│   ├── install_traefik.yml
│   └── uninstall_traefik.yml
├── templates/
│   ├── secrets/traefik-dashboard-secret.yaml.j2
│   └── traefik/
│       ├── values_nopvc.yaml.j2
│       └── values_pvc.yaml.j2
├── scripts/
│   └── update-cloudflare-ip.sh      # Actualización dinámica de IP pública
├── ansible.cfg
└── README.md
```

---

## ⚙️ Requisitos

- **Ansible**: Instalado en el nodo de control.
- **Acceso SSH**: A los nodos con claves privadas.
- **Clúster K3s**: Ya desplegado.
- **Helm**: Instalado en el nodo de control.

---

## 🔧 Flujo de Despliegue Paso a Paso

### 🔐 FASE 1: Generación del Secret Sellado (Solo una vez)

```bash
sudo ansible-playbook playbooks/generate_traefik_secrets.yml
```

### 🚀 FASE 2: Despliegue Inicial Sin Almacenamiento Persistente (Modo Prueba)

```bash
sudo ansible-playbook playbooks/deploy_traefik.yml
```

### 🏁 FASE 3: Despliegue Final Con Almacenamiento Persistente (Producción)

```bash
sudo ansible-playbook playbooks/deploy_traefik_pvc.yml
```

---

## 🌐 IPs y Asignaciones DHCP Estáticas

| Nombre           | Dirección MAC         | IP Asignada     | Rol                              |
|------------------|-----------------------|-----------------|----------------------------------|
| loadbalancer1    | 52:54:00:aa:bb:cc    | 192.168.0.30    | HAProxy + Keepalived (master)   |
| loadbalancer2    | 52:54:00:39:ae:c8    | 192.168.0.31    | HAProxy + Keepalived (backup)   |
| api_vip          | 00:00:5e:00:01:10    | 192.168.0.32    | VIP para Kubernetes API         |
| second_vip       | 00:00:5e:00:01:20    | 192.168.0.33    | VIP para Traefik Ingress HTTP/HTTPS |

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

⚠️ **Importante:** La VPN se utiliza exclusivamente para acceder a servicios internos de gestión (no públicos). El acceso general a servicios públicos se realiza sin VPN, a través de dominios resueltos por Cloudflare.

---

## 🔐 Acceso al Dashboard de Traefik

- **URL**: `https://<second_vip>/dashboard/`
- **Usuario**: `admin`
- **Contraseña**: definida en `htpasswd.txt`

### 🔏 Generación de archivo htpasswd

```bash
htpasswd -nb admin MiPasswordSegura > files/htpasswd.txt
```

Alternativa en Python:

```bash
python3 -c "import crypt; print('admin:' + crypt.crypt('MiPasswordSegura', crypt.mksalt(crypt.METHOD_MD5)))"
```

---

## 🛠 Configuración avanzada

### Let's Encrypt (Modo Producción)

Para usar certificados reales, cambia la URL del CA de staging por:

```plaintext
https://acme-v02.api.letsencrypt.org/directory
```

---

### 🔄 Propósito de `uninstall_traefik.yml`

Permite eliminar de forma segura Traefik, su release de Helm, secretos (sellados y planos), IngressRoute, PVCs y archivos persistentes.

#### 💡 Cuándo Usarlo

- 🔁 Resetear entornos de prueba.
- 🛠 Reintentar instalación fallida.
- 🚀 Reinstalación limpia antes de la Fase 3.

```bash
sudo ansible-playbook playbooks/uninstall_traefik.yml
```

---

## 🧠 Qué Resuelve Este Setup

| Problema                          | Solución                                   |
|-----------------------------------|-------------------------------------------|
| No tienes dominio público real    | Dominio local `socialdevs.site`.          |
| Necesitas HTTPS                   | Certificados autofirmados wildcard.       |
| Múltiples subdominios             | `*.socialdevs.site`.                      |
| Enrutamiento interno flexible     | Traefik + IngressRoute + Middleware.      |
| DNS interno                       | CoreDNS.                                  |

---

## 🔒 Seguridad y Buenas Prácticas

### Recomendaciones de Seguridad

| Servicio                          | Exposición                              | Protección Requerida                       |
|-----------------------------------|-----------------------------------------|--------------------------------------------|
| **Público** (APIs, webs)          | Ingress (Traefik) + VIP externo         | HTTPS + Firewall + Dominio + IP dinámica   |
| **Privado** (Traefik UI, Admin)   | Solo VPN/LAN o IP filtrada              | `htpasswd`, TLS, Firewall IP               |
| **Interno** (DB, etc.)            | Solo `ClusterIP`                        | Sin Ingress                                |

---

## ✅ Detalles Técnicos

- **Certificados:** Autofirmados wildcard `*.socialdevs.site`.
- **Dashboard:** Puerto 8080 (opcional).
- **Recursos:** 1 pod, 100m CPU, 128Mi RAM.
- **Proveedores habilitados:** `kubernetesIngress`, `kubernetesCRD`.
- **Puertos utilizados:** 80, 443, 8080.


# Estrategia TLS (Let's Encrypt + Certificados Internos)

## Let's Encrypt:
- Dominios públicos (`socialdevs.site`, `home.socialdevs.site`)
- Usan certResolver `letsencrypt`
- Se renuevan automáticamente

## Certificados Internos:
- *.socialdevs.site (excepto los públicos)
- Generados con OpenSSL (wildcard)
- Aplicados como `Secret` TLS en el clúster
- Usados en IngressRoutes internos


curl -k -u admin:SuperPassword123 --resolve traefik.socialdevs.site:31541:10.17.4.21 https://traefik.socialdevs.site:31541/dashboard/

curl -k -u admin:SuperPassword123 https://traefik.socialdevs.site/dashboard/

curl -k -u admin:SuperPassword123 --resolve traefik.socialdevs.site:443:10.17.4.21 https://traefik.socialdevs.site/dashboard/


curl -k -u admin:SuperPassword123 https://traefik.socialdevs.site:31541/dashboard/




curl -k -u admin:SuperPassword123 --resolve traefik.socialdevs.site:32196:10.17.4.21 https://traefik.socialdevs.site:32196/dashboard/


curl -k -u admin:SuperPassword123 --resolve traefik.socialdevs.site:30348:10.17.4.21 https://traefik.socialdevs.site:30348/dashboard/

kubectl get svc traefik -n kube-system -o yaml | grep nodePort


[victory@virtualizacion-server ~]$ curl -k https://traefik.socialdevs.site/dashboard/
401 Unauthorized
[victory@virtualizacion-server ~]$ curl -k -u admin:SuperPassword123 https://traefik.socialdevs.site/dashboard/
<!DOCTYPE html><html><head><script>window.APIURL = "/api/"</script><title>Traefik</title><meta charset=utf-8><meta name=description content="Traefik UI"><meta name=format-detection content="telephone=no"><meta name=msapplication-tap-highlight content=no><meta name=viewport content="user-scalable=no,initial-scale=1,maximum-scale=1,minimum-scale=1,width=device-width"><link rel=icon type=image/png href=./app-logo-128x128.png><link rel=icon type=image/png sizes=16x16 href=./icons/favicon-16x16.png><link rel=icon type=image/png sizes=32x32 href=./icons/favicon-32x32.png><link rel=icon type=image/png sizes=96x96 href=./icons/favicon-96x96.png><link rel=icon type=image/ico href=./icons/favicon.ico><link rel=apple-touch-icon href=./icons/apple-icon-152x152.png><link rel=apple-touch-icon sizes=152x152 href=./icons/apple-icon-152x152.png><link rel=apple-touch-icon sizes=167x167 href=./icons/apple-icon-167x167.png><link rel=apple-touch-icon sizes=180x180 href=./icons/apple-icon-180x180.png>  <script type="module" crossorigin src="./assets/index-BH-fqmTU.js"></script>
  <link rel="stylesheet" crossorigin href="./assets/index-jjiyEA_O.css">
</head><body><div id=q-app></div></body></html>[victory@virtualizacion-server ~]$

