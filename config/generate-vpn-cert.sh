#!/bin/bash
# =====================================================
# Script para crear CA y certificado VPN para StrongSwan
# Compatible con Ubuntu Server 25.0
# Autor: ivansalpe
# =====================================================

# Variables
CA_KEY="/etc/ipsec.d/private/ca.key.pem"
CA_CERT="/etc/ipsec.d/cacerts/ca-cert.pem"
VPN_KEY="/etc/ipsec.d/private/vpn-gw.key.pem"
VPN_CERT="/etc/ipsec.d/certs/vpn-gw.cert.pem"
VPN_CN="vpn.ivansalpe.lab"

# =====================================================
# 1️⃣ Crear la CA (autoridad certificadora)
# Genera clave RSA de 4096 bits y crea un certificado autofirmado
# =====================================================
echo "[*] Generando clave privada de la CA..."
ipsec pki --gen --type rsa --size 4096 --outform pem > $CA_KEY
chmod 600 $CA_KEY
echo "[*] Clave CA creada en $CA_KEY"

echo "[*] Creando certificado autofirmado de la CA..."
ipsec pki --self --ca --lifetime 3650 \
  --in $CA_KEY \
  --dn "CN=VPN-CA" \
  --outform pem > $CA_CERT
echo "[*] Certificado CA creado en $CA_CERT"

# Tip: Mantener la clave de CA segura. Usar chmod 600 evita accesos no autorizados.

# =====================================================
# 2️⃣ Crear clave privada del VPN-GW
# Clave RSA de 2048 bits para el servidor VPN
# =====================================================
echo "[*] Generando clave privada del VPN-GW..."
ipsec pki --gen --type rsa --size 2048 --outform pem > $VPN_KEY
chmod 600 $VPN_KEY
echo "[*] Clave VPN creada en $VPN_KEY"

# Tip: RSA 2048 suficiente para lab; en producción considerar 3072/4096 bits.

# =====================================================
# 3️⃣ Emitir certificado del VPN-GW usando la CA
# Convierte la clave privada en pública, luego firma con la CA
# =====================================================
echo "[*] Creando certificado del VPN-GW firmado por la CA..."
ipsec pki --pub --in $VPN_KEY \
  --type rsa | ipsec pki --issue \
  --cacert $CA_CERT \
  --cakey $CA_KEY \
  --dn "CN=$VPN_CN" \
  --san "$VPN_CN" \
  --flag serverAuth --flag ikeIntermediate \
  --outform pem > $VPN_CERT
echo "[*] Certificado VPN creado en $VPN_CERT"

# =====================================================
# 4️⃣ Verificación rápida
# =====================================================
echo "[*] Verificando certificado VPN..."
openssl x509 -in $VPN_CERT -text -noout | grep -E "Subject:|Subject Alternative Name|X509v3 Key Usage"

echo "[✅] Proceso completado. Archivos listos para StrongSwan:"
echo "    CA: $CA_CERT"
echo "    VPN Key: $VPN_KEY"
echo "    VPN Cert: $VPN_CERT"
