# IDS/IPS — Suricata en modo Inline

En esta sección voy a montar Suricata para monitorear y bloquear tráfico de la LAN y la DMZ en tiempo real, usando la topología que definimos.

###1️⃣ Creación de la VM e instalación de IDS/IPS

🦴 Creamos una nueva VM con UbuntuServer 25.04 minimal con las siguientes interfaces:
``` bash
eth0 → conexión a FW-EDGE-01 (inline)

eth1 → gestión interna o monitor remoto
```
<!--
Sistema operativo: Ubuntu Server 25.04 minimal.

Recursos recomendados:

CPU: 2 vCPU

RAM: 2–4 GB

Disco: 10–20 GB

interfaces:
eth0 - en modo interna para capturar el tráfico
eth1 - bridge o nat para salir a interner y actualizar el sistema e instalar paquetes.
Interfaces de red:
-->
🦴 Configurar las IPs:

Crear un archivo completamente nuevo desde cero
``` bash
sudo nano /etc/netplan/01-ids-ips.yaml
```
Ponemos lo siguiente:
``` yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens33:
      dhcp4: no
      addresses:
        - 10.10.0.50/24
      gateway4: 10.10.0.1
      nameservers:
        addresses: [10.10.0.1,8.8.8.8]
    ens34:
      dhcp4: yes
```
aplicamos los cambios.
``` bash
sudo netplan apply
```
<!--
Verificar conectividad:

# Ping al firewall
ping -c 3 10.10.0.1

# Ping a Internet (por eth1)
ping -c 3 8.8.8.8
-->

🦴 Instalamos Suricata(motor IDS/IPS)
``` bash
sudo apt update
sudo apt install -y suricata ethtool
```
<!--
suricata → motor IDS/IPS

ethtool → verificar capacidades de la NIC (offloading, promiscuous, etc.)
sudo apt update
sudo apt install -y ethtool
ethtool -k ens33
-->
🦴 Deshabilitar offloading de NIC para asegurar que Suricata inspeccione todo el tráfico:

sudo ethtool -K ens33 gro off gso off tso off

***

### 2️⃣. Configurar Suricata en modo Inline

<!--
Nota rápida: voy a usar AF_PACKET (af-packet) para modo inline porque es directo en entornos Linux y funciona bien en laboratorios. Alternativa: NFQUEUE (iptables → NFQUEUE → Suricata) si quieres más control; lo comento al final. Aquí me centro en AF_PACKET.

- Backup de configuración actual
sudo cp /etc/suricata/suricata.yaml /etc/suricata/suricata.yaml.bak

- Habilitar modo promiscuo (si hace falta)

Si estás en un bridge o mirror, pon la interfaz en promiscuo:

sudo ip link set dev ens33 promisc on

- xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
-->
Edito el archivo principal:
``` bash
sudo nano /etc/suricata/suricata.yaml
```
Cambios principales:
``` yaml
af-packet:
  - interface: ens33
    cluster-id: 99
    cluster-type: cluster_flow
    defrag: yes
    use-mmap: yes
    tpacket-v3: yes
    ring-size: 200000
    block-size: 32768
    block-threads: 1
    buffer-size: 64536
    checksum-checks: no
    copy-iface: false     # NO copiar, trabajar inline, no solo monitoriza, actúa directamente sobre el tráfico.
    bypass: false         # NO permitir bypass -> modo IPS (bloqueo)obliga a Suricata a bloquear paquetes sospechosos.

```
<!--
Explicación rápida de campos claves:

interface: la interfaz física que inspecciona todo el tráfico (aquí ens33).

cluster-id/cluster-type: parámetros para balanceo en entornos con múltiples hilos (deja como está si solo 1).

tpacket-v3, use-mmap: rendimiento y estabilidad.

copy-iface: false: evita copiar paquetes a otra interfaz -> Suricata actúa sobre el flujo real.

bypass: false: obliga a Suricata a NO permitir bypass → modo IPS (cuando una regla es drop, el paquete se bloqueará).

IMPORTANTE: algunos kernels/drivers requieren tpacket-v3: yes para rendimiento y soporte de AF_PACKET en modo inline.
-->
Probamos la configuración de Suricata (sin arrancar todavía)
```
sudo suricata -T -c /etc/suricata/suricata.yaml
```
<img width="1555" height="94" alt="image" src="https://github.com/user-attachments/assets/091052a9-6ecd-4c94-bf00-9c32111a595d" />
Arrancar Suricata en modo af-packet (inline)
Primero en **modo monitor** para validar detecciones (recomiendo empezar aquí):
``` bash
sudo suricata -c /etc/suricata/suricata.yaml -i ens33 --af-packet --pidfile /var/run/suricata.pid
```

Observamos ```/var/log/suricata/fast.log``` y ```/var/log/suricata/eve.json``` para eventos.
<img width="2243" height="166" alt="image" src="https://github.com/user-attachments/assets/666ff71e-c09f-4809-9730-c9a961b498fc" />

Ahora lo arrancamos en modo IPS(bloqueo efectivo):
``` bash
sudo suricata -D -c /etc/suricata/suricata.yaml -i ens33 --af-packet
```
Ver logs y eventos en tiempo real:
``` bash
sudo tail -f /var/log/suricata/fast.log
sudo tail -f /var/log/suricata/eve.json
```
En ```eve.json``` se puede ver los eventos en formato JSON(útil para SIEM), en ```fast.log``` verás resumenes legibles.
<!--
Para Ver si paquetes  los paquetes son bloqueados

Mientras Suricata está en modo IPS y una regla drop dispara, comprueba:

iptables -L -n -v (si tienes reglas iptables relacionadas)

sudo tcpdump -i ens33 -n para comprobar si el tráfico deja de salir

Revisa eve.json para ver el sid y la acción (drop/alert)
-->
***

3️⃣. Reglas de Suricata(descarga, activación y creación de reglas DROP)

🂡. Actualizar/instalar ```suricata-update```:
//Normalmente suricata-update viene con Suricata. Usar para obtener reglas ET Open:
``` bash
sudo apt install -y suricata-update
```

Descargar y aplicar reglas (flujo seguro):

Actualiza fuentes internas
``` bash
sudo suricata-update update-sources
```
Habilitar Emerging Threats Open (ET Open)
``` bash
sudo suricata-update enable-source et/open
```
Descargar y generar las reglas finales usadas por Suricata
``` bash
sudo suricata-update
```

🎯 se generará un fichero de reglas (ej. /var/lib/suricata/rules/suricata.rules) y Suricata leerá esas reglas vía la configuración en suricata.yaml.

---
#### Pruebas de reglas internas

🂱. Revisar / probar reglas descargadas

Lista las reglas principales:
``` bash
sudo ls -lh /var/lib/suricata/rules/
sudo head -n 40 /var/lib/suricata/rules/suricata.rules
```
---

🃁. Crear un fichero de reglas local para pruebas (local.rules)

Creamos ```sudo nano /etc/suricata/rules/local.rules```:
``` yaml
sudo tee /etc/suricata/rules/local.rules > /dev/null <<'EOF'
# regla de prueba: bloquea intentos a SSH (ejemplo laboratorio)
drop tcp any any -> any 22 (msg:"LAB - DROP SSH intento"; sid:1000001; rev:1;)
# regla de prueba: alerta escaneo ping (ejemplo)
alert icmp any any -> any any (msg:"LAB - ICMP ping detectado"; sid:1000002; rev:1;)
EOF
```
Luego incluimos ```local.rules``` en ```suricata.yaml```. Buscamos la sección ```rule-files```: y añadimos ```local.rules```:
``` yaml
rule-files:
  - local.rules
  - suricata.rules
```
---
🃑. Validar sintaxis y cargar reglas

Probar configuración:
``` bash
sudo suricata -T -c /etc/suricata/suricata.yaml
```

reiniciar Suricata (o parar la ejecución actual, detener y volver a iniciar):
``` bash
sudo systemctl restart suricata
```

<!--
# Si lo ejecutaste manualmente: detener proceso y volver a lanzar
  sudo pkill suricata
  sudo suricata -D -c /etc/suricata/suricata.yaml -i ens33 --af-packet

Si quieres ver logs en vivo:
  sudo journalctl -u suricata -f
-->
---

🂮. Probar reglas en laboratorio (tests)
a) Test SSH (regla drop)

Desde una VM atacante en la LAN se intenta conectar por SSH al servidor de pruebas (p. ej. srv-web o al mismo FW):

// desde atacante
``` bash
nc -vz 10.10.1.10 22
```
<!-- o
ssh -o ConnectTimeout=5 usuario@10.10.1.10
-->

>Si la regla drop se disparó, la conexión debe fallar y en eve.json se verá el sid:1000001 con action drop.

> Observamos tcpdump en ens33 para verificar que los paquetes son descartados.

b) Test ICMP (regla alert)
``` bash
ping -c 3 10.10.1.10
```
> Se Debe ver en eve.json la alerta con sid:1000002.
