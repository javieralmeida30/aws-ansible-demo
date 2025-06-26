# Instalación de AWX en macOS

## Prerrequisitos

### 1. Instalar Docker Desktop
```bash
# Usando Homebrew
brew install --cask docker

# O descargar directamente desde: https://www.docker.com/products/docker-desktop/
```

### 2. Habilitar Kubernetes en Docker Desktop
1. Abrir Docker Desktop
2. Ir a **Settings** → **Kubernetes** 
3. Marcar **Enable Kubernetes**
4. Hacer clic en **Apply & Restart**

### 3. Instalar herramientas necesarias
```bash
# Instalar Helm
brew install helm

# Instalar kubectl (si no se instaló con Docker Desktop)
brew install kubectl

# Verificar que Kubernetes funciona
kubectl cluster-info
```

## Instalación de AWX

### 1. Agregar repositorios de Helm
```bash
helm repo add awx-operator https://ansible.github.io/awx-operator/
helm repo add traefik https://helm.traefik.io/traefik
helm repo update
```

### 2. Crear namespace y instalar AWX Operator
```bash
# Crear namespace
kubectl create namespace awx

# Instalar AWX Operator
helm install awx-operator awx-operator/awx-operator \
  -n awx \
  --set 'AWX.enabled=yes'

# Instalar Traefik como ingress controller
helm install traefik traefik/traefik -n awx
```

### 3. Crear archivo de configuración de AWX
```bash
# Crear awx-instance.yaml
cat > awx-instance.yaml << 'EOF'
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-local
  namespace: awx
spec:
  service_type: nodeport
  nodeport_port: 30080
EOF

# Aplicar la configuración
kubectl apply -f awx-instance.yaml
```

### 4. Crear Ingress Route para acceso local
```bash
# Crear awx-ingress.yaml
cat > awx-ingress.yaml << 'EOF'
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: awx-ingressroute
  namespace: awx
spec:
  entryPoints:
    - web
  routes:
    - match: Host(`localhost`) && PathPrefix(`/`)
      kind: Rule
      services:
        - name: awx-local-service
          port: 80
EOF

# Aplicar el ingress
kubectl apply -f awx-ingress.yaml
```

### 5. Esperar a que AWX esté listo
```bash
# Verificar el estado de los pods
kubectl get pods -n awx -w

# Verificar servicios
kubectl get svc -n awx
```

## Acceso a AWX

### Obtener credenciales
```bash
# Usuario: admin
# Obtener contraseña:
kubectl -n awx get secret awx-local-admin-password -o jsonpath='{.data.password}' | base64 -d
```

### Acceder a la interfaz
- URL: http://localhost
- Usuario: `admin`
- Contraseña: (obtenida del comando anterior)

## Eliminación Completa

### Para eliminar completamente AWX sin rastros:

```bash
# 1. Eliminar los recursos de AWX
kubectl delete -f awx-instance.yaml
kubectl delete -f awx-ingress.yaml

# 2. Desinstalar charts de Helm
helm uninstall awx-operator -n awx
helm uninstall traefik -n awx

# 3. Eliminar namespace (esto borra todo)
kubectl delete namespace awx

# 4. Limpiar imágenes Docker (opcional)
docker system prune -a --volumes

# 5. Deshabilitar Kubernetes en Docker Desktop
# Ir a Docker Desktop Settings → Kubernetes → Deshabilitar

# 6. Desinstalar Docker Desktop (si ya no lo necesitas)
# brew uninstall --cask docker
```

## Opción Alternativa: Docker Compose (Más Simple)

Si prefieres algo más directo:

### 1. Crear docker-compose.yml
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:13
    environment:
      POSTGRES_DB: awx
      POSTGRES_USER: awx
      POSTGRES_PASSWORD: awxpass
    volumes:
      - postgres_data:/var/lib/postgresql/data

  awx-web:
    image: quay.io/ansible/awx:latest
    depends_on:
      - postgres
    environment:
      DATABASE_HOST: postgres
      DATABASE_NAME: awx
      DATABASE_USER: awx
      DATABASE_PASSWORD: awxpass
    ports:
      - "8080:8052"
    volumes:
      - awx_projects:/var/lib/awx/projects

volumes:
  postgres_data:
  awx_projects:
```

### 2. Ejecutar
```bash
# Iniciar AWX
docker-compose up -d

# Ver logs
docker-compose logs -f

# Acceder en: http://localhost:8080
```

### 3. Eliminar completamente
```bash
# Parar y eliminar contenedores
docker-compose down -v

# Eliminar imágenes
docker rmi $(docker images -q quay.io/ansible/awx)
docker rmi $(docker images -q postgres:13)

# Limpiar volúmenes
docker volume prune
```

## Consejos Adicionales

### Para desarrollo y testing:
- Usa la primera opción (Kubernetes) si quieres una experiencia más similar a producción
- Usa Docker Compose si solo necesitas probar funcionalidades básicas
- Ambas opciones se pueden eliminar completamente sin dejar rastros

### Recursos del sistema:
- AWX necesita al menos 4GB de RAM libre
- El setup completo ocupará ~2-3GB de espacio en disco
- En Mac M1/M2, todo funciona nativamente

### Persistencia de datos:
- Los datos se almacenan en volúmenes Docker
- Al eliminar con `-v` se borran todos los datos
- Si quieres mantener configuraciones, omite el flag `-v`

¿Te gustaría que proceda con alguna de estas opciones o necesitas más detalles sobre algún paso específico? 