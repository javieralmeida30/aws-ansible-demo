#!/bin/bash

echo "🗑️ Eliminando AWX completamente..."

# Eliminar namespace (esto elimina todos los recursos)
echo "📦 Eliminando namespace 'awx'..."
kubectl delete namespace awx --ignore-not-found=true

# Desinstalar charts de Helm (por si acaso)
echo "🔧 Eliminando charts de Helm..."
helm uninstall awx-operator -n awx 2>/dev/null || true
helm uninstall traefik -n awx 2>/dev/null || true

# Eliminar repositorios de Helm
echo "📚 Eliminando repositorios de Helm..."
helm repo remove awx-operator-helm 2>/dev/null || true
helm repo remove traefik 2>/dev/null || true

# Limpiar imágenes Docker (opcional)
echo "🧹 Limpiando imágenes Docker..."
docker system prune -f

echo ""
echo "✅ AWX eliminado completamente"
echo ""
echo "💡 Para eliminar también las imágenes Docker:"
echo "   docker system prune -a --volumes"
echo ""
echo "🔧 Para deshabilitar Kubernetes:"
echo "   Ve a Docker Desktop → Settings → Kubernetes → Deshabilitar" 