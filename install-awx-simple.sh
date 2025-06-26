#!/bin/bash

echo "🚀 Instalando AWX en Kubernetes local (Método 2025)..."

# Verificar que Kubernetes está funcionando
echo "📋 Verificando Kubernetes..."
if ! kubectl cluster-info > /dev/null 2>&1; then
    echo "❌ Error: Kubernetes no está disponible. Asegúrate de que esté habilitado en Docker Desktop."
    exit 1
fi

echo "✅ Kubernetes está funcionando"

# Crear namespace
echo "🏗️ Creando namespace 'awx'..."
kubectl create namespace awx --dry-run=client -o yaml | kubectl apply -f -

# Usar Kustomize para instalar AWX Operator (método oficial 2025)
echo "🔧 Instalando AWX Operator usando Kustomize..."
kubectl apply -k https://github.com/ansible/awx-operator/config/default?ref=2.19.1

echo "⏳ Esperando a que el operador esté listo..."
kubectl wait --for=condition=Available deployment/awx-operator-controller-manager -n awx-system --timeout=300s

# Aplicar configuración de AWX
echo "⚙️ Desplegando instancia de AWX..."
kubectl apply -f awx-instance.yaml

echo "⏳ Esperando a que AWX esté listo..."
echo "Esto puede tomar 5-10 minutos..."

# Esperar a que AWX esté listo
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=awx-local -n awx --timeout=600s

# Configurar acceso por NodePort
echo "🔗 Configurando acceso por NodePort..."
kubectl patch svc awx-local-service -n awx -p '{"spec": {"type": "NodePort", "ports": [{"port": 80, "targetPort": 8052, "protocol": "TCP", "nodePort": 30080}]}}'

echo ""
echo "🎉 ¡AWX instalado exitosamente!"
echo ""
echo "📋 Información de acceso:"
echo "🌐 URL: http://localhost:30080"
echo "👤 Usuario: admin"
echo "🔑 Para obtener la contraseña:"
echo ""
echo "   kubectl -n awx get secret awx-local-admin-password -o jsonpath='{.data.password}' | base64 -d"
echo ""
echo "📊 Para monitorear el progreso:"
echo "   kubectl get pods -n awx -w"
echo ""
echo "🗑️ Para eliminar AWX completamente:"
echo "   kubectl delete namespace awx"
echo "   kubectl delete -k https://github.com/ansible/awx-operator/config/default?ref=2.19.1" 