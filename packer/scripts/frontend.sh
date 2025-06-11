#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

# =============================
# VARIABLES DE CONFIGURACIÓN
# =============================
FRONTEND_REPO="https://github.com/apaul6dev/frontend-mean.git"
FRONTEND_DIR="/var/www/frontend-mean"
NODE_VERSION="20"
BACKEND_ALB_DNS="internal-backend-alb-820469654.us-east-1.elb.amazonaws.com"
BACKEND_PORT="8000"

# =============================
# Instalar dependencias
# =============================
echo "🟢 Instalando Node.js y Angular CLI..."
curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
sudo apt-get update -y
sudo apt-get install -y nodejs build-essential git nginx
sudo npm install -g @angular/cli

# =============================
# Clonar y construir frontend Angular
# =============================
echo "📦 Clonando frontend Angular..."
sudo git clone ${FRONTEND_REPO} ${FRONTEND_DIR}
cd ${FRONTEND_DIR}
sudo npm install

# =============================
# Reemplazar URL del backend
# =============================
echo "🔧 Configurando endpoint del backend en Angular..."
sudo sed -i "s|http://localhost:8000/api|http://${BACKEND_ALB_DNS}:${BACKEND_PORT}/api|g" src/environments/environment.ts
sudo sed -i "s|http://localhost:8000/api|http://${BACKEND_ALB_DNS}:${BACKEND_PORT}/api|g" src/environments/environment.prod.ts

echo "🏗️ Construyendo frontend en modo producción..."
sudo ng build --configuration production

# =============================
# Configurar NGINX para servir Angular
# =============================
echo "🌐 Configurando NGINX..."
sudo tee /etc/nginx/sites-available/frontend-mean > /dev/null <<EOF
server {
  listen 80;
  server_name localhost;

  root ${FRONTEND_DIR}/dist/frontend;
  index index.html;

  location / {
    try_files \$uri \$uri/ /index.html;
  }
}
EOF

sudo ln -sf /etc/nginx/sites-available/frontend-mean /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx

echo "✅ Frontend Angular desplegado correctamente en http://localhost"
