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

[Archivo Conf WEB-MAIL-DNS](config/DMZ)

Aplico cambios:
``` bash
sudo netplan apply
```
<!-- Verifico conectividad:
ping 10.10.3.1
ping 8.8.8.8
-->

---

### 2️⃣. Instalación del Servidor WEB(Apache)

Este paso sirve para mostrar contenido HTTP/HTTPS a clientes externos.

```
sudo apt update && sudo apt install -y apache2 php libapache2-mod-php
```
Verifico el estado:
```
sudo systemctl status apache2
```

Coloco un archivo de prueba:
```
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php
```

Desde otro host:
```
curl http://10.10.3.10/info.php
```

--- 

### 3️⃣. Instalación del Servidor de Correo(Postfix)

Este paso sirve para configurar un servidor de correo básico con Postfix y Dovecot.
``` bash
sudo apt update && sudo apt install -y postfix dovecot-imapd dovecot-pop3d
```

Durante la instalación de Postfix:
- Tipo de configuración: Internet Site
- Nombre de dominio: lab.local


Verifico servicios:
``` bash
sudo systemctl status postfix
sudo systemctl status dovecot
```

Creo un usuario de prueba:
``` bash
sudo adduser prueba
echo "correo de prueba" | mail -s "Test DMZ" prueba@lab.local
```

Verifico recepción:
```
mail
```
<img width="1478" height="158" alt="Screenshot from 2025-11-03 11-01-51" src="https://github.com/user-attachments/assets/1a962579-a40c-4f6e-a5be-f7beb591d1c5" />

---

### 4️⃣. Instalación del Servidor DNS(Bind9)

Este paso sirve para implementar un servidor DNS maestro con Bind9.
``` bash
sudo apt update && sudo apt install -y bind9 bind9-utils
```

Edito el archivo de zona local:
``` bash
sudo nano /etc/bind/named.conf.local
```

Agrego:
``` yaml
zone "lab.local" {
    type master;
    file "/etc/bind/db.lab.local";
};
```

Creo el archivo de zona:
``` bash
sudo cp /etc/bind/db.local /etc/bind/db.lab.local
sudo nano /etc/bind/db.lab.local
```

Contenido:
``` yaml
$TTL    604800
@       IN      SOA     ns1.lab.local. admin.lab.local. (
                        2         ; Serial
                        604800    ; Refresh
                        86400     ; Retry
                        2419200   ; Expire
                        604800 )  ; Negative Cache TTL
;
@       IN      NS      ns1.lab.local.
ns1     IN      A       10.10.3.12
web     IN      A       10.10.3.10
mail    IN      A       10.10.3.11
```

Reinicio Bind9:
``` bash
sudo systemctl restart bind9
sudo systemctl status bind9
```

Pruebo resolución:
``` bash
dig @10.10.3.12 web.lab.local
dig @10.10.3.12 mail.lab.local
```
<img width="500" height="200" alt="Screenshot from 2025-11-03 11-30-09" src="https://github.com/user-attachments/assets/cb8e81c3-14d0-45e8-878e-c509301177d1" />

<img width="500" height="200" alt="Screenshot from 2025-11-03 11-30-26" src="https://github.com/user-attachments/assets/0707e6d4-9409-4792-aa45-d032e382b667" />

---

### 5️⃣. Verificación General

Desde una máquina cliente LAN:
``` bash
ping 10.10.3.10
ping 10.10.3.11
ping 10.10.3.12
```
Verificación de resolución DNS -- Compruebo que el servidor DNS responde y resuelve las zonas configuradas:

``` bash
nslookup web.lab.local 10.10.3.12
nslookup mail.lab.local 10.10.3.12
nslookup ns1.lab.local 10.10.3.12
```
Verificación de servicio WEB
```
curl http://10.10.3.10
curl http://web.lab.local
```
Pruebas de servicio de correo
``` bash
telnet 10.10.3.11 25
220 mail.lab.local ESMTP Postfix
```
Y verifico que Dovecot esté escuchando:

``` bash
sudo ss -tuln | grep dovecot
```

Todo debe resolver correctamente. Con esto, la zona DMZ queda operativa con tres servicios esenciales: WEB, MAIL y DNS, completamente segmentados y controlados a través del FW-EDGE-01 y monitoreados por el IDS/IPS Inline.
### 🧩 Resultado Final – Estado de los Servidores DMZ

| 🖥️ **Máquina**   | 🌐 **Dirección IP** | ⚙️ **Servicio Principal**  | 🟢 **Estado**     |
|------------------|--------------------|----------------------------|------------------|
| SRV-DMZ-WEB     | `10.10.3.10`       | Apache2 + PHP              | ✅ Operativo     |
| SRV-DMZ-MAIL    | `10.10.3.11`       | Postfix + Dovecot          | ✅ Operativo     |
| SRV-DMZ-DNS     | `10.10.3.12`       | Bind9 (DNS Maestro)        | ✅ Operativo     |

La zona DMZ se encuentra plenamente funcional, con tres servicios clave desplegados en entornos aislados. Todos los hosts responden correctamente, resuelven nombres, y el tráfico es inspeccionado por el IDS/IPS Inline antes de alcanzar los servidores.
