# Http proxy in Dcoker container for development
Durante el desarrollo de aplicaciones web muchas veces es necesario hacer pruebas en dispositivos (móviles, tablets, etc.) distintos del equipo en que estamos haciendo el desarrollo y tenemos levantado un servidor local.

Estas pruebas pueden complicarse aún más en el caso de que algunos de los servicios se consuman a través de una vpn, hagamos uso de nombres de host definidos en el archivo hosts de la máquina de desarrollo, etc.

Haciendo uso de este servidor proxy, podemos probar las aplicaciones desde otros dispositivos como si fuesen el propio equipo de desarrollo, simplemente indicando en los ajustes de conexión del dispositivo que queremos utilizar este proxy.

## 1. Requisitos
- Docker 18.06.0+
- Todos los dispositivos implicados deben estar en la misma red.

## 2. Configuración inicial
Si no lo has hecho aún, clona el repositorio en tu máquina de desarrollo
```
git clone git@github.com:ielizari/dev-proxy.git
```

En el archivo `config/squid.conf` se definen, entre otras cosas, los permisos de acceso. Actualmente está configurado para permitir el acceso al proxy a todos los equipos con IP 192.168.1.xxx

```
acl localnet src 192.168.1.1/8
```
Es posible que necesites cambiar este rango de IPs por uno que se ajuste a tu configuración de red, o incluso usar IPs concretas en lugar de un rango.
Para añadir varias IPs concretas, basta con añadir algo como esto:
```
# acl localnet src 192.168.1.1/8
acl localnet src 192.168.1.10
acl localnet src 192.168.1.9
```
Al reiniciar el contendor, sólo tendrán acceso al proxy las IPs 192.168.1.10 y 192.168.1.9

> :warning: La configuración por defecto permitirá que cualquier equipo conectado la red local con IP entre 192.168.1.0 y 192.168.1.255 pueda utilizar la conexión de tu equipo de desarrollo, incluido el acceso a VPN en caso de estar trabajando con ella. Es recomendable acotar el rango de IPs a las de los dispositivos en los que vas a hacer las pruebas antes de levantar el contenedor Docker. En el futuro se añadirá también la autenticación para poder conectarse al proxy.

## 3. Arrancar el servidor proxy
Desde la carpeta en la que hayas clonado el repositorio ejecuta:
```
docker-compose up
```

## 4. Configurar el proxy en los dispositivos a probar
### 4.1 Android
El modo de activar el uso del proxy puede cambiar dependiendo de la versión de Android y la marca del dispositivo pero, en general, los pasos son los siguientes:
- Ir a Ajustes > Conexiones > WiFi
- Entrar a la configuración de la red WiFi en la que vas a trabajar.
- En las opciones avanzadas, en la sección 'Proxy' selecciona 'Manual'
- Introduce la IP del equipo en el que has levantado el servidor proxy.
- El puerto usado es el 3128
- Guarda los cambios

## 5. TO-DO
- Habilitar la autenticación http en el proxy
- Explorar el uso de la directiva ssl_bump para no tener que aceptar el certificado autofirmado en múltiples urls
- Montar el contenedor a partir de la imagen oficial de Squid

