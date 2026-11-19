# SIRAM - Sistema de Respuesta a Emergencias (App Móvil)

Aplicación móvil construida en **Flutter** para el reporte instantáneo de situaciones de emergencia (Accidentes de tránsito, Incendios, Hurtos, Sismos, Inundaciones, entre otros). Conecta directamente con la arquitectura distribuida de microservicios de **SIRAM** mediante un API Gateway GraphQL.

## Requisitos Previos

Antes de clonar y ejecutar este proyecto, asegúrate de contar con lo siguiente instalado en tu equipo:

1. **Flutter SDK** (Versión 3.x o superior): [Guía de instalación de Flutter](https://docs.flutter.dev/get-started/install)

2. **Android Studio** (Con soporte para Flutter y Dart plugins habilitados).

3. **Android SDK / NDK**: La app requiere Android SDK y NDK versión `27.0.12077973` (Android Studio lo descargará automáticamente si es necesario).

4. **Backend SIRAM en ejecución**: Los microservicios desplegados en Docker Desktop (`graphql-gateway`, `emergencias-service`, `notificacion-service`, `kafka`, `postgres`).

## Guía Paso a Paso para Ejecutar en Android Studio

### Paso 1: Clonar el Repositorio

Abre la terminal o Git Bash y ejecuta:

```
git clone https://github.com/TU_USUARIO/siram_app.git
cd siram_app
```

### Paso 2: Abrir en Android Studio

1. Inicia **Android Studio**.

2. Selecciona **Open** (o **File > Open...**).

3. Busca la carpeta donde clonaste el proyecto (`siram_app`) y presiona **OK**.

4. Espera a que Android Studio termine de indexar el proyecto.

### Paso 3: Instalar Dependencias

Abre la terminal integrada en Android Studio (**Terminal** en la parte inferior) o tu terminal de sistema y ejecuta:

```
flutter pub get
```

*Esto descargará paquetes clave como `geolocator` para el rastreo GPS y `http` para las consultas GraphQL.*

## Configuración Única: Dirección IP del Backend

Por defecto, la aplicación se conecta a una IP local configurada en `lib/services/siram_graphql_service.dart`. Cada desarrollador debe ajustar este parámetro según su entorno de pruebas:

Abre el archivo `lib/services/siram_graphql_service.dart` y localiza la variable del punto de enlace:

```dart
// Modifica la dirección según tu caso de uso:
static const String _graphqlUrl = 'http://<TU_IP_O_HOST>:8080/graphql';
```

### Casos de prueba:

* **Opción A: Probando en un Celular Físico (vía Wi-Fi)**

  1. Conecta tu teléfono y tu PC a la **misma red Wi-Fi**.

  2. Obtén la IP local de tu PC (en Windows abre CMD y ejecuta `ipconfig`; busca la *Dirección IPv4*, por ejemplo `192.168.1.15`).

  3. Reemplaza la URL en el archivo:

     ```dart
     static const String _graphqlUrl = 'http://192.168.1.15:8080/graphql';
     ```

* **Opción B: Probando en el Emulador Oficial de Android Studio**

  1. Si ejecutas Docker y el emulador en la misma máquina, usa la IP especial del puente de Android:

     ```dart
     static const String _graphqlUrl = 'http://10.0.2.2:8080/graphql';
     ```

## Compilar y Ejecutar

1. **Conecta tu dispositivo:**

   * **Físico:** Activa la *Depuración por USB* en las opciones de desarrollador del celular y conéctalo por cable USB.

   * **Emulador:** Abre el **Device Manager** en Android Studio e inicia un emulador Android (AVD).

2. Selecciona tu dispositivo en la barra superior de Android Studio (junto al botón de reproducción).

3. Presiona el botón **Run (`▶`)** o presiona `Shift + F10`.

## Permisos y Seguridad de Ubicación

La app incluye una pantalla guardián (`PermisoUbicacionGate`) que exige acceso obligatorio al chip GPS del dispositivo:

* Si el GPS del dispositivo está desactivado o el usuario deniega el permiso de ubicación, la aplicación despliega un cuadro modal de bloqueo que impide el acceso a las funciones de reporte.

* Incluye acceso directo a los ajustes del sistema para habilitar la ubicación en caso de bloqueo permanente.

## Integración con Microservicios

La aplicación interactúa con la infraestructura distribuida de SIRAM:

```
[ App Móvil Flutter ] 
        │ (HTTP / GraphQL)
        ▼
[ siram-graphql-gateway :8080 ]
        │ 
        ├─► [ siram-emergencias-service :8081 ] ──► [ PostgreSQL :5432 ]
        │            │
        │            └─► (Publica en Kafka :9092)
        │                      │
        └──────────────────────┼─► [ siram-notificacion-service :8082 ]
```

* **Gateway:** `siram-graphql-gateway` en el puerto `8080`.

* **Mutación enviada:** `reportarIncidente(tipo, latitud, longitud)`

* **Consulta enviada:** `obtenerIncidentes(filtroTipo)`

## Solución a Problemas Comunes

* **Error: `SocketException` o Conexión rehusada al enviar reporte:**

  * Verifica que la PC y el celular estén en la misma red Wi-Fi.

  * Confirma que el puerto `8080` de tu PC no esté bloqueado por el Firewall de Windows.

* **Error: `INTERNAL_ERROR` al reportar:**

  * Revisa los logs de Docker en tu PC (`docker compose logs -f emergencias-service`) para verificar que PostgreSQL y Kafka estén respondiendo.

* **Fallo en compilación Gradle / NDK:**

  * Ejecute `flutter clean` y luego `flutter pub get`. Asegúrate de tener conexión a Internet para que Gradle descargue las dependencias del NDK 27.