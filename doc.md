🧭 Plan Teórico de Implementación del Proyecto de Ingress con Traefik
🎯 Objetivo General
Implementar una solución escalable y segura de ingress con Traefik sobre Kubernetes (K3s), diferenciando claramente entre servicios internos (privados) y externos (públicos), usando certificados autofirmados en LAN y certificados Let's Encrypt para dominios reales.

✅ 1. Clasificación de Dominios
🔐 Dominios Privados (Internos/LAN)
Estos dominios solo se acceden desde la red interna. No están expuestos a Internet ni necesitan DNS público.

Ejemplos:

traefik.socialdevs.site

grafana.socialdevs.site

prometheus.socialdevs.site

argocd.socialdevs.site

jenkins.socialdevs.site

nginx.socialdevs.site

longhorn.socialdevs.site

Características:

No requieren conexión a Internet.

Se aseguran con certificados autofirmados.

Se configuran mediante IngressRoute con etiqueta access: internal.

Se sirven por HTTPS en LAN (entryPoint: websecure).

El certificado se monta desde un secreto llamado internal-tls-secret.

🌍 Dominios Públicos (Expuestos a Internet)
Estos dominios apuntan a la IP pública del balanceador o clúster y requieren certificados válidos.

Ejemplos:

socialdevs.site

public.socialdevs.site

Características:

Necesitan un DNS real y resolución externa.

Se aseguran con certificados válidos vía Let's Encrypt (ACME).

Se configuran mediante IngressRoute con etiqueta access: public.

El certResolver permite a Traefik gestionar los certificados automáticamente.

Requieren persistencia habilitada (/data) para almacenar los certificados emitidos.

📐 Resumen Arquitectónico
Tipo de Dominio	Ejemplos	Certificado	Uso de TLS	EntryPoint
🔐 Privado	grafana.socialdevs.site	Autofirmado	internal-tls-secret	websecure
🌍 Público	public.socialdevs.site	Let's Encrypt (ACME)	Automático	websecure

🔄 Flujo de Implementación (3 Fases)
🔹 Fase 1 – traefik-ansible-k3s-cluster (Modo sin PVC)
Objetivo: Instalar Traefik con certificados autofirmados para acceso seguro en entorno local.

Implementa Traefik usando configuración sin almacenamiento persistente.

Se habilita HTTPS en LAN (entryPoint websecure) con certificados locales.

Se protege el dashboard con autenticación básica.

No se usa Let's Encrypt ni resolvers.

Ideal para pruebas internas y verificación de red.

🔐 Beneficio: Puedes comenzar a usar Traefik en minutos sin requerir almacenamiento ni DNS público.

🔹 Fase 2 – flatcar-k3s-storage-suite
Objetivo: Instalar Longhorn (u otra solución de almacenamiento) para habilitar volúmenes persistentes en el clúster.

Se despliega Longhorn o NFS como sistema de almacenamiento distribuido.

Se configura la StorageClass por defecto.

Se validan los volúmenes y se verifica su disponibilidad.

(Opcional) Se realiza una prueba con un PVC sencillo.

📦 Beneficio: Prepara el entorno para que Traefik almacene certificados reales de forma segura y persistente.

🔹 Fase 3 – traefik-ansible-k3s-cluster (Modo con PVC)
Objetivo: Reinstalar o actualizar Traefik para usar certificados Let's Encrypt.

Se activa la persistencia (/data) para certificados dinámicos.

Se configura el certResolver para Let's Encrypt (ACME).

Se reemplazan los certificados autofirmados por certificados reales.

Se mantienen las rutas y autenticaciones previas.

Se aseguran todos los servicios públicos con certificados válidos.

🔒 Beneficio: Traefik queda listo para producción con HTTPS real en servicios públicos, sin intervención manual en certificados.

🧠 Esquema de Flujo General
scss
Copiar
Editar
1️⃣ traefik-ansible-k3s-cluster (🔐 HTTPS interno, sin PVC)
          ↓
2️⃣ flatcar-k3s-storage-suite (📦 instalación de Longhorn)
          ↓
3️⃣ traefik-ansible-k3s-cluster (🔒 Let's Encrypt + PVC)
📌 Buenas Prácticas Clave
Usar etiquetas en los IngressRoute (access: internal o access: public) para organizarlos visualmente.

Nunca usar certificados autofirmados en dominios expuestos públicamente.

No usar resolvers públicos en ambientes internos.

Separar claramente IngressRoute internos y públicos.

Usar nodeSelector o affinity si necesitas ubicar Traefik en un nodo específico.

