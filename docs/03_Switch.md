# SW-CORE-02 — Switch Core y Servidores Internos

El objetivo de crear una VM ligera que actúe como switch virtual / bridge para la LAN (10.10.1.0/24). Hardware mínimo y red correctamente mapeada para conectar servidores internos.

### 1️⃣. Crear la VM SW-CORE-02 en VMware

Lo primero es preparar y configurar el entorno, descargo la iso de [Alpine Linux](https://www.alpinelinux.org/?utm_source=chatgpt.com) que es la distribución de linux que voy a utilizar ya que es ligera y empiezo a preparar la interfaz de red(VMnet2 → 10.10.1.0/24) en modo "host only".

Editamos el archivo ".vmx" y le añadimos la siguiente línea: 
<!-- Esto permite al sistema de bridge capturar paquetes en modo promiscuo si hace falta. -->
```bash
ethernet0.allowPromisc = "TRUE" 
```
### 2️⃣. Instalación de SO y configuración del bridge en SW-CORE-02
Se entra al sistema, se loguea como 'root' y se añade lo siguiente 'setup-alpine' para empezar la instalación.

Asignar IP temporal correctamente

Primero asegúrate de que la interfaz está conectada:
``` bash
ip link set eth0 up
```
(Reemplaza eth0 por el nombre real de tu interfaz; usa ip a para listarlas si no sabes el nombre.)
<!--
Luego asigna la IP con la interfaz explícita:
``` ip addr add 192.168.238.50/24 dev eth0 ```
Agrega la ruta por defecto (gateway):
``` ip route add default via 192.168.238.2 ```
Configura DNS temporal:
``` echo "nameserver 8.8.8.8" > /etc/resolv.conf ```bash
Prueba conectividad:
``` ping -c 4 8.8.8.8
ping -c 4 dl-cdn.alpinelinux.org ```
-->

en la parte de "repositories mirror" poner lo siguiente:
<!--echo linkrepositorio >> /etc/apk/repositories -->
``` bash
http://mirror1.hs-esslingen.de/pub/Mirrors/alpine/v3.20/main
http://mirror1.hs-esslingen.de/pub/Mirrors/alpine/v3.20/community
```
actualiza los repositorios con:
``` bash
apk update
```
Instalamos los paquetes necesarios:
Ahora ejecuta:
``` bash
apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/v3.22/main bridge iproute2
``` 
<!-- Con --repository = obligamos a usar un repositorio válido y directo, evitando problemas de “world not found”.

--no-cache = evita conflictos con caché corrupto.
 -->
 Ahora vamos a configurar el **bridge br0**, para eso editamos el siguiente fichero "/etc/network/interfaces" con lo siguiente:
``` nano
auto lo
iface lo inet loopback

# Interfaz física (sin IP)
auto eth0
iface eth0 inet manual

# Bridge principal
auto br0
iface br0 inet static
    address 10.10.1.2
    netmask 255.255.255.0
    gateway 10.10.1.1
    dns-nameservers 8.8.8.8 1.1.1.1
    bridge_ports eth0
    bridge_stp off
    bridge_fd 0

``` 
 
 <!-- eth0 es la interfaz conectada al Core/Router.

br0 es el bridge virtual, con la IP de gestión 10.10.1.2.

Si vas a conectar más NICs al switch, simplemente añádelas en bridge_ports.
 -->
 Reinicia la red para aplicar cambios:
 ``` bash
rc-service networking restart
```
 <!--
Verifica que br0 existe y está UP:

'''ip a show br0'''

Prueba conectividad:

'''ping -c 4 10.10.1.1   # Gateway (RT-CORE-01)
ping -c 4 8.8.8.8     # DNS externo'''

E. Arranque automático

Asegúrate de que los servicios se inicien en boot:

'''rc-update add networking boot
rc-update add local boot'''
 -->

 
