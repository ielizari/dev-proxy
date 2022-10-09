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

### 2.1 Variables de entorno
Haz una copia del archivo `.env.dist` y renómbrelo como `.env`. En este archivo deberás cambiar la variable HOST_IP introduciendo la ip en tu red local del equipo en el que se va a ejecutar el proxy. Es recomendable también cambiar el password de la variable SQUID_PASS.

### 2.2 Archivo hosts
El servidor proxy utiliza el archivo `config/hosts` para resolver los nombres. Una opción rápida es copiar el contenido del archivo hosts del equipo en el que se va a ejecutar el proxy.
En sistemas Linux y MacOS, este archivo se encuentra en `/etc/hosts`. En sistemas Windows puedes encontrarlo en `C:\Windows\System32\Drivers\etc\hosts`.

En el momento de levantar el contenedor, se sustituirán automáticamente todas las apariciones de `127.0.0.1` por la ip definida en la variable HOST_IP en el paso anterior.
### 2.3 IPs con acceso al proxy
En el archivo `config/squid.conf` se definen, entre otras cosas, los permisos de acceso. Actualmente está configurado para permitir el acceso al proxy a todos los equipos con IP 192.168.1.xxx

```
acl localnet src 192.168.1.1/24
```
Es posible que necesites cambiar este rango de IPs por uno que se ajuste a tu configuración de red, o incluso usar IPs concretas en lugar de un rango.
Para añadir varias IPs concretas, basta con añadir algo como esto:
```
# acl localnet src 192.168.1.1/24
acl localnet src 192.168.1.10
acl localnet src 192.168.1.9
```
Al reiniciar el contendor, sólo tendrán acceso al proxy las IPs 192.168.1.10 y 192.168.1.9

> :warning: La configuración por defecto permitirá que cualquier equipo conectado la red local con IP entre 192.168.1.0 y 192.168.1.255 pueda utilizar la conexión de tu equipo de desarrollo, incluido el acceso a VPN en caso de estar trabajando con ella. Es recomendable acotar el rango de IPs a las de los dispositivos en los que vas a hacer las pruebas antes de levantar el contenedor Docker.

### 2.4 Usuario y contraseña
La autenticación en el proxy mediante usuario y contraseña está activada por defecto. En caso de querer desactivarla, bastará con comentar la siguiente línea en el archivo `config/squid.conf`:
```
http_access deny !auth_users
```

### 2.5 Puerto
Al utilizar el modo `network_mode: host` no se definen los puertos en el archivo docker-compose.yml. De hecho en versiones de docker-compose superiores a la 1.24 se mostrará un error si intentamos hacer el port binding.

Para cambiar el puerto en el que queremos que funcione el proxy, deberemos editar el archivo `config/squid.conf` en la siguiente línea:
```
http_port 3128
```
Después de hacer el cambio será necesario reiniciar el contenedor, o reiniciar el servicio desde dentro del contendor.

En el caso de tener activo un firewall y/o antivirus, asegurarse de que no se esté bloqueando el puerto seleccionado.
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

## 5. Comandos útiles
### 5.1 Acceso shell al contenedor
```
docker exec -it squid-proxy bash
```
### 5.2 Reconstruir el contenedor
El ususario y password de acceso al proxy se generan durante la fase build del contenedor. Esta fase sólo se ejecuta la primera vez que levantamos el contendor, por lo que si queremos cambiar la contraseña, o añadir más usuarios será necesario volver a recrear el contenedor. Esto puede hacerse con el siguiente comando:
```
docker-compose up --build --force-recreate
```
En caso de que no nos esté cogiendo la nueva contraseña, es posible que docker esté utilizando datos cacheados. Para evitarlo, se puede reconstruir el contenedor con los siguientes comandos.
```
docker-compose build --no-cache
docker-compose up
```
### 5.3 Generar nuevos usuarios y contraseñas
Si queremos añadir nuevos usuarios o cambiar contraseñas sin tener que reconstruir el contendor, podemos hacerlo utilizando el comando visto en el punto 5.1 para obtener una shell dentro del contenedor y ejecutar:
```
htpasswd /etc/squid/users_passwd USUARIO
```
Por defecto sólo se tiene en cuenta el usuario `proxy`. En el archivo `config/squid.conf` tendremos que añadir los nuevos usuarios en la línea:
```
acl auth_users proxy_auth proxy USUARIO
```
## 6. TO-DO
- Explorar el uso de la directiva ssl_bump para no tener que aceptar el certificado autofirmado en múltiples urls
- Montar el contenedor a partir de la imagen oficial de Squid

