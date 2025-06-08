#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

# =============================
# VARIABLES DE CONFIGURACIÓN
# =============================
MONGO_USER="root"
MONGO_PASS="example"
MONGO_PORT=27017
APP_REPO="https://github.com/apaul6dev/backend-mean.git"
APP_DIR="/var/www/backend-mean"
NODE_VERSION="20"
APP_DB="mean-db"

# =============================
# Instalar MongoDB 6.0
# =============================
echo "🔧 Instalando MongoDB 6.0..."

# Forzar needrestart a modo automático para evitar prompts
echo 'NEEDRESTART_MODE=a' | sudo tee -a /etc/environment
sudo sed -i 's/^#\$nrconf{restart} =.*/\$nrconf{restart} = '\''a'\'';/' /etc/needrestart/needrestart.conf

ARCH=$(dpkg --print-architecture)

curl -fsSL https://pgp.mongodb.com/server-6.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-6.0.gpg
echo "deb [ arch=${ARCH} signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" \
  | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

sudo apt-get update -y
sudo apt-get install -y mongodb-org

sudo mkdir -p /datos/bd /datos/log
sudo chown -R mongodb:mongodb /datos/bd /datos/log

sudo tee /etc/mongod.conf > /dev/null <<EOF
systemLog:
   destination: file
   path: /datos/log/mongod.log
   logAppend: true
storage:
   dbPath: /datos/bd
   journal:
      enabled: true
net:
   port: ${MONGO_PORT}
security:
   authorization: enabled
EOF

sudo systemctl enable mongod
sudo systemctl restart mongod

echo "⏳ Esperando que MongoDB esté disponible..."
for i in {1..10}; do
  if mongosh --quiet --eval "db.runCommand({ ping: 1 })" &>/dev/null; then
    echo "✅ MongoDB está disponible."
    break
  fi
  sleep 2
done

mongosh admin --eval "
db.createUser({
  user: '${MONGO_USER}',
  pwd: '${MONGO_PASS}',
  roles: [ { role: 'root', db: 'admin' } ]
})
"

# =============================
# Instalar Node.js, pm2 y clonar el backend
# =============================
echo "🟢 Instalando Node.js y pm2..."
curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
sudo apt-get install -y nodejs build-essential git
sudo npm install -g pm2

echo "📦 Clonando backend MEAN..."
sudo mkdir -p ${APP_DIR}
sudo git clone ${APP_REPO} ${APP_DIR}
cd ${APP_DIR}
sudo npm install

echo "🚀 Iniciando app con pm2..."
sudo pm2 start index.js --name backend-mean
sudo pm2 startup systemd -u $(whoami) --hp $HOME --silent
sudo pm2 save

# =============================
# Instalar y configurar NGINX
# =============================
echo "🌐 Configurando NGINX..."
sudo apt-get install -y nginx
sudo tee /etc/nginx/sites-available/backend-mean > /dev/null <<EOF
server {
  listen 80;
  server_name localhost;

  location / {
    proxy_pass http://localhost:8000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_cache_bypass \$http_upgrade;
  }
}
EOF

sudo ln -sf /etc/nginx/sites-available/backend-mean /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx

echo "✅ Backend MEAN desplegado correctamente en http://localhost"
