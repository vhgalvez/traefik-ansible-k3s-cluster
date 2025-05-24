# Despliegue de Traefik en K3s con Ansible

Este proyecto instala **Traefik** como controlador de Ingress dentro de un clúster **K3s** utilizando **Helm** y **Ansible**. La instalación incluye:

* Desinstalación de Traefik por defecto (K3s)
* Instalación con Helm (versión 23.1.0)
* Habilitación de HTTPS (TLS) con Let's Encrypt (staging)
* Autenticación básica en el dashboard vía middleware

---

## 📦 Estructura del Proyecto

```
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

* Ansible
* Acceso SSH a los nodos (usando claves privadas)
* Clúster K3s ya desplegado
* Helm instalado en el nodo de control

---

## 🚀 Ejecución paso a paso

1. Edita tu inventario:

   ```ini
   [controller]
   10.17.4.21 ansible_user=core ansible_ssh_private_key_file=/ruta/a/id_rsa ansible_shell_executable=/bin/sh
   ```

2. Asegúrate de tener el archivo `files/htpasswd.txt` con el siguiente contenido generado por `htpasswd`:

   ```bash
   htpasswd -nb admin MiPasswordSegura > files/htpasswd.txt
   ```

3. Ejecuta el playbook:

   ```bash
   ansible-playbook -i inventory.ini playbooks/install_traefik.yml
   ```

4. Accede al Dashboard de Traefik:

   * **URL:** `https://<second_vip>/dashboard/`
   * **Usuario:** `admin`
   * **Contraseña:** la definida en `htpasswd.txt`

---

## ✅ Conclusión

El proyecto `traefik-ansible-k3s-cluster`:

* Está **preparado para producción**, con seguridad (TLS, auth)
* Usa **Helm + Ansible** para mantener un despliegue declarativo y reproducible
* Integra **Middleware**, `IngressRoute`, y auto TLS para prácticas modernas

Puedes modificar el `values.yaml.j2` para añadir balanceo, rate-limiting, certificados personalizados o rutas adicionales según tus necesidades.

---

🛡 Si deseas migrar a certificados reales de Let's Encrypt, cambia la URL del CA de staging por:

```
https://acme-v02.api.letsencrypt.org/directory
```

---

📬 ¿Tienes dudas o necesitas soporte adicional? No dudes en integrarlo con GitOps, monitoreo o alerting en próximos pasos.


✅ Opción 1: Generarlo con htpasswd (recomendado)
📦 Instala apache2-utils (si no lo tienes)
En Debian/Ubuntu:

bash
Copiar
Editar
sudo apt install apache2-utils
En CentOS/RHEL:

bash
Copiar
Editar
sudo yum install httpd-tools
🔐 Genera el archivo htpasswd.txt:
bash
Copiar
Editar
htpasswd -nb admin MiPasswordSegura
Esto generará una línea como:

perl
Copiar
Editar
admin:$apr1$ZAxMN7AB$FfjW5g0iTnEKRW7s3gZpQ0
📁 Guarda este contenido en el archivo files/htpasswd.txt para que Ansible lo use.

🧪 Opción 2: Usar Python puro (sin instalar nada más)
bash
Copiar
Editar
python3 -c "import crypt; print('admin:' + crypt.crypt('MiPasswordSegura', crypt.mksalt(crypt.METHOD_MD5)))"
Resultado:

perl
Copiar
Editar
admin:$1$PN1nq...$JYTCdWk5id8NIVRSfT/4G0
📁 También lo puedes guardar en files/htpasswd.txt.

📄 Recomendación
Tu archivo htpasswd.txt debe tener una única línea así:

perl
Copiar
Editar
admin:$apr1$ZAxMN7AB$FfjW5g0iTnEKRW7s3gZpQ0
Y lo usas en Ansible con:

yaml
Copiar
Editar
users: {{ lookup('file', '../files/htpasswd.txt') | b64encode }}
¿Quieres que te genere ahora mismo el contenido para un usuario y contraseña que me indiques (ej. admin / admin123) para que lo pegues en tu archivo?






Tú dijiste:
esto lo puede hacer pythoy en usando localhost
python3 -c "import crypt; print('admin:' + crypt.crypt('MiPasswordSegura', crypt.mksalt(crypt.METHOD_MD5)))"


ChatGPT Plus
✅ Sí, exactamente. Ese comando en Python 3 ejecutado desde localhost:

bash
Copiar
Editar
python3 -c "import crypt; print('admin:' + crypt.crypt('MiPasswordSegura', crypt.mksalt(crypt.METHOD_MD5)))"
👉 Te genera una línea htpasswd válida para Traefik con autenticación básica.
El resultado se verá como:

perl
Copiar
Editar
admin:$1$PN1nq...$JYTCdWk5id8NIVRSfT/4G0
📁 ¿Qué hacer luego?
Crea el archivo files/htpasswd.txt en tu proyecto Ansible:

bash
Copiar
Editar
echo "admin:$1$PN1nq...$JYTCdWk5id8NIVRSfT/4G0" > files/htpasswd.txt
Verifica que Ansible lo pueda leer:

yaml
Copiar
Editar
users: {{ lookup('file', '../files/htpasswd.txt') | b64encode }}
🛡 ¿Por qué usar crypt.METHOD_MD5?
Es compatible con el formato $apr1$, que es el esperado por la mayoría de servicios que implementan htpasswd, como Apache, Traefik, NGINX, etc.

Si necesitas un hash más fuerte (bcrypt o SHA), se requiere una librería externa (passlib), pero para la mayoría de casos con Traefik, crypt es suficiente y funciona bien.