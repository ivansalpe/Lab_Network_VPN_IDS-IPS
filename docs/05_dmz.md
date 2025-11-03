# DMZ

### 1️⃣. Instalación y Configuración — Máquinas DMZ (WEB / MAIL / DNS)

Voy a crear **tres máquinas virtuales Ubuntu Server 24.04 LTS** en VMware que formarán la DMZ:
- **SRV-DMZ-WEB** → 10.10.3.10 (Apache)
- **SRV-DMZ-MAIL** → 10.10.3.11 (Postfix)
- **SRV-DMZ-DNS** → 10.10.3.12 (Bind9)

Conectaré cada VM a la red virtual **DMZ** (la interfaz em3 del firewall OPNsense: 10.10.3.1/24). Luego configuraré los servicios, reglas en el firewall y pruebas.

<!--
**Crear VM:**
   - Nombre: `SRV-DMZ-WEB`,  `SRV-DMZ-MAIL`, `SRV-DMZ-DNS`
   - Guest OS: Ubuntu 24.04 (Linux)
   - CPU: 1 vCPU (puedo poner 2 si quiero)
   - RAM: 1–2 GB
   - Disco: 10 GB (provisionado dinámico)
   - NIC: 1 NIC **conectada a la red DMZ** (Network/Port Group: `DMZ`)
-->
Configuro la IP estática (netplan)

Edito `/etc/netplan/01-netcfg.yaml` (si no existe, lo creo):

[Archivo Conf WEB/MAIL/DNS](config/DMZ)

Aplico cambios:
``` bash
sudo netplan apply
```
<!-- Verifico conectividad:
ping 10.10.3.1
ping 8.8.8.8
-->

---

2️⃣. Instalación del Servidor WEB(Apache)

3️⃣. Instalación del Servidor de Correo(Postfix)

4️⃣. Instalación del Servidor DNS(Bind9)

5️⃣. Verificación General


