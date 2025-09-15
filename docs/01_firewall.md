
Lo Primero es Configurar los entornos virtuales, para eso en VMware en "virtual-network-editor se añade la siguiente información <...>.

# FW_EDGE_01 — Firewall de borde (OPNsense) 
### 1️⃣. Instalar OPNsense
Descargar la iso e instalar el firewall [OPNsense](https://opnsense.org/download/). <!-- https://docs.opnsense.org/manual/how-tos/ipsec-rw-srv-mschapv2.html -->
- Usuario: `installer`  
- Password: `opnsense`  
Esto te da acceso al instalador.
Recomendable elegir la opción `ZFS` como sistema de  archivos ya que es mas avanzado.
Recomendable cambiar la contraseña.

### 2️⃣. Asignar interfaces y IPs
Se introduce las interfaces de red en la opción 1)assign interfaces y se añade las interfaces.

Le assignamos las IPs a las interfaces en la opción **2)Set interface IP address** .


| Interfaz FW | Nombre | Red/Subred     | IP en FW       | Gateway          | Función                                |
|-------------|--------|---------------|----------------|----------------|----------------------------------------|
| em0         | WAN    | 192.168.1.0/24 | 192.168.1.2    | 192.168.1.1    | Conexión a Internet / router ISP        |
| em1         | LAN    | 10.10.0.0/24   | 10.10.0.1      | –              | Red interna/core                        |
| em2         | VPN    | 10.10.2.0/24   | 10.10.2.1      | –              | Gateway VPN (clientes remotos)          |
| em3         | DMZ    | 10.10.3.0/24   | 10.10.3.1      | –              | Servidores expuestos (WEB, MAIL, DNS)   |


<img width="1755" height="481" alt="image" src="https://github.com/user-attachments/assets/8e3abf26-e2c9-4d13-894c-067ebdc08f11" />



### 3️⃣. Configuración inicial via GUI
En el navegador → https://10.10.0.1
Se entra en "wizard" y se empieza a configurar:
     - Hostname: `fw-edge-01`
     - Timezone: ajustar a tu región.
     - DNS: `8.8.8.8 / 1.1.1.1` (opcional interno).
     - Activar SSH para gestión remota segura.
     - Cambiar contraseña admin por una fuerte.

### 4️⃣. Reglas de firewall mínimas

Se añade las siguientes reglas: 
    
  1. LAN → Any (permit established)  → `Menú: Firewall → Rules  →  Lan`
     - **Action:** Pass
     - **Interface:** LAN
     - **Source:** LAN net
     - **Destination:** Any
     - **State type:** Keep state
     - **Description:** "Allow LAN to Internet (established)"
  >//Esto permite que todos los hosts de la LAN inicien conexiones hacia cualquier destino (Internet, VPN, Core), mientras bloquea conexiones no solicitadas desde fuera.
  
  2. WAN → Solo HTTPS/SSH desde IP segura  → `Menú: Firewall → Rules → Wan`
     - **Action:** Pass
     - **Interface:** WAN
     - **Source:** IP de gestión segura (ej: mi IP pública/32 o cualquier-ip-interna/32) o VPN/red interna(10.10.2.0/24) 
     - **Destination:** WAN address(192.168.1.2)
     - **Destination port range:** HTTPS (443) o SSH (22)
     - **Description:** "Allow secure remote admin"
  >//Esto Permite que solo direcciones IP autorizadas accedan al firewall desde Internet. Si no se necesita acceso remoto, **no agregar esta regla**.

  3. NAT outbound: Automatic (masquerade para LAN → WAN) → Menú: `Menú: Firewall → NAT → Outbound`
     - Seleccionar **Automatic Outbound NAT**.
 //La LAN (10.10.0.0/24) puede salir a Internet usando la IP de WAN del firewall (192.168.1.2). Esto evita conflictos de rutas y permite conectividad hacia afuera.

  4. VPN </br>
  ⓐ. Importar la CA (ca-cert.pem) → `Ruta: System → Trust → Authorities → Add`
<div align="center">
     <img width="648" height="237" alt="image" src="https://github.com/user-attachments/assets/15b6e07d-b6ec-4417-bbf7-42e3ef1a279a">
</div>

   ⓑ. Importar el certificado del servidor firewall (vpn-gw.cert.pem + vpn-gw.key.pem) → `Ruta: System → Trust → Certificates → Add/Import`
<div align="center">
     <img width="648" height="237" alt="image" src="https://github.com/user-attachments/assets/3c67e92a-0ec3-41b3-9640-6024289832ab" />
</div>
<!-- Activa el servicio IPSec en el firewall. 
⚡ Ojo: el archivo **ca.key.pem** NO se sube al firewall. Esa clave privada de la CA se guarda bajo 7 llaves 🔐. Solo sirve si quieres generar más certificados en la máquina local.
-->

<!-- 
<img width="1190" height="52" alt="image" src="https://github.com/user-attachments/assets/20fe4065-7f80-42e8-9931-f6e44b530941" />

## 🐱 Concatenar certificado e intermediarios para validar el check y me aparezca en verde.

Si mi certificado tiene un intermediario (o solo quiero asegurarme), creo un archivo que contenga primero **mi certificado** y luego **la CA pública**:

```bash
cat vpn-gw-cert.pem ca-cert.pem > vpn-gw-fullchain.pem
```
vpn-gw-cert.pem → mi certificado del gateway 🐶

ca-cert.pem → el certificado público de mi CA 🐹

vpn-gw-fullchain.pem → archivo que OPNsense puede usar para validar toda la cadena 🐰

🐼 Importar el certificado completo en OPNsense
Voy a:

System → Trust → Certificates → +Add
En Certificate data, pego el contenido de vpn-gw-fullchain.pem 🦊

En Private key data, pego mi vpn-gw.key.pem 🐸


Ahora OPNsense tendrá toda la cadena y podrá validar el certificado 🐵.
La GUI debería mostrar el check verde, porque ve que mi certificado está firmado por una CA confiable 🐷.

🐔 Confirmar la validación
Después de subirlo, refresco la lista de certificados 🐧

Si aún veo la X, me aseguro de que la CA esté marcada como trusted en:

System → Trust → Authorities
Una vez hecho esto, la GUI reconocerá mi certificado como válido 🐢.
-->


- Habilitar IPsec/IKEv2
` 
VPN → IPsec → connections → Enable IPsec
` 
<!-- Activa el servicio IPSec en el firewall. -->

- Crear Fase 1 (IKEv2)

  

Interfaz em2 → IP 10.10.2.1

Habilito IPsec/IKEv2

Creo fase 1 (IKEv2):

Remote Gateway: any (clientes)

Authentication: RSA (usar CA ca-cert.pem)

Creo fase 2 (IPsec):

Local subnet: 10.10.1.0/24

Remote subnet: 10.10.2.100-200

NAT: si quiero que los clientes accedan a Internet a través de la VPN, configuro masquerade.

Tip: Activo logs de IPsec para depurar si hay problemas de conexión.

>// Permite tráfico seguro desde LAN hacia Internet, protege segmentos críticos.

### 5️⃣. Integración con Router Core (RT-CORE-01)



