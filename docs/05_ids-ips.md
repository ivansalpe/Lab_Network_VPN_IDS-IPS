# IDS/IPS — Suricata en modo Inline

En esta sección voy a montar Suricata para monitorear y bloquear tráfico de la LAN y la DMZ en tiempo real, usando la topología que definimos.

###1️⃣ Creación de la VM e instalación de IDS/IPS

🦴 Creamos una nueva VM con UbuntuServer 25.04 minimal con las siguientes interfaces:
``` bash
eth0 → conexión a FW-EDGE-01 (inline)

eth1 → gestión interna o monitor remoto
```
<!--
Sistema operativo: Ubuntu Server 25.04 minimal.

Recursos recomendados:

CPU: 2 vCPU

RAM: 2–4 GB

Disco: 10–20 GB

interfaces:
eth0 - en modo interna para capturar el tráfico
eth1 - bridge o nat para salir a interner y actualizar el sistema e instalar paquetes.
Interfaces de red:
-->
🦴 Configurar las IPs:

Crear un archivo completamente nuevo desde cero
``` bash
sudo nano /etc/netplan/01-ids-ips.yaml
```
Ponemos lo siguiente:
``` yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens33:
      dhcp4: no
      addresses:
        - 10.10.0.50/24
      gateway4: 10.10.0.1
      nameservers:
        addresses: [10.10.0.1,8.8.8.8]
    ens34:
      dhcp4: yes
```
aplicamos los cambios.
``` bash
sudo netplan apply
```
<!--
Verificar conectividad:

# Ping al firewall
ping -c 3 10.10.0.1

# Ping a Internet (por eth1)
ping -c 3 8.8.8.8
-->

🦴 Instalamos Suricata(motor IDS/IPS)
``` bash
sudo apt update
sudo apt install -y suricata ethtool
```
<!--
suricata → motor IDS/IPS

ethtool → verificar capacidades de la NIC (offloading, promiscuous, etc.)
-->
🦴 Deshabilitar offloading de NIC para asegurar que Suricata inspeccione todo el tráfico:

sudo ethtool -K ens33 gro off gso off tso off

### 2️⃣. Configurar Suricata en modo Inline

Edito el archivo principal:

sudo nano /etc/suricata/suricata.yaml


Cambios principales:

af-packet:
  - interface: eth0
    cluster-id: 99
    cluster-type: cluster_flow
    defrag: yes
    use-mmap: yes
    # Para modo inline (IPS)
    bypass: no
    copy-iface: false


bypass: no → obliga a Suricata a bloquear paquetes sospechosos.

copy-iface: false → no solo monitoriza, actúa directamente sobre el tráfico.

Tip: Guardar una copia de suricata.yaml original antes de modificar.
3️⃣. 
