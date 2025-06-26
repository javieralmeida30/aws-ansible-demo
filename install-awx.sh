#!/bin/bash

echo "🚀 Instalando AWX en Kubernetes local..."

# Verificar que Kubernetes está funcionando
echo "📋 Verificando Kubernetes..."
if ! kubectl cluster-info > /dev/null 2>&1; then
    echo "❌ Error: Kubernetes no está disponible. Asegúrate de que esté habilitado en Docker Desktop."
    exit 1
fi

echo "✅ Kubernetes está funcionando"

# Agregar repositorios de Helm
echo "📦 Agregando repositorios de Helm..."
helm repo add awx-operator-helm https://ansible-community.github.io/awx-operator-helm/
helm repo add traefik https://helm.traefik.io/traefik
helm repo update

# Crear namespace
echo "🏗️ Creando namespace 'awx'..."
kubectl create namespace awx --dry-run=client -o yaml | kubectl apply -f -

# Instalar AWX Operator
echo "🔧 Instalando AWX Operator..."
helm upgrade --install awx-operator awx-operator-helm/awx-operator \
  -n awx \
  --wait

# Instalar Traefik
echo "🌐 Instalando Traefik (Ingress Controller)..."
helm upgrade --install traefik traefik/traefik -n awx --wait

# Aplicar configuración de AWX
echo "⚙️ Desplegando instancia de AWX..."
kubectl apply -f awx-instance.yaml

# Aplicar ingress
echo "🔗 Configurando ingress..."
kubectl apply -f awx-ingress.yaml

echo "⏳ Esperando a que AWX esté listo..."
echo "Esto puede tomar 5-10 minutos..."

# Esperar a que AWX esté listo
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=awx-local -n awx --timeout=600s

echo ""
echo "🎉 ¡AWX instalado exitosamente!"
echo ""
echo "📋 Información de acceso:"
echo "🌐 URL: http://localhost"
echo "👤 Usuario: admin"
echo "🔑 Contraseña: (ejecuta el siguiente comando)"
echo ""
echo "   kubectl -n awx get secret awx-local-admin-password -o jsonpath='{.data.password}' | base64 -d"
echo ""
echo "📊 Para monitorear el progreso:"
echo "   kubectl get pods -n awx -w"
echo ""
echo "🗑️ Para eliminar AWX completamente:"
echo "   kubectl delete namespace awx" 