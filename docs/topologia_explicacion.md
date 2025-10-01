# Topología de Red

## 1. Internet
- Nodo simulado que representa la conexión externa hacia el mundo.
- Solo se conecta al firewall perimetral (**FW-EDGE-01**).
- **Función:** Entrada/salida de tráfico simulado hacia la red interna y DMZ.

## 2. FW-EDGE-01 (Firewall perimetral)
- Conecta Internet con la red interna.
- **Interfaces:**
  - `eth0` → Internet (`192.168.2.1/24`)
  - `eth1` → Red interna Core (`10.10.0.1/24`)
- **Función:**
  - Controla qué tráfico externo entra y sale.
  - Realiza NAT para que los servidores internos puedan acceder a Internet sin exponer sus IP privadas.
  - Primer punto de seguridad: bloquea tráfico no autorizado.

## 3. RT-CORE-01 (Router core)
- Conecta firewall con los switches internos.
- **Interfaces:**
  - `eth0` → Firewall (`10.10.0.2/24`)
  - `eth1` → Switch Core (`10.10.1.1/24`)
- **Función:**
  - Rutea tráfico entre la red interna (Core), la VPN y la DMZ.
  - Puede manejar rutas estáticas o dinámicas (OSPF, RIP).
  - Es el backbone que conecta todas las VLAN internas.

## 4. SW-CORE-01 (Switch Core)
- Conecta los servidores internos: Web, DB y App.
- VLAN1: red interna corporativa (`10.10.1.0/24`).
- **Función:**
  - Distribuye tráfico interno entre los servidores.
  - Separa la red interna de la VPN y la DMZ mediante VLANs.

## 5. Servidores internos (WEB, DB, APP)
- Dirección IP dentro de la VLAN Core (`10.10.1.x`).
- Gateway: RT-CORE-01 (`10.10.1.1`).
- **Función:**
  - `SRV-WEB`: servidor web interno, puede alojar aplicaciones internas.
  - `SRV-DB`: base de datos interna, no accesible desde Internet.
  - `SRV-APP`: servidor de aplicaciones, se comunica con Web y DB.
- Esta segmentación protege los datos internos frente a accesos externos.

## 6. SW-VPN-01 y VPN-GW-01
- VLAN2: red dedicada a VPN (`10.10.2.0/24`).
- **VPN-GW-01:** permite conexiones remotas seguras desde usuarios o sedes externas.
- **SW-VPN-01:** distribuye tráfico VPN a IDS/IPS y hacia el Core si es necesario.
- **Función:**
  - Asegurar que el tráfico remoto entre de manera cifrada y controlada.
  - La VPN actúa como puente seguro hacia la red interna.

## 7. IDS-IPS-01
- Conectado entre la VPN y la DMZ.
- **Función:**
  - IDS (Intrusion Detection System): detecta tráfico sospechoso o ataques.
  - IPS (Intrusion Prevention System): puede bloquear tráfico malicioso en tiempo real.
- Protege la DMZ y la red interna frente a amenazas externas, especialmente desde la VPN.

## 8. SW-DMZ-01 y servidores DMZ (WEB, MAIL, DNS)
- VLAN3: red DMZ (`10.10.3.0/24`).
- **Función:**
  - `DMZ-WEB`: servidor web accesible desde Internet (público).
  - `DMZ-MAIL`: servidor de correo electrónico.
  - `DMZ-DNS`: servidor DNS para resolución de nombres públicos.
- El switch DMZ aísla estos servidores del Core interno.
- Todo tráfico hacia/desde DMZ pasa por IDS/IPS y firewall.

## 9. Flujo de tráfico resumido
- Tráfico externo hacia Internet → llega a FW-EDGE-01 → decide si pasa a DMZ o bloquea.
- Usuarios VPN remotos → entran por VPN-GW-01 → inspeccionados por IDS/IPS → acceden a la red interna si tienen permisos.
- Servidores internos → comunicación segura dentro de VLAN1, sin exponer IPs a Internet.
- DMZ → servidores públicos (web, mail, DNS) aislados del Core para seguridad.

## Resumen general
- Segmentación por VLANs: Core (interna), VPN (remota), DMZ (pública).
- Firewall y NAT protegen la red interna.
- VPN + IDS/IPS controlan acceso remoto y tráfico sospechoso.
- DMZ mantiene servicios públicos aislados del Core interno.

