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
Verificaciones rápidas:
``` bash 
show interfaces
ping 10.10.0.1
ping 10.10.1.10
traceroute 8.8.8.8
```
show interfaces → confirma que eth0 y eth1 tienen las IPs correctas.

ping 10.10.0.1 → comprueba conectividad con FW.

ping 10.10.1.10 → comprueba conectividad con SRV-WEB.

traceroute 8.8.8.8 → verifica que la ruta por defecto hacia Internet funciona
=========================================== -->
### 3️⃣. Configuración VLAN trunking (opcional pero recomendado)
Ⓐ Entrar en modo configuración VyOS
``` bash
configure
```
Ⓑ Crear VLAN1 (LAN interna)
<!-- ==========================================
# Crear subinterfaz VLAN1
vif 1 → VLAN1 (LAN interna)

IP 10.10.1.1/24 → gateway para servidores
=========================================== -->
``` bash
set interfaces ethernet eth1 vif 1 address '10.10.1.1/24'
set interfaces ethernet eth1 vif 1 description 'LAN_VLAN1'
```
# Comentario: eth1 se convierte en trunk para VLAN1; IP 10.10.1.1/24 para la red interna.
Ⓒ Crear VLAN2 (VPN)
``` bash
set interfaces ethernet eth1 vif 2 description 'VPN_VLAN2'
```
set interfaces ethernet eth0 vif 2 address 10.10.2.2/24
# Comentario: eth0 hacia IDS/FW también lleva tráfico de VPN; IP 10.10.2.2/24.
Ⓓ Crear VLAN3 (DMZ)

``` bash
set interfaces ethernet eth1 vif 3 description 'DMZ_VLAN3'
```
set interfaces ethernet eth3 vif 3 address 10.10.3.2/24
# Comentario: eth3 conecta hacia DMZ; IP 10.10.3.2/24 para servidores DMZ.

Ⓔ Configurar ruta hacia FW-EDGE-01
``` bash
set protocols static route 0.0.0.0/0 next-hop 10.10.0.1
```
- Esto permite que cualquier tráfico que salga de la LAN hacia Internet pase por el firewall.

Ⓕ Activar forwarding entre VLANs (opcional para pruebas de LAN)
VyOS tiene IP forwarding activado por defecto, pero para asegurarse:
``` bash
set system ip-forwarding
```
##### Verificaciones:
``` bash
show interfaces
```
// Comprueba que eth1.1, eth0.2 y eth3.3 existen y tienen las IPs correctas.
``` bash
ping 10.10.1.10
```
// Comentario: Comprueba conectividad con SRV-WEB (VLAN1).
``` bash
ping 10.10.2.10
```
// Comprueba conectividad con VPN-GW (VLAN2).
``` bash
ping 10.10.3.10
```
// Comprueba conectividad con DMZ-WEB (VLAN3).

### 4️⃣. Integración con FW-EDGE-01 e IDS
<!--
Diagrama de flujo de integración

| Nodo        | Interfaz Core      | Interfaz Destino       | Tipo de Conexión       |
|------------|------------------|----------------------|----------------------|
| Core Router | VLAN1             | SW-CORE-02           | LAN interna          |
| Core Router | VLAN0 o trunk     | IDS (eth0)           | Monitor/inline       |
| Core Router | VLAN2             | FW-EDGE-01 (em1 LAN) | LAN / IPS inline     |

- Todo el tráfico LAN → Core → FW → IDS (inline)
- Se usan VLANs para separar tráfico de usuarios, servidores y DMZ.
- IDS en modo inline conectado al Core permite inspeccionar y bloquear tráfico antes de llegar al FW o a los servidores.
-->
🍀 Configurar VLANs en el Core Router

VLAN 1 - LAN interna
``` bash
# VLAN1 - LAN interna
sudo ip link add link eth0 name eth0.1 type vlan id 1
sudo ip addr add 10.10.1.1/24 dev eth0.1
sudo ip link set dev eth0.1 up
```
VLAN 2 - IPS/IDS trunk
``` bash
sudo ip link add link eth0 name eth0.2 type vlan id 2
sudo ip addr add 10.10.0.2/24 dev eth0.2
sudo ip link set dev eth0.2 up
```
<!--
Explicación:
- link eth0 → subinterface sobre la interfaz física ens33.
- name eth0.X → nombre de la subinterface.
- type vlan id X → asigna ID de VLAN.
- ip addr add → define la IP del Core Router en esa VLAN.
- ip link set up → activa la interfaz.
-->>>
🍀 Configurar rutas hacia FW-EDGE-01 e IDS

Red LAN interna a FW (tráfico hacia firewall)
``` bash
sudo ip route add 10.10.0.0/24 via 10.10.0.1    # FW-EDGE-01 LAN
```
Red IDS inline
```
sudo ip route add 10.10.0.50/32 via 10.10.0.50  # IDS/IPS
```

### 5️⃣. Conectar SWC y servidores
<!-- =========================================== 
7. Verificaciones básicas

Qué hacer:

ping 10.10.0.1 → hacia FW-EDGE-01

ping 10.10.1.10 → hacia SRV-WEB

traceroute 8.8.8.8 → confirma salida por FW-EDGE-01

Para qué sirve: Comprueba conectividad entre FW, IDS, Core y servidores.

8. Backup y automatización

Qué hacer:

Exportar configuración VyOS: save /config/config.boot

Guardar en repo configs/core/

Para qué sirve: Permite restaurar rápidamente o replicar VM.
=========================================== -->
