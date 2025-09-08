
Lo Primero es Configurar los entornos virtuales, para eso en VMware en "virtual-network-editor se añade la siguiente información <...>.

# FW_EDGE_01 — Firewall de borde (OPNsense) 
### 1️⃣. Instalar OPNsense
Descargar la iso e instalar el firewall [OPNsense](https://opnsense.org/download/).
- Usuario: `installer`  
- Password: `opnsense`  
Esto te da acceso al instalador.
> Recomendable elegir la opción `ZFS` como sistema de  archivos ya que es mas avanzado.
> Recomendable cambiar la contraseña.

### 2️⃣. Asignar interfaces y IPs
> Se introduce las interfaces de red en la opción 1)assign interfaces y se añade las interfaces.

> Le assignamos las IPs a las interfaces en la opción **2)Set interface IP address** .


| Interfaz FW | Nombre | Red/Subred     | IP en FW       | Gateway          | Función                                |
|-------------|--------|---------------|----------------|----------------|----------------------------------------|
| em0         | WAN    | 192.168.1.0/24 | 192.168.1.2    | 192.168.1.1    | Conexión a Internet / router ISP        |
| em1         | LAN    | 10.10.0.0/24   | 10.10.0.1      | –              | Red interna/core                        |
| em2         | VPN    | 10.10.2.0/24   | 10.10.2.1      | –              | Gateway VPN (clientes remotos)          |
| em3         | DMZ    | 10.10.3.0/24   | 10.10.3.1      | –              | Servidores expuestos (WEB, MAIL, DNS)   |



### 3️⃣. Configuración inicial via GUI
> En el navegador → https://10.10.0.1
> Se entra en "wizard" y se empieza a configurar:
     - Hostname: `fw-edge-01`
     - Timezone: ajustar a tu región.
     - DNS: `8.8.8.8 / 1.1.1.1` (opcional interno).
     - Activar SSH para gestión remota segura.
     - Cambiar contraseña admin por una fuerte.

### 4️⃣. Reglas de firewall mínimas

> Se añade las siguientes reglas: 
    
  1. LAN → Any (permit established)  → `Menú: Firewall → Rules  →  Lan`
     - **Action:** Pass
     - **Interface:** LAN
     - **Source:** LAN net
     - **Destination:** Any
     - **State type:** Keep state
     - **Description:** "Allow LAN to Internet (established)"
  //Esto permite que todos los hosts de la LAN inicien conexiones hacia cualquier destino (Internet, VPN, Core), mientras bloquea conexiones no solicitadas desde fuera.
  
  2. WAN → Solo HTTPS/SSH desde IP segura  → `Menú: Firewall → Rules → Wan`
     - **Action:** Pass
     - **Interface:** WAN
     - **Source:** IP de gestión segura (ej: mi IP pública/32 o cualquier-ip-interna/32) o VPN/red interna(10.10.2.0/24) 
     - **Destination:** WAN address(192.168.1.2)
     - **Destination port range:** HTTPS (443) o SSH (22)
     - **Description:** "Allow secure remote admin"
  //Esto Permite que solo direcciones IP autorizadas accedan al firewall desde Internet. Si no se necesita acceso remoto, **no agregar esta regla**.

  3. NAT outbound: Automatic (masquerade para LAN → WAN) → Menú: `Menú: Firewall → NAT → Outbound`
     - Seleccionar **Automatic Outbound NAT**.
  //La LAN (10.10.0.0/24) puede salir a Internet usando la IP de WAN del firewall (192.168.1.2). Esto evita conflictos de rutas y permite conectividad hacia afuera.

  4. VPN/DMZ → Lo configuramos mas adelante @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


// Permite tráfico seguro desde LAN hacia Internet, protege segmentos críticos.

### 5️⃣. Integración con Router Core (RT-CORE-01)



