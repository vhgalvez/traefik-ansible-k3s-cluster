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

___________

Este proyecto está diseñado para automatizar la instalación, configuración y gestión de Traefik como un Ingress Controller en un clúster de Kubernetes, asegurando tanto el acceso HTTP como HTTPS para los servicios dentro del clúster. Además, también gestiona el acceso seguro al dashboard de Traefik a través de autenticación básica y el almacenamiento de certificados TLS de manera persistente. A continuación, se detallan los componentes clave y su funcionamiento:

Objetivo Principal del Proyecto:
Automatizar el despliegue de Traefik en un clúster de Kubernetes con una configuración segura, optimizada y persistente, incluyendo:

La generación y almacenamiento de certificados TLS para tráfico HTTPS.

La instalación de Traefik Dashboard con autenticación básica.

La persistencia de certificados usando Longhorn.

La automatización completa de este proceso usando Ansible y Helm.

Componentes y Funcionalidad:
1. Generación y Gestión de Certificados TLS:
Certificados Autofirmados y Let's Encrypt:

Se generan certificados TLS autofirmados para uso interno y se configura la automatización para obtener certificados Let's Encrypt mediante el desafío HTTP-01. Esto permite que todas las conexiones HTTPS estén aseguradas.

Los certificados generados incluyen un certificado wildcard (por ejemplo, *.socialdevs.site), lo que permite que cualquier subdominio de ese dominio esté cubierto por el mismo certificado.

Almacenamiento Persistente con Longhorn:

Los certificados TLS se almacenan de forma persistente en un volumen persistente (PVC) gestionado por Longhorn. Este volumen garantiza que los certificados no se pierdan si el pod de Traefik se reinicia o se mueve a otro nodo dentro del clúster.

Persistent Volume Claims (PVCs):

Se crea un PVC que montará el volumen con los certificados dentro del pod de Traefik, garantizando su disponibilidad durante el ciclo de vida de la aplicación.

2. Despliegue de Traefik con Helm:
Traefik como Ingress Controller:

Traefik se instala y configura mediante Helm en el clúster de Kubernetes. Traefik actúa como un Ingress Controller, lo que significa que maneja el tráfico HTTP(S) que entra al clúster, redirigiéndolo a los servicios internos.

El despliegue se realiza con valores específicos para TLS, autenticación y persistencia.

Configuración de IngressRoute:

Se configura un IngressRoute para acceder al dashboard de Traefik, utilizando una ruta protegida por autenticación básica. Esta autenticación asegura que solo los usuarios autorizados puedan acceder al panel de administración de Traefik.

Middleware de Autenticación:

Se genera un middleware que gestiona la autenticación básica para el acceso al dashboard de Traefik, utilizando un Sealed Secret que almacena de manera segura las credenciales (admin:SuperPassword123).

TLSStore Global:

Se configura un TLSStore global en Traefik que hace referencia a los certificados TLS (como wildcard-socialdevs-tls.crt y wildcard-socialdevs-tls.key). Este TLSStore asegura que todos los servicios en el clúster de Kubernetes gestionados por Traefik utilicen el mismo certificado SSL.

3. Autenticación Básica para el Dashboard de Traefik:
El acceso al dashboard de Traefik se asegura con autenticación básica.

El secreto con las credenciales de acceso (admin:SuperPassword123) se crea y se sella utilizando Sealed Secrets, lo que garantiza que las credenciales estén cifradas y solo puedan ser desencriptadas dentro del clúster.

4. Configuración de Certificados y Secrets:
Sealed Secrets:

El uso de Sealed Secrets asegura que los secretos, como las credenciales de autenticación y los certificados TLS, estén protegidos y sean accesibles solo dentro del clúster.

Los secrets sellados se gestionan mediante la herramienta kubeseal, lo que permite almacenar secretos de forma segura y mantenerlos sincronizados con el clúster de Kubernetes.

5. Automatización con Ansible y Helm:
Ansible se utiliza para automatizar todo el proceso, desde la generación de certificados hasta la instalación de Traefik y la configuración de todos los recursos en Kubernetes (como IngressRoute, Secrets, TLSStore, etc.).

Playbooks:

Se crean varios playbooks de Ansible para gestionar cada paso del proceso:

Generación de certificados autofirmados y TLS.

Creación del PVC para almacenar los certificados TLS.

Instalación y configuración de Traefik usando Helm con los valores apropiados.

Generación y aplicación de Secrets para autenticación y TLS.

Verificación del despliegue, asegurando que Traefik esté funcionando correctamente.

Flujo de Trabajo del Proyecto:
Generación de Certificados:

Se generan certificados TLS autofirmados o se obtienen certificados de Let's Encrypt.

Estos certificados se almacenan en un PVC gestionado por Longhorn.

Despliegue de Traefik:

Traefik se instala y configura usando Helm con un archivo de valores (Helm values) que configura los certificados, la autenticación y los servicios expuestos.

Configuración de Autenticación:

Se configura la autenticación básica para el dashboard de Traefik y se genera un Sealed Secret con las credenciales de acceso.

Aplicación de Recursos Kubernetes:

Se crean y aplican los recursos necesarios, como IngressRoute para acceder al dashboard, TLSStore para los certificados y Secrets para la autenticación.

Verificación del Despliegue:

El sistema realiza una verificación para asegurarse de que Traefik esté en funcionamiento y que el acceso al dashboard a través de HTTPS esté configurado correctamente.

Resumen Final:
Este proyecto automatiza la instalación y configuración de Traefik en un clúster de Kubernetes con un enfoque en la seguridad y persistencia. Utiliza Ansible para gestionar todos los recursos necesarios (certificados TLS, IngressRoutes, Secrets, etc.), Helm para desplegar Traefik, y Sealed Secrets para proteger las credenciales y certificados. La solución incluye la configuración de TLS para tráfico HTTPS, la autenticación segura para el dashboard, y la persistencia de los certificados usando Longhorn.