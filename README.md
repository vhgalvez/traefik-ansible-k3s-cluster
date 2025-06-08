# Despliegue de Traefik en K3s con Ansible

Este proyecto instala **Traefik** como controlador de Ingress dentro de un clúster **K3s** utilizando **Helm** y **Ansible**. La instalación incluye:

- Desinstalación de Traefik por defecto (K3s).
- Instalación con Helm (versión 23.1.0).
- Generación de certificados autofirmados.
- Configuración de un VIP para acceso a servicios.
- Autenticación básica en el dashboard vía middleware.

---

## 📦 Estructura del Proyecto

```plaintext
traefik-ansible-k3s-cluster/
├── inventory/hosts.ini               # Inventario Ansible con nodos
├── vars/main.yml                    # Variables globales
├── files/
│   ├── traefik-dashboard-ingressroute.yaml
│   ├── traefik-dashboard-sealed.yaml
│   └── traefik-dashboard-secret.yaml
├── playbooks/
│   ├── deploy_traefik.yml           # Fase 1 y 2: Genera secretos e instala Traefik sin PVC
│   ├── deploy_traefik_pvc.yml       # Fase 3: Instalación final con PVC
│   ├── generate_traefik_secrets.yml
│   ├── install_traefik.yml
│   └── uninstall_traefik.yml
├── templates/
│   ├── secrets/traefik-dashboard-secret.yaml.j2
│   └── traefik/
│       ├── values_nopvc.yaml.j2
│       └── values_pvc.yaml.j2
├── ansible.cfg
└── README.md
```

---

## ⚙️ Requisitos

- Ansible
- Acceso SSH a los nodos (con claves privadas)
- Clúster K3s ya desplegado
- Helm instalado en el nodo de control

---

## 🚀 Flujo de despliegue paso a paso

### 🔐 FASE 1: Generación del Secret sellado (solo una vez)
```bash
ansible-playbook playbooks/generate_traefik_secrets.yml
```

### 🚀 FASE 2: Despliegue inicial sin almacenamiento persistente (pruebas)
```bash
ansible-playbook playbooks/deploy_traefik.yml
```

### 🔄 FASE 3: Reinstalación final con almacenamiento persistente (modo producción)
```bash
ansible-playbook playbooks/deploy_traefik_pvc.yml
```

---

## 🌐 Acceso al Dashboard de Traefik

- **URL:** `https://<second_vip>/dashboard/`
- **Usuario:** `admin`
- **Contraseña:** la definida en `htpasswd.txt`

---

## 🛠 Configuración avanzada

### Certificados reales de Let's Encrypt

Para usar certificados reales, cambia la URL del CA de staging por:
```plaintext
https://acme-v02.api.letsencrypt.org/directory
```

### Generación de archivo `htpasswd.txt`

**Opción recomendada (con htpasswd):**
```bash
htpasswd -nb admin MiPasswordSegura > files/htpasswd.txt
```

**Opción alternativa (Python):**
```bash
python3 -c "import crypt; print('admin:' + crypt.crypt('MiPasswordSegura', crypt.mksalt(crypt.METHOD_MD5)))"
```

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

### CoreDNS externo (infra-cluster)
- **IP:** 10.17.3.11
- Configurado con hosts locales `.cefaslocalserver.com`

### CoreDNS interno (K3s)
- Resuelve servicios `.svc.cluster.local`

---

## 🔒 Seguridad y buenas prácticas

| Tipo de Servicio                     | Exposición                              | Protección Necesaria                          |
|--------------------------------------|-----------------------------------------|-----------------------------------------------|
| **Público** (NGINX, APIs públicas)   | A través de Ingress (Traefik) + VIP     | HTTPS, dominios wildcard, firewall           |
| **Interno** (Traefik UI, Admin APIs) | Solo en VPN/LAN o IP filtrada           | `htpasswd`, firewall, certificados TLS cliente |
| **Base de datos / servicios internos** | Solo `ClusterIP`                        | Sin Ingress                                   |

---

## ✅ Detalles Técnicos

- **Certificados:** autofirmados wildcard `*.cefaslocalserver.com`
- **Log:** nivel `DEBUG`
- **Proveedores activados:** `kubernetesIngress`, `kubernetesCRD`
- **Puertos:** 80, 443 (Traefik), 8080 (dashboard opcional)
- **Recursos:** 1 pod, 100m CPU, 128Mi RAM (ajustable)

---

## 🧠 Qué resuelve este setup

| Problema                          | Solución                                   |
|-----------------------------------|-------------------------------------------|
| No tienes dominio público real    | Dominio local `cefaslocalserver.com`      |
| Necesitas HTTPS                   | Certificados autofirmados wildcard        |
| Tienes múltiples subdominios      | `*.cefaslocalserver.com`                  |
| Quieres enrutar servicios internos| Traefik + IngressRoute + Middleware       |
| DNS interno                       | CoreDNS con resolución LAN                |

---

## 🗂️ Componentes clave

- `values_pvc.yaml.j2`: configuración final con almacenamiento
- `generate_traefik_secrets.yml`: generación y cifrado del Secret (Fase 1)
- `deploy_traefik.yml`: despliegue sin PVC (Fase 2)
- `deploy_traefik_pvc.yml`: despliegue con PVC (Fase 3, final)
- `/ssl/`: certificados TLS autofirmados
- `CoreDNS`: DNS local para el dominio `.cefaslocalserver.com`
