#!/bin/bash
set -euo pipefail

echo "=== Deploy Backend - $(date) ==="

cd /opt/simit

# Cargar variables de entorno
if [ -f .env.production ]; then
    export $(grep -v '^#' .env.production | xargs)
fi

# Login a ECR
echo "Logging into ECR..."
aws ecr get-login-password --region ${AWS_REGION:-us-east-1} | \
    docker login --username AWS --password-stdin ${ECR_REGISTRY}

# Pull imagenes actualizadas
echo "Pulling latest images..."
docker compose -f docker-compose.prod.yml pull backend

# Detener contenedores anteriores
echo "Stopping old containers..."
docker compose -f docker-compose.prod.yml down

# Iniciar nuevos contenedores
echo "Starting new containers..."
docker compose -f docker-compose.prod.yml up -d

# Esperar a que el backend este listo
echo "Waiting for backend to be ready..."
sleep 15

# Verificar que el contenedor esta corriendo
if docker compose -f docker-compose.prod.yml ps backend | grep -q "Up"; then
    echo "Backend is running!"
else
    echo "ERROR: Backend failed to start"
    docker compose -f docker-compose.prod.yml logs backend
    exit 1
fi

# Ejecutar migraciones (opcional, Supabase maneja las migraciones)
# docker compose -f docker-compose.prod.yml exec -T backend php artisan migrate --force

# Limpiar cache
echo "Clearing cache..."
docker compose -f docker-compose.prod.yml exec -T backend php artisan config:cache 2>/dev/null || true
docker compose -f docker-compose.prod.yml exec -T backend php artisan route:cache 2>/dev/null || true
docker compose -f docker-compose.prod.yml exec -T backend php artisan view:cache 2>/dev/null || true

# Limpiar imagenes viejas
echo "Cleaning old Docker images..."
docker image prune -f

echo "=== Deploy Backend completed ==="
