# Script de configuración del IDS/IPS (Alpine) - Bridge de gestión

!/bin/bash
# ===========================================
# Configuración de bridge inline para IDS/IPS
# ===========================================
# Este script crea un bridge de gestión "br-inline",
# añade las interfaces físicas ens33 y ens34,
# y asigna la IP de administración 10.10.0.50/24.
# Las interfaces físicas no tendrán IPs, manteniendo el modo inline transparente.
# ===========================================

# 1️⃣ Crear el bridge "br-inline"
sudo ip link add name br-inline type bridge
echo "[INFO] Bridge br-inline creado"

# 2️⃣ Levantar el bridge
sudo ip link set br-inline up
echo "[INFO] Bridge br-inline activado"

# 3️⃣ Añadir interfaces físicas al bridge
sudo ip link set ens33 master br-inline
sudo ip link set ens34 master br-inline
echo "[INFO] Interfaces ens33 y ens34 añadidas al bridge"

# 4️⃣ Levantar las interfaces físicas
sudo ip link set ens33 up
sudo ip link set ens34 up
echo "[INFO] Interfaces físicas activadas"

# 5️⃣ Asignar IP de gestión al bridge
sudo ip addr add 10.10.0.50/24 dev br-inline
echo "[INFO] IP de gestión 10.10.0.50/24 asignada al bridge"

# 6️⃣ Verificación
echo "[INFO] Estado del bridge y interfaces:"
ip addr show br-inline
ip link show ens33
ip link show ens34

echo "[INFO] Ping de prueba hacia FW y Core Router:"
ping -c 3 10.10.0.1   # Firewall
ping -c 3 10.10.0.2   # Core Router

echo "[INFO] Configuración completada con éxito"
