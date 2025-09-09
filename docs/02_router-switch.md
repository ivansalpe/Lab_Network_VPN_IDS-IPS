# RT/SW-CORE-01 — Router/Core Switch

### 1️⃣. Crear VM RT/SW-CORE-01 en VMware

Se añade las interfaces de red y se crea la VM.

>//Crear la máquina virtual que actuará como router/switch core del laboratorio, conectando el IDS, FW-EDGE-01 y los switches internos. Esta VM será la base para enrutar y segmentar el tráfico entre VLANs.

Se descarga [VyOS](https://vyos.net/get/nightly-builds/), y en este caso como es un laboratorio utilizaremos la versión **"Rolling release"** ya que permite
acceder a las últimas características y mejoras de VyOS, ideales para pruebas y desarrollo en un entorno controlado.

Se arranca la máquina con la iso puesta y después de poner las credenciales(vyos), se debe poner **"install image
"** para empezar la instalación.

>//Copia VyOS desde el CD al disco duro virtual y configura GRUB para boot.

### 2️⃣. Configurar interfaces y rutas (RT/SW-CORE-01)

> Esto asigna IPs a las interfaces del router core y establecer rutas básicas para que el tráfico interno y hacia Internet fluya correctamente.

 Entramos en modo configuración para poder aplicar cambios de red. 
 ``` bash 
 configure
 ```
[//]: # (Interfaz hacia IDS/FW)

``` bash
set interfaces ethernet eth0 description "Link to IDS"
set interfaces ethernet eth0 address 10.10.0.2/24
``` 
> eth0 conecta al IDS y al firewall; 10.10.0.2/24 es la IP del Core en esta subred.

[//]: # 'Interfaz hacia SWC (LAN interna, VLAN1)'

``` bash
set interfaces ethernet eth1 description "LAN VLAN1"
set interfaces ethernet eth1 address 10.10.1.1/24
```
> eth1 conecta al switch core y distribuye tráfico a los servidores internos.

[//]: # (Ruta por defecto hacia FW-EDGE-01)
``` bash 
set protocols static route 0.0.0.0/0 next-hop 10.10.0.1
```  
> Todo tráfico no local se envía al firewall de borde.
``` bash 
commit
``` 
> Aplica los cambios inmediatamente.
``` bash 
save
``` 
> Guarda la configuración de manera persistente.

``` bash 
exit
``` 
> Salimos del modo configuración.
<!-- ==========================================
Verificaciones rápidas
show interfaces
ping 10.10.0.1
ping 10.10.1.10
traceroute 8.8.8.8
show interfaces → confirma que eth0 y eth1 tienen las IPs correctas.

ping 10.10.0.1 → comprueba conectividad con FW.

ping 10.10.1.10 → comprueba conectividad con SRV-WEB.

traceroute 8.8.8.8 → verifica que la ruta por defecto hacia Internet funciona
=========================================== -->
### 3️⃣. Tercer Punto Importante
