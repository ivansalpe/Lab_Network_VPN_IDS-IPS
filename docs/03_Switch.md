# SW-CORE-02 — Switch Core y Servidores Internos

El objetivo de crear una VM ligera que actúe como switch virtual / bridge para la LAN (10.10.1.0/24). Hardware mínimo y red correctamente mapeada para conectar servidores internos.

### 1️⃣. Crear la VM SW-CORE-02 en VMware

Lo primero es preparar y configurar el entorno, descargo la iso de [Alpine Linux](https://www.alpinelinux.org/?utm_source=chatgpt.com) que es la distribución de linux que voy a utilizar ya que es ligera y empiezo a preparar la interfaz de red(VMnet2 -- 10.10.1.0/24) en modo "host only".

