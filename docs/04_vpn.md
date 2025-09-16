# VPN-GW (10.10.2.10) con StrongSwan

#### 1️⃣. Creación y configuración de red de VPN

Instalo el sistema operativo[Ubuntu Server minimal](https://ubuntu.com/download/server) con su interfaz.
<!--
Nombre: vpn-gw
SO: Debian/Ubuntu Server minimal
CPU/RAM: 2 vCPU, 2 GB RAM
Disco: 10 GB
NICs:
eth0 → Conectado a la red VPN (10.10.2.0/24)
IP: 10.10.2.10/24
Gateway: 10.10.2.1 (FW-EDGE-01, interfaz em2)
  -->
Actualizo los repositorios y descargo e instalo el comando **"ping"** que viene en el paquete **"iputils-ping"** para probar la conectividad después:
``` bash
sudo apt update
sudo apt install iputils-ping -y
```
Creo el archivo **"01-netcfg.yaml"** dentro de **/etc/netplan/"**
``` bash
sudo touch /etc/netplan/01-netcfg.yaml
```
Y dentro del archivo pongo lo siguiente para configurar la red:
``` bash
network:
  version: 2
  ethernets:
    ens33:
      addresses: [10.10.2.10/24]
      gateway4: 10.10.2.1
      nameservers:
        addresses: [8.8.8.8,1.1.1.1]
```
Aplico los cambios:
``` bash
sudo netplan apply
```
<!-- Para verificar la conexión
ip a show ens33
ping -c 4 10.10.2.1   # FW-EDGE-01
  -->
### 2️⃣. Instalar StrongSwan (IPsec)
``` bash
sudo apt install -y strongswan strongswan-pki
```
Esto instala el servicio de VPN IPsec.

### 3️⃣. Generar certificados y claves
Aquí se crea una Autoridad Certificadora (CA) y un certificado de servidor para el Gateway VPN.
Esto permite que los clientes validen la identidad del servidor y establezcan un túnel seguro.
<!-- 
> Instalar librerías TPM (si se quiere usar TPM)
sudo apt install -y tpm2-abrmd tpm2-tools libtss2-tcti-tabrmd0

Esto instalará la librería que el plugin TPM necesita.

> Deshabilitar el plugin TPM (opción rápida)
Edito /etc/strongswan.d/charon/*.conf (por ejemplo plugins-strongswan.conf) y desactivo el plugin tpm.

Por ejemplo, añado:
load = tpm no
--> 
En VPN-GW:

Ⓐ. Se crean las carpetas para las claves:
``` bash
mkdir -p /etc/ipsec.d/{private,certs,cacerts}
``` 
Ⓑ. Se genera la clave privada CA autofirmada:
``` bash
mkdir -p /etc/ipsec.d/{private,certs,cacerts}
sudo ipsec pki --gen --type rsa --size 4096 --outform pem > /etc/ipsec.d/private/ca.key.pem
sudo chmod 600 /etc/ipsec.d/private/ca.key.pem

sudo ipsec pki --self --ca --lifetime 3650 \
  --in /etc/ipsec.d/private/ca.key.pem \
  --dn "CN=VPN-CA" \
  --outform pem > /etc/ipsec.d/cacerts/ca-cert.pem
```

Ⓒ. Crear clave privada para el VPN-GW:
``` bash
sudo ipsec pki --gen --type rsa --size 2048 --outform pem > /etc/ipsec.d/private/vpn-gw.key.pem
sudo chmod 600 /etc/ipsec.d/private/vpn-gw.key.pem
```

Ⓓ. Emitir certificado del servidor VPN
``` bash
sudo ipsec pki --pub --in /etc/ipsec.d/private/vpn-gw.key.pem \
  --type rsa | sudo ipsec pki --issue \
  --cacert /etc/ipsec.d/cacerts/ca-cert.pem \
  --cakey /etc/ipsec.d/private/ca.key.pem \
  --dn "CN=vpn.ivansalpe.lab" \
  --san "vpn.ivansalpe.lab" \
  --flag serverAuth --flag ikeIntermediate \
  --outform pem > /etc/ipsec.d/certs/vpn-gw.cert.pem
```
Ⓔ. Verificar Certificado
``` bash
openssl x509 -in /etc/ipsec.d/certs/vpn-gw.cert.pem -text -noout
``` 
<!-- 
| Paso | Qué hace | Tip importante |
|------|----------|----------------|
| 1️⃣ Crear CA | Genera la **clave privada de la autoridad certificadora** y un certificado autofirmado. | Mantener la clave privada de la CA **muy segura**. No compartir. |
| 2️⃣ Crear clave VPN | Genera la **clave privada del servidor VPN** que usará StrongSwan. | RSA 2048 suficiente para laboratorio; en producción: 3072-4096. |
| 3️⃣ Emitir certificado VPN | Convierte la clave privada en pública, luego **firma con la CA** para que el certificado sea válido. | `--flag serverAuth --flag ikeIntermediate` asegura que el certificado es válido para servidor VPN y IKEv2. |
| 4️⃣ Verificación | Muestra información clave del certificado para confirmar CN, SAN y flags. | Siempre revisar CN y SAN coincidan con tu hostname/IP real de VPN. |

- ca-cert.pem → certificado de la CA

- vpn-gw.cert.pem → certificado del servidor VPN

- vpn-gw.key.pem → clave privada del servidor VPN

Para automatizar el processo [Agenerate-cert](config/generate-vpn-cert.sh)
--> 
💡 Siempre mantengo las claves privadas con permisos 600 para seguridad.

### 4️⃣. Integración VPN-GW con StrongSwan y Firewall

En este paso voy a configurar la VPN Gateway (`VPN-GW 10.10.2.10`) usando **StrongSwan (IKEv2)** y conectarla con el Firewall `FW-EDGE-01`. Esto me permitirá que clientes remotos se conecten de forma segura a la LAN interna.

Ⓐ. Configuración de StrongSwan en VPN-GW

Modifico el archivo **/etc/ipsec.conf** con la siguiente configuración:

```bash
config setup
    charondebug="ike 2, knl 2, cfg 2, net 2"

conn ivansalpe-vpn
    keyexchange=ikev2
    auto=add
    left=%any
    leftid=@vpn.ivansalpe.lab
    leftcert=vpn-gw.cert.pem
    leftsubnet=10.10.1.0/24
    right=%any
    rightid=%any
    rightauth=eap-mschapv2
    rightsourceip=10.10.2.100-10.10.2.200
    eap_identity=%identity
```
y este archivo **/etc/ipsec.secrets** también con lo siguiente:
```bash
: RSA "vpn-gw.key.pem"
usuario : EAP "claveSuperSecreta123"
```
<!-- 
Qué hago aquí:

leftsubnet -- define la LAN interna que quiero que los clientes VPN vean.

rightsourceip -- define el rango que asigno a los clientes.

eap_identity -- permite usar usuario/contraseña para autenticar los clientes.
-->
💡 Siempre reviso que los CN y SAN de mi certificado coincidan con el hostname real del VPN-GW.

Ⓑ. Arrancar StrongSwan
Para iniciar el daemon IPsec (charon) utilizo:
```bash
sudo ipsec start
```
Esto lanza StrongSwan y carga la configuración de /etc/ipsec.conf y /etc/ipsec.secrets.

Después puedo verificar el estado con:
```bash
sudo ipsec statusall
```

Tip: statusall muestra todas las conexiones definidas, SA activas y rangos de IP asignados a clientes VPN.
<!-- 
Pruebas de conexión VPN

Desde un cliente remoto:

Importo la CA ca-cert.pem

Creo una conexión IKEv2 hacia vpn.ivansalpe.lab

Usuario: usuario

Password: claveSuperSecreta123

Pruebo conectividad:

ping 10.10.1.10   # SRV-WEB
ping 10.10.1.11   # SRV-DB
ping 10.10.1.12   # SRV-APP
ping 8.8.8.8      # Salida a Internet

Si responde todo, significa que la VPN está funcionando correctamente y los clientes tienen acceso seguro a la LAN interna y opcionalmente a Internet.
-->
---
<!-- 
— Reiniciar StrongSwan

Cada vez que modifico la configuración:

sudo ipsec stop
sudo ipsec start


Esto asegura que los cambios en ipsec.conf o en los certificados se apliquen correctamente.

— Arranque automático con systemd (opcional, recomendado)

Si quiero que StrongSwan se inicie al arrancar Ubuntu, puedo crear un unit file personalizado:

Crear archivo de unidad:

sudo nano /etc/systemd/system/strongswan.service

Pegar contenido:

[Unit]
Description=StrongSwan IPsec VPN daemon
After=network.target

[Service]
Type=forking
ExecStart=/usr/sbin/ipsec start
ExecStop=/usr/sbin/ipsec stop
ExecReload=/usr/sbin/ipsec reload
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target


Recargar systemd y habilitar servicio:

sudo systemctl daemon-reload
sudo systemctl enable strongswan
sudo systemctl start strongswan
sudo systemctl status strongswan


Ahora strongswan arranca automáticamente al inicio del sistema.

status muestra que el daemon está activo y cargando las configuraciones.

— Ver conexiones y depuración
sudo ipsec statusall
sudo journalctl -u strongswan -f


statusall → estado de túneles, SA IKE/IPsec, IP asignadas a clientes

journalctl -f → logs en tiempo real para troubleshooting
-->
