
Lo Primero es Configurar los entornos virtuales, para eso en VMware en "virtual-network-editor se añade la siguiente información <...>.

# FW_EDGE_01 — Firewall de borde (OPNsense) 
### 1️⃣. Instalar OPNsense
Descargar la iso e instalar el firewall [OPNsense](https://opnsense.org/download/). <!-- https://docs.opnsense.org/manual/how-tos/ipsec-rw-srv-mschapv2.html -->
- Usuario: `installer`  
- Password: `opnsense`  
Esto te da acceso al instalador.
Recomendable elegir la opción `ZFS` como sistema de  archivos ya que es mas avanzado.
Recomendable cambiar la contraseña.
---
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

---

### 3️⃣. Configuración inicial via GUI
En el navegador → https://10.10.0.1
Se entra en "wizard" y se empieza a configurar:
     - Hostname: `fw-edge-01`
     - Timezone: ajustar a tu región.
     - DNS: `8.8.8.8 / 1.1.1.1` (opcional interno).
     - Activar SSH para gestión remota segura.
     - Cambiar contraseña admin por una fuerte.
---
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
ⓒ. 🔐 Fase 1: Establecimiento de la conexión segura(IPsec/IKEv2)
Accedo a la interfaz web de OPNsense y navego a: `VPN → IPsec → connections → + Add Phase 1` 
 
-- General settings (fase 1 básica)
 
| Campo             | Valor / Configuración                                                                 |
|-------------------|---------------------------------------------------------------------------------------|
| **Name / Description** | `VPN-Clients‐IKEv2`                                                              |
| **Version**       | `IKEv2`                                                                               |
| **Interface**     | `em2` (interfaz donde la IP = `10.10.2.1`)                                            |
| **Remote addresses** | `any` (aceptar clientes remotos)                                                   |
| **Local addresses**  | vacío ó `10.10.2.1` (IP del firewall en esa interfaz, si OPNsense lo exige)        |

-- Autenticación (fase 1)

- **Local Authentication**: Certificates→ selecciona el certificado servidor `VPN-GW`  
- **Remote Authentication**: Certificate Authorities → selecciona `VPN-CA`

ⓓ. 🔐 Fase 2: Configuración del túnel IPsec

Vamos a crear un alias ya que opnsense no deja introducir rangos de ip con la "-", para eso se requiere crear un alias en: `menú: Firewall → Aliases`.

| Campo       | Valor / Configuración                                                                 |
|-------------|---------------------------------------------------------------------------------------|
| **Name**    | `VPN_RANGE_100_200`                                                                  |
| **Type**    | `Network(s)`                                                                          |
| **Content** | 10.10.2.100/30<br>10.10.2.104/29<br>10.10.2.112/28<br>10.10.2.128/26<br>10.10.2.192/29 |

- Añade un *child* (o sección “Children”) dentro de la Connection de la fase 1 para definir la fase 2.

<!-- 
10.10.2.200/32 
— Virtual Tunnel Interface (si lo necesitas)

- Solo si se usa el modo **route-based / VTI** → crea una interfaz virtual en **VPN → IPsec → Virtual Tunnel Interfaces**  
- Asigna un **reqid** único, y direcciones para el túnel si se requiere tráfico Enrutado.  
- En este caso, si solo es clientes remotos, no se necesita configurar VTI, salvo que requiera que el túnel aparezca como interfaz local para rutas específicas.--> 
- A los campos del child:

  | Campo | Valor |
  |---|---|
  | **Mode** | Tunnel IPv4 |
  | **Local Network / Local Traffic Selector** | `10.10.1.0/24` |
  | **Remote Network / Remote Traffic Selector** | `VPN_RANGE_100_200` #este es el nombre del alias que se debe crear anteriormente |
  | **Encryption / ESP proposals** | AES256 + SHA256 (o AES-GCM si lo prefieres) |
  | **PFS / Key Exchange Group** | 14 |
  | **Lifetime** | ~ 3600 segundos |

ⓔ. Reglas de Firewall y NAT
Se debe añadir una serie de reglas, ya que si no se configuran las reglas correctamente, los clientes VPN no podrán comunicarse ni con la LAN ni con Internet.

- **Firewall → Rules → WAN**: permitir UDP/500, UDP/4500 y protocolo ESP hacia IP `em2`.  
- **Firewall → Rules → IPsec / Interface IPsec**: permitir tráfico entrante desde rango `10.10.2.100-200` hacia LAN `10.10.1.0/24`.  
- **Outbound NAT**: si los clientes deben acceder a Internet a través de VPN, configura NAT (masquerade) con Source = `10.10.2.100-200`.
  
- 🔹 Se añade una nueva regla en  `Firewall → Rules → WAN` con los siguientes campos:

| Campo | Valor |
|-------|-------|
| Action | Pass |
| Interface | WAN |
| Protocol | UDP |
| Source | any |
| Source Port Range | any |
| Destination | WAN Address ('10.10.2.1/32' # IP del FW em2) |
| Destination Port Range | 500 - 4500 (incluye IKE y NAT-T) |
| Description | `Allow IPsec VPN` |

> 💡 Esto permite que los clientes VPN remotos puedan iniciar la conexión IKEv2.

- 🔹 Se añade otra nueva regla pero esta vez en  `Firewall → Rules → IPsec` con los siguientes campos:


| Campo | Valor |
|-------|-------|
| Action | Pass |
| Interface | IPsec |
| Protocol | any |
| Source | 10.10.2.100 - 10.10.2.200 (pool de clientes VPN) |
| Destination | 10.10.1.0/24 (LAN interna) |
| Description | `Allow VPN clients to LAN` |


> 💡 Esto permite que los clientes VPN accedan a la red interna del laboratorio.

- 🔹 Se Cambia el **mode** a `Hybrid Outbound NAT rule generation` o `Manual Outbound NAT` . Se añade una nueva regla en  `Firewall → NAT → Outbound` con los siguientes campos:

| Campo | Valor |
|-------|-------|
| Interface | WAN |
| Source | 10.10.2.100 - 10.10.2.200 |
| Source Port | any |
| Destination | any |
| Translation / target | Interface Address |
| Description | `Masquerade VPN clients to Internet` |

> 💡 Esto permite que los clientes VPN puedan salir a Internet usando la IP pública del firewall.

<!-- 
🔹 Verificación rápida

- Conéctate con un cliente VPN y prueba:
- `ping 10.10.1.10` → SRV-WEB  
- `ping 10.10.1.11` → SRV-DB  
- `ping 8.8.8.8` → acceso a Internet (si NAT activo)  

- Revisa logs en:
VPN → IPsec → Log File
Firewall → Log File
-->

5. DMZ </br>

---

### 5️⃣. Integración con Router Core (RT-CORE-01)



