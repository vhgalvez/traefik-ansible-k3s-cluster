# 📄 Summary - Traefik Ansible K3s Cluster

Este proyecto instala y gestiona **Traefik** como controlador de Ingress en un clúster **K3s**, con enfoque en:

- Seguridad (certificados TLS internos y/o Let's Encrypt)
- Almacenamiento persistente (PVC con Longhorn)
- Acceso controlado (auth básica + VPN)
- Acceso público a través de Cloudflare + IP dinámica

---

## 📦 Fases del Despliegue

### 🔐 Fase 1 – Preparación de certificados y secretos

1. `1-generate-selfsigned-certs.yml`  
   → Genera certificados autofirmados `*.socialdevs.site` en `files/certs/`

2. `2-generate-internal-tls-cert.yml`  
   → Crea un Secret TLS con los certificados anteriores, en `kube-system`

3. `3-seal-traefik-auth-secret.yml`  
   → Cifra el secreto de acceso al dashboard con `kubeseal`

---

### 🚀 Fase 2 – Despliegue de Traefik

4. `4-install-traefik-dashboard.yml`  
   → Instala Traefik vía Helm, usando el chart `traefik/traefik` y valores customizados desde plantilla

5. `deploy_traefik.yml`  
   → Orquesta las fases anteriores para un despliegue inicial sin almacenamiento persistente

---

### 📦 Fase 3 – Certificado desde PVC y TLSStore global

6. `2a-create-cert-pvc.yml`  
   → Copia los certificados a un PVC Longhorn y crea un Secret TLS compartido

7. `values_pvc.yaml.j2`  
   → Define el `tlsStore.default` apuntando al Secret almacenado en `kube-system`

8. `deploy_traefik_pvc.yml`  
   → Reinstala Traefik usando configuración persistente con PVC y TLS global

---

### 🧹 Fase Final – Desinstalación

9. `uninstall-traefik-dashboard.yml`  
   → Borra Helm release, secretos, CRDs, y limpia puertos

---

## 🌐 Red y Exposición

- Cloudflare + DDNS → IP dinámica pública
- Router doméstico redirige puertos 80/443 a `VIP` (192.168.0.33)
- HAProxy + Keepalived redirige a pods de Traefik
- VPN WireGuard permite acceso administrativo

---

## 🔒 Seguridad

- Acceso al dashboard protegido por autenticación HTTP básica (`htpasswd`)
- Certificados TLS internos y wildcard
- Secrets cifrados con SealedSecrets
- Firewall basado en `nftables`

---

## 📂 Estructura de Archivos

- `playbooks/` → Todas las fases automatizadas con Ansible
- `templates/` → YAMLs renderizados para Traefik y secrets
- `files/certs/` → Certificados autofirmados
- `vars/main.yml` → Configuración reutilizable global
- `README.md` → Documentación extendida
- `Summary.md` → Resumen estructurado (este archivo)

---

## ✅ Estado Actual

Traefik se despliega automáticamente con:

- Dashboard seguro (`/dashboard`)
- TLS wildcard funcional para dominios internos
- Opción de Let's Encrypt para producción
- Certificados desde PVC con sincronización multi-namespace
- Integración Cloudflare y WireGuard
