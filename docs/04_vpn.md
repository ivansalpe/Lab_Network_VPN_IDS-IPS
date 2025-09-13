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
Después de reiniciar strongSwan, el warning debería desaparecer.

> Deshabilitar el plugin TPM (opción rápida)

Edito /etc/strongswan.d/charon/*.conf (por ejemplo plugins-strongswan.conf) y desactivo el plugin tpm.

Por ejemplo, añado:

load = tpm no
--> 
En VPN-GW:

Se crean las carpetas y se generar la clave privada de la CA:
``` bash
mkdir -p /etc/ipsec.d/{private,certs,cacerts}
ipsec pki --gen --outform pem > /etc/ipsec.d/private/vpn-gw.key.pem
chmod 600 /etc/ipsec.d/private/vpn-gw.key.pem
```
> 📌 Qué hace: </br>
> Crea una clave RSA privada para la CA. </br>
> Se guarda en /etc/ipsec.d/private/ca.key.pem. </br>

>⚠️ Importante: </br>
>Esta clave es ultra sensible: con ella se pueden firmar certificados. </br>
> Debe tener permisos 600 y nunca salir del servidor seguro.

Crear certificado autofirmado(CA) para el servidor VPN:
``` bash
ipsec pki --self --in /etc/ipsec.d/private/vpn-gw.key.pem \
  --dn "CN=vpn.ivansalpe.lab" --ca \
  --outform pem > /etc/ipsec.d/cacerts/ca-cert.pem

ipsec pki --issue --in /etc/ipsec.d/private/vpn-gw.key.pem \
  --cacert /etc/ipsec.d/cacerts/ca-cert.pem \
  --dn "CN=vpn.ivansalpe.lab" --san "vpn.ivansalpe.lab" \
  --outform pem > /etc/ipsec.d/certs/vpn-gw.cert.pem
```
> 📌 Qué hace: </br>
> Usa la clave de la CA para generar un certificado autofirmado. </br>
> Este es el certificado raíz (Root CA). </br>
> Los clientes lo necesitan para confiar en los certificados que firme la CA. </br>
>👉 Se guarda en /etc/ipsec.d/cacerts/ca.cert.pem.

