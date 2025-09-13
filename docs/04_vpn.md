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
<!-- Para verificar l conexión
ip a show ens33
ping -c 4 10.10.2.1   # FW-EDGE-01
  -->
### 2️⃣. Instalar StrongSwan (IPsec)
