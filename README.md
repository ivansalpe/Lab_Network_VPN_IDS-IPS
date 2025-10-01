<div align="center">
<i></b><h2>  🌐 Laboratorio de Red Profesional – VPN + IDS/IPS (documentation in Spanish)</i></b></h2> 
</div>

<i></b>📖 Descripción del Proyecto</i></b>

Soy ivansalpe y he diseñado este laboratorio de red con el objetivo de demostrar mis habilidades en seguridad informática, redes y virtualización. La topología implementada incluye:

- 🔥 Un firewall de perímetro (FW-EDGE-01) con OPNsense.

- 🛡️ Un IDS/IPS inline (Suricata) dedicado, que inspecciona y bloquea tráfico en tiempo real.

- 🖧 Un núcleo de red con routers/switches virtualizados para segmentar VLANs.

- 🌍 Una DMZ para servicios públicos expuestos.

- 🔑 Una VPN (IPsec/IKEv2) para acceso remoto seguro.

Este proyecto busca simular un entorno empresarial real, combinando seguridad perimetral, segmentación y monitorización avanzada de amenazas.

---

<i></b>📊 Topología de Red</i></b>
```mermaid

graph TD
    %% Clases de colores
    classDef internet fill:#f2f2f2,stroke:#000,stroke-width:1px;
    classDef core fill:#52A1C0,stroke:#000,stroke-width:1px;
    classDef vpn fill:#ffd699,stroke:#000,stroke-width:1px;
    classDef dmz fill:#d1e7dd,stroke:#000,stroke-width:1px;
    classDef fw fill:#ff9999,stroke:#000,stroke-width:2px;
    classDef ids fill:#8A6182,stroke:#000,stroke-width:2px;

    %% Nodos con iconos
    Internet["Ⓐ 🌐 Internet<br>192.168.1.1/24"]
    FW["Ⓑ 🔥 FW-EDGE-01<br>em0:192.168.1.2<br>em1:10.10.0.1<br>em2:10.10.2.1<br>em3:10.10.3.1"]
    IDS["Ⓒ 🛡️ IDS/IPS Inline<br>br-inline: 10.10.0.50/24<br>ens33 ↔ Core<br>ens34 ↔ FW"]
    Core["Ⓓ 🖧 RT/SW-CORE-01<br>10.10.0.2 / 10.10.1.1"]
    SWC["Ⓔ 🖧 SW-CORE-02<br>10.10.1.2"]

    WEB["Ⓕ 💻 SRV-WEB<br>10.10.1.10"]
    DB["Ⓖ 🗄️ SRV-DB<br>10.10.1.11"]
    APP["Ⓗ ⚙️ SRV-APP<br>10.10.1.12"]

    VPN["Ⓘ 🔑 VPN-GW<br>10.10.2.10"]

    DMZWEB["Ⓙ 🌍 DMZ-WEB<br>10.10.3.10"]
    DMZMAIL["Ⓚ 📧 DMZ-MAIL<br>10.10.3.11"]
    DMZDNS["Ⓛ 📡 DMZ-DNS<br>10.10.3.12"]

    %% Conexiones
    Internet ---|"em0 (WAN)"| FW
    FW ---|"em1 (LAN)"| IDS
    IDS ---|"ens33 → ens34"| Core
    Core ---|"VLAN1"| SWC
    SWC ---|"VLAN1"| WEB
    SWC ---|"VLAN1"| DB
    SWC ---|"VLAN1"| APP

    FW ---|"em2 (VPN)"| VPN
    FW ---|"em3 (DMZ)"| DMZWEB
    FW ---|"em3 (DMZ)"| DMZMAIL
    FW ---|"em3 (DMZ)"| DMZDNS

    %% Clases
    class Internet internet;
    class FW fw;
    class IDS ids;
    class Core,SWC,WEB,DB,APP core;
    class VPN vpn;
    class DMZWEB,DMZMAIL,DMZDNS dmz;
```
---

<i></b>🛠️ Componentes del Laboratorio</i></b>
| Componente                | Función / Rol                                                                 |
|----------------------------|-------------------------------------------------------------------------------|
| FW-EDGE-01 (OPNsense)      | Firewall perimetral, NAT, control de tráfico, terminación de VPN IKEv2/IPsec |
| IDS/IPS Inline (Suricata)  | Inspección profunda de paquetes, aplicación de reglas ET Open, bloqueo de amenazas |
| RT/SW-CORE-01              | Routing interno y manejo de VLANs entre LAN, DMZ y VPN                       |
| SW-CORE-02                 | Switch de distribución en VLAN1                                              |
| Servidores LAN             | WEB, DB, APP — servicios internos críticos                                   |
| Servidores DMZ             | WEB, MAIL, DNS — servicios expuestos y monitorizados                         |
| VPN-GW / Clientes VPN      | Acceso remoto seguro, con opción de NAT hacia Internet                       |

---

<i></b>🎯 Objetivos del Proyecto</i></b>

🔹 Simular un entorno empresarial real con seguridad perimetral y segmentación de red.

🔹 Demostrar habilidades en:

- 🔐 VPNs seguras (IKEv2/IPsec)

- 🛡️ Detección y respuesta ante amenazas (Suricata)

- 🖧 Diseño y operación de VLANs

🔹 Documentar el laboratorio de forma clara y profesional para portafolios

---

<i></b>🛠️ Modos de Operación</i></b>

- FW-EDGE-01: Segmentación de red, NAT, VPN IKEv2, reglas de firewall

- IDS/IPS Inline: Análisis y bloqueo de tráfico LAN/DMZ/VPN, reglas ET Open

- Core / Switches: VLANs separadas (LAN, VPN, DMZ) y enrutamiento interno

- Servidores LAN y DMZ: Servicios internos y públicos, protegidos por FW e inspeccionados por IDS/IPS

- VPN-GW / Clientes VPN: Conexión remota segura, NAT opcional para Internet

---

<i></b>📝 Manual Paso a Paso</i></b>

1️⃣ FW-EDGE-01 (OPNsense)

[Parte Firewall](docs/01_firewall.md)

2️⃣ IDS/IPS Inline (Suricata) 

[Parte IDSs-IPS](docs/02_ids-ips.md)

3️⃣ Core Router/Switch y servidores internos(VLAN) <br>

[Parte Router](docs/03a_router.md)

[Parte Switch](docs/03b_switch.md)

4️⃣ VPN-GW - Clientes VPN<br>

[Parte VPN](docs/04_vpn.md)

5️⃣ DMZ  <br>

[Parte DMZ](docs/05_dmz.md)

---

<i></b>🧾 Notas Finales</i></b>

- IDS/IPS en modo inline entre FW y Core → inspección total de tráfico.

- VLANs separadas para LAN (10.10.1.0/24), DMZ (10.10.3.0/24), VPN (10.10.2.0/24).

- FW-EDGE-01 gestiona VPN remoto y NAT si es necesario para acceso a Internet.

- Logs de Suricata y FW activos para auditoría y depuración.

- Topología refleja entorno real de empresa, perfecta para portafolios de redes y seguridad.
