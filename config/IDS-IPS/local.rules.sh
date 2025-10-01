#!/bin/bash
set -e
echo "[*] Habilitando ET Open y actualizando reglas..."
sudo suricata-update enable-source et/open
sudo suricata-update
echo "[*] Creando local.rules de laboratorio..."
sudo tee /etc/suricata/rules/local.rules > /dev/null <<'EOF'
drop tcp any any -> any 22 (msg:"LAB - DROP SSH intento"; sid:1000001; rev:1;)
alert icmp any any -> any any (msg:"LAB - ICMP ping detectado"; sid:1000002; rev:1;)
EOF
echo "[*] Hecho. Reinicia Suricata."
