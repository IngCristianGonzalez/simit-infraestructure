# Simit Infrastructure

Repositorio de infraestructura y CI/CD para el proyecto Simit.

## Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│                      AWS Cloud                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────┐    ┌──────────────────────────────┐   │
│  │ CloudFront  │───▶│ S3 (Frontend Angular)         │   │
│  │   (CDN)     │    │                               │   │
│  └─────────────┘    └──────────────────────────────┘   │
│         │                                               │
│         │ API Calls                                    │
│         ▼                                               │
│  ┌──────────────────────────────────────────────────┐  │
│  │                EC2 Instance                       │  │
│  │  ┌────────────────────────────────────────────┐  │  │
│  │  │  Docker Compose                            │  │  │
│  │  │                                            │  │  │
│  │  │  ┌─────────┐  ┌─────────┐                 │  │  │
│  │  │  │  Nginx  │  │ Backend │                 │  │  │
│  │  │  │  :443   │  │  :9000  │                 │  │  │
│  │  │  └─────────┘  └─────────┘                 │  │  │
│  │  └────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │              Supabase Cloud                       │  │
│  │  ┌─────────────┐  ┌─────────────┐               │  │
│  │  │  PostgreSQL  │  │    Auth     │               │  │
│  │  │   (DB)       │  │   (JWT)     │               │  │
│  │  └─────────────┘  └─────────────┘               │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Stack Tecnológico

| Componente | Tecnología |
|------------|------------|
| Frontend | Angular 20, SCSS, Tailwind, Bootstrap |
| Backend | Laravel 11, PHP 8.2 |
| Base de datos | Supabase PostgreSQL |
| Autenticación | Supabase Auth (JWT) |
| Infraestructura | AWS EC2, S3, CloudFront |
| CI/CD | GitHub Actions |
| Containers | Docker, Docker Compose |

## Repositorios

| Repositorio | Descripción |
|-------------|-------------|
| `proyecto-simit-frontend` | Frontend Angular |
| `proyecto-simit-service` | Backend Laravel |
| `simit-infraestructure` | Infraestructura y CI/CD (este repo) |

---

## Setup Inicial

### 1. Supabase

Asegúrate de tener un proyecto en Supabase con:

1. **PostgreSQL Database**: Tablas creadas y migradas
2. **Auth**: Habilitado con los métodos deseados (email, magic link, etc.)
3. **Connection String**: Copiar el connection string del pooler:
   - Ve a Settings → Database → Connection string → Transaction mode
   - Formato: `postgresql://postgres.[ref]:[password]@aws-0-[region].pooler.supabase.com:6543/postgres`

### 2. EC2 Instance

```bash
# Conectar a la EC2
ssh -i your-key.pem ubuntu@your-ec2-ip

# Ejecutar setup
git clone https://github.com/TU_USUARIO/simit-infraestructure.git
cd simit-infraestructure
sudo bash scripts/setup-ec2.sh
```

### 3. SSL Certificates (Let's Encrypt)

```bash
# Instalar certbot
sudo apt-get install -y certbot

# Obtener certificado (parar nginx temporalmente)
sudo docker stop simit-nginx
sudo certbot certonly --standalone -d api.tudominio.com

# Copiar certificados
sudo mkdir -p /opt/simit/nginx/ssl
sudo cp /etc/letsencrypt/live/api.tudominio.com/fullchain.pem /opt/simit/nginx/ssl/
sudo cp /etc/letsencrypt/live/api.tudominio.com/privkey.pem /opt/simit/nginx/ssl/

# Reiniciar nginx
sudo docker start simit-nginx
```

### 4. AWS S3 + CloudFront (Frontend)

```bash
# Crear bucket S3
aws s3 mb s3://simit-frontend-tu-ambiente

# Configurar website hosting
aws s3 website s3://simit-frontend-tu-ambiente \
  --index-document index.html \
  --error-document index.html

# Crear CloudFront distribution
aws cloudfront create-distribution \
  --origin-domain-name simit-frontend-tu-ambiente.s3.amazonaws.com \
  --default-root-object index.html \
  --viewer-protocol-policy redirect-to-https
```

### 5. ECR Repository (Backend)

```bash
# Crear repositorio ECR
aws ecr create-repository --repository-name simit-backend

# Login
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
```

### 6. GitHub Secrets

#### Repo: `simit-infraestructure`

| Secret | Valor |
|--------|-------|
| `EC2_HOST` | IP pública de la EC2 |
| `EC2_USER` | `ubuntu` |
| `EC2_SSH_KEY` | Contenido del archivo `.pem` |

#### Repo: `proyecto-simit-frontend`

| Secret | Valor |
|--------|-------|
| `AWS_ACCESS_KEY_ID` | Access key de AWS |
| `AWS_SECRET_ACCESS_KEY` | Secret key de AWS |
| `AWS_REGION` | `us-east-1` |
| `S3_BUCKET` | Nombre del bucket S3 |
| `CLOUDFRONT_DISTRIBUTION_ID` | ID de CloudFront |
| `FRONTEND_DOMAIN` | `www.tudominio.com` |
| `FRONTEND_REPO` | `TU_USUARIO/proyecto-simit-frontend` |
| `API_URL` | `https://api.tudominio.com/api` |

#### Repo: `proyecto-simit-service`

| Secret | Valor |
|--------|-------|
| `ECR_REGISTRY` | `ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com` |
| `AWS_REGION` | `us-east-1` |

---

## Variables de Entorno Backend (`.env.production`)

```bash
# App
APP_NAME=Simit
APP_ENV=production
APP_KEY=base64:GENERAR_CON_php_artisan_key_generate
APP_DEBUG=false
APP_URL=https://api.tudominio.com

# Supabase PostgreSQL
DB_CONNECTION=pgsql
DB_HOST=aws-0-us-east-1.pooler.supabase.com
DB_PORT=6543
DB_DATABASE=postgres
DB_USERNAME=postgres.TU_PROJECT_REF
DB_PASSWORD=tu_password_supabase

# Supabase Auth
SUPABASE_URL=https://TU_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=tu_anon_key
SUPABASE_JWT_SECRET=tu_jwt_secret
SUPABASE_SERVICE_ROLE_KEY=tu_service_role_key

# Sesiones
SESSION_DRIVER=database
CACHE_STORE=database
QUEUE_CONNECTION=database

# Mail
MAIL_MAILER=smtp
MAIL_HOST=smtp-relay.brevo.com
MAIL_PORT=587
MAIL_USERNAME=tu_usuario
MAIL_PASSWORD=tu_password
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS="notificaciones@simit.gov.co"
MAIL_FROM_NAME="${APP_NAME}"
```

---

## Deploy

### Automático (CI/CD)

Cada push a `main` ejecuta el deploy automáticamente:

```bash
git push origin main
```

### Manual

```bash
# Conectar a EC2
ssh -i your-key.pem ubuntu@your-ec2-ip

# Deploy backend
cd /opt/simit
bash scripts/deploy-backend.sh

# Deploy frontend (desde tu maquina local)
cd proyecto-simit-frontend
npm run build -- --configuration production
aws s3 sync dist/proyecto-simit-browser s3://tu-bucket --delete
aws cloudfront create-invalidation --distribution-id TU_ID --paths "/*"
```

---

## Comandos Útiles

```bash
# Ver logs del backend
docker compose -f docker-compose.prod.yml logs -f backend

# Reiniciar servicios
docker compose -f docker-compose.prod.yml restart

# Actualizar backend
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d

# Shell dentro del contenedor
docker compose -f docker-compose.prod.yml exec backend bash

# Ejecutar artisan
docker compose -f docker-compose.prod.yml exec backend php artisan [command]
```

---

## Estructura del Repo

```
simit-infraestructure/
├── .github/workflows/
│   ├── deploy-backend.yml    # CI/CD backend → EC2
│   └── deploy-frontend.yml   # CI/CD frontend → S3/CloudFront
├── nginx/
│   └── default.conf          # Nginx reverse proxy con SSL
├── scripts/
│   ├── deploy-backend.sh     # Script de deploy en EC2
│   └── setup-ec2.sh          # Setup inicial de la EC2
├── envs/
│   ├── .env.backend.example  # Variables de entorno backend
│   ├── .env.frontend.example # Variables de entorno frontend
│   └── github-secrets.example
├── docker-compose.prod.yml   # Backend + Nginx
├── frontend.Dockerfile       # Dockerfile para Angular
├── nginx-frontend.conf       # Nginx config para Angular
└── README.md
```

---

## Troubleshooting

### Backend no inicia

```bash
docker compose -f docker-compose.prod.yml logs backend
# Verificar variables de entorno en .env.production
```

### Error de conexion a Supabase

```bash
# Verificar que el host de Supabase es accesible desde EC2
docker compose -f docker-compose.prod.yml exec backend ping aws-0-us-east-1.pooler.supabase.com
```

### Frontend no carga

```bash
# Verificar S3 bucket
aws s3 ls s3://tu-bucket

# Verificar CloudFront
aws cloudfront get-distribution --id TU_DISTRIBUTION_ID
```

### SSL no funciona

```bash
# Verificar certificados
ls -la /opt/simit/nginx/ssl/

# Verificar nginx config
docker compose -f docker-compose.prod.yml exec nginx nginx -t
```
