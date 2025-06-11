# 📦 Proyecto: Traefik Ansible K3s Cluster

Este proyecto automatiza la instalación y configuración de **Traefik como Ingress Controller** en un clúcster Kubernetes K3s de alta disponibilidad, utilizando **Helm y Ansible**, con enfoque profesional, seguro y modular.

---

## 🎯 Objetivo Principal

> Desplegar un entorno seguro y automatizado de Traefik en K3s con soporte para:
>
> * HTTPS vía Let's Encrypt (público)
> * TLS autofirmado para dominios internos (privado)
> * Dashboard seguro con autenticación
> * IngressRoutes separados por contexto
> * Buenas prácticas DevOps, GitOps y seguridad

---

## 📁 Estructura del Proyecto

```
traefik-ansible-k3s-cluster/
├── ansible.cfg
├── inventory/                # Inventario Ansible
│   └── hosts.ini
├── LICENSE
├── playbooks/               # Playbooks automatizados
│   ├── apply_ingress_and_middlewares.yml
│   ├── deploy_traefik.yml
│   ├── deploy_traefik_pvc.yml
│   ├── generate_certs.yml
│   ├── generate_internal_tls_secrets.yml
│   ├── generate_traefik_secrets.yml
│   ├── install_traefik.yml
│   ├── uninstall_traefik.yml
│   └── files/               # YAMLs estáticos (sellados)
│       ├── traefik-dashboard-ingressroute.yaml
│       ├── traefik-dashboard-middleware.yaml
│       ├── traefik-dashboard-sealed.yaml
│       └── traefik-dashboard-secret.yaml
├── templates/               # Plantillas Jinja2 renderizables
│   ├── secrets/
│   │   ├── tls-secret.yaml.j2
│   │   └── traefik-dashboard-secret.yaml.j2
│   └── traefik/
│       ├── ingressroute-internal.yaml.j2
│       ├── ingressroute-public.yaml.j2
│       ├── traefik-dashboard-ingressroute.yaml.j2
│       ├── traefik-dashboard-middleware.yaml.j2
│       ├── middleware-secure-headers.yaml.j2
│       ├── values_nopvc.yaml.j2
│       └── values_pvc.yaml.j2
├── vars/
│   └── main.yml             # Variables globales centralizadas
├── README.md
└── SUMMARY.md               # (Este archivo)
```

---

## 🔧 Funcionalidades Clave

### 🔹 Helm Chart Profesional

* Versión configurable: `traefik_chart_version: "36.0.0"`
* Modos con y sin almacenamiento persistente (PVC / no-PVC)
* Opciones en `values_pvc.yaml.j2` y `values_nopvc.yaml.j2`

### 🔹 IngressRoutes

* **Público (`ingressroute-public.yaml.j2`)** con `certResolver: letsencrypt`
* **Interno (`ingressroute-internal.yaml.j2`)** con `tls.secretName`
* Separación clara entre tráfico externo e interno

### 🔹 Seguridad y Headers

* Middleware `secure-headers` para CSP y headers seguros
* Redirección HTTP → HTTPS activada

### 🔹 Dashboard de Traefik Seguro

* `traefik-dashboard-ingressroute.yaml.j2` solo accesible desde LAN/VPN
* Protegido con autenticación básica (secret gestionado)

### 🔹 Certificados

* TLS autofirmado (interno) con secret `internal_tls_secret_name`
* Let's Encrypt (externo) por dominio vía ACME + certResolver
* Secrets creados y sellados mediante Sealed Secrets opcionalmente

---

## 🔐 Seguridad

* Uso de BasicAuth para el Dashboard
* Headers seguros
* Certificados diferenciados por entorno (externo/público, interno)
* Dashboard no expuesto a Internet
* Separación de permisos y nombres de middleware por namespace

---

## 📌 Requisitos Previos

* Kubernetes K3s en ejecución con acceso a `kubectl` y `helm`
* Nodo de control o bastión con Ansible instalado
* Acceso al clúcster via kubeconfig

---

## 🚀 Ejecución Rápida (ejemplo)

## 📞 Contacto / Mantenimiento

Este proyecto es mantenido por [vhgalvez](https://github.com/vhgalvez) como parte del ecosistema **FlatcarMicroCloud** para entornos bare-metal con K3s y automatización total.

> 🌟 Licencia MIT - Uso libre con crédito al autor

---

## ✅ Estado

| Componente               | Estado |
| ------------------------ | ------ |
| Traefik instalado        | ✅      |
| Dashboard seguro         | ✅      |
| HTTPS con Let's Encrypt  | ✅      |
| TLS interno              | ✅      |
| IngressRoute interno     | ✅      |
| IngressRoute público     | ✅      |
| Middleware de headers    | ✅      |
| Helm + Ansible funcional | ✅      |
