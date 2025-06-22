#!/bin/bash

# Nombre del namespace y release de Traefik (ajustar si usas otros)
NAMESPACE="kube-system"
RELEASE_NAME="traefik"
USER="admin"
PASS="SuperPassword123"
DASHBOARD_URL="https://traefik.socialdevs.site/dashboard/"

echo "🔍 Verificando pod de Traefik..."
kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name="$RELEASE_NAME"

echo -e "\n📄 Logs del Deployment de Traefik (últimas 20 líneas):"
kubectl logs -n "$NAMESPACE" deploy/$RELEASE_NAME --tail=20

echo -e "\n🌐 Servicios expuestos:"
kubectl get svc -n "$NAMESPACE" -l app.kubernetes.io/name="$RELEASE_NAME"

echo -e "\n🔗 Endpoints conectados:"
kubectl get endpoints -n "$NAMESPACE" $RELEASE_NAME

echo -e "\n💾 PVC (almacenamiento persistente):"
kubectl get pvc -n "$NAMESPACE"

echo -e "\n📁 Archivos de certificados dentro del pod (si está corriendo):"
POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name="$RELEASE_NAME" -o jsonpath="{.items[0].metadata.name}")
kubectl exec -n "$NAMESPACE" "$POD_NAME" -- ls -l /etc/traefik/certs || echo "❌ No se pudo acceder a /etc/traefik/certs"

echo -e "\n🧪 Acceso HTTPS al dashboard (curl -k)..."
curl -sk -u "$USER:$PASS" "$DASHBOARD_URL" | grep -i '<title>\|Traefik'

echo -e "\n✅ Verificación terminada."