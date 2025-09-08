# RT/SW-CORE-01 — Router/Core Switch

### 1️⃣. Crear VM RT/SW-CORE-01 en VMware

Se añade las interfaces de red y se crea la VM.

>//Crear la máquina virtual que actuará como router/switch core del laboratorio, conectando el IDS, FW-EDGE-01 y los switches internos. Esta VM será la base para enrutar y segmentar el tráfico entre VLANs.

Se descarga [VyOS](https://vyos.net/get/nightly-builds/), y en este caso como es un laboratorio utilizaremos la versión **"Rolling release"** ya que permite
acceder a las últimas características y mejoras de VyOS, ideales para pruebas y desarrollo en un entorno controlado.

Se arranca la máquina con la iso puesta y después de poner las credenciales(vyos), se debe poner **"install image
"** para empezar la instalación.

>//Copia VyOS desde el CD al disco duro virtual y configura GRUB para boot.

