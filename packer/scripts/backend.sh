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

# Evitar prompts de reinicio de servicios
echo 'NEEDRESTART_MODE=a' | sudo tee -a /etc/environment
sudo sed -i 's/^#\$nrconf{restart} =.*/\$nrconf{restart} = '\''a'\'';/' /etc/needrestart/needrestart.conf || true

ARCH=$(dpkg --print-architecture)

curl -fsSL https://pgp.mongodb.com/server-6.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-6.0.gpg
echo "deb [ arch=${ARCH} signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" \
  | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

sudo apt-get update -y
sudo apt-get install -y mongodb-org

# Configuración inicial sin autenticación
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
# No activar autorización todavía
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

# Crear usuario admin
mongosh admin --eval "
if (!db.getUser('${MONGO_USER}')) {
  db.createUser({
    user: '${MONGO_USER}',
    pwd: '${MONGO_PASS}',
    roles: [ { role: 'root', db: 'admin' } ]
  })
}
"

# Activar autenticación
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

sudo systemctl restart mongod

# =============================
# Instalar Node.js, PM2 y Backend
# =============================
echo "🟢 Instalando Node.js y PM2..."
curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
sudo apt-get install -y nodejs build-essential git
sudo npm install -g pm2

echo "📦 Clonando backend MEAN..."
sudo rm -rf ${APP_DIR}
sudo git clone ${APP_REPO} ${APP_DIR}
sudo chown -R $(whoami):$(whoami) ${APP_DIR}
cd ${APP_DIR}
npm install

# =============================
# Iniciar app con PM2 y configurar inicio automático
# =============================
echo "🚀 Iniciando app con PM2..."
pm2 start index.js --name backend-mean

# Registrar PM2 en arranque automático
STARTUP_CMD=$(pm2 startup systemd -u $(whoami) --hp $HOME | grep sudo)
eval $STARTUP_CMD

pm2 save

echo "✅ Backend MEAN desplegado y configurado para arrancar automáticamente con PM2"
