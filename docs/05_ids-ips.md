IDS/IPS — Suricata en modo Inline

En esta sección voy a montar Suricata para monitorear y bloquear tráfico de la LAN y la DMZ en tiempo real, usando la topología que definimos.

1️⃣ Creación de la VM e instalación de IDS/IPS

Creamos una nueva VM con UbuntuServer 25.04 minimal con las siguientes interfaces:
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

💡: Para modo inline, la NIC principal debe estar enbridged y conectada a un switch virtual que reciba todo el tráfico que quieres inspeccionar.
Interfaces de red:
-->
***
Instalamos Suricata(motor IDS/IPS)

sudo apt update
sudo apt install -y suricata ethtool


suricata → motor IDS/IPS

ethtool → verificar capacidades de la NIC (offloading, promiscuous, etc.)

💡: Deshabilitar offloading de NIC para asegurar que Suricata inspeccione todo el tráfico:

sudo ethtool -K eth0 gro off gso off tso off
