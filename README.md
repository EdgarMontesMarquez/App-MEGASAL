# Sales y Premesclas del Caribe "MEGASAL"

Este es un proyecto de aplicación móvil desarrollado con Flutter para la gestión de clientes, facturas y pagos de "Sales y Premesclas del Caribe MEGASAL". La aplicación está diseñada para operar de forma completamente local, sin necesidad de conexión a internet o servicios en la nube, guardando toda la información de manera segura en el dispositivo del usuario.

## Características

-   *Gestión de Clientes:* Registra, consulta y edita la información de tus clientes. Visualiza de un vistazo la deuda pendiente de cada uno.
-   *Generación de Facturas:* Crea facturas detalladas en formato PDF, incluyendo datos del cliente, del transportista (conductor y vehículo) y una lista de productos vendidos.
-   *Control de Abonos y Deudas:* La aplicación permite registrar abonos a las deudas de los clientes. El saldo pendiente se actualiza automáticamente y se mantiene un historial de todos los pagos realizados.
-   *Historial de Facturas:* Accede a un historial de todas las facturas generadas, las cuales se almacenan en formato PDF en el almacenamiento local del dispositivo para fácil acceso y compartición.
-   *Funcionamiento 100% Offline:* Todas las funcionalidades son accesibles sin conexión a internet, lo que la hace ideal para uso en campo o en zonas con conectividad limitada.

## Tecnologías y Librerías Utilizadas

El proyecto fue desarrollado principalmente con Flutter, utilizando una variedad de lenguajes para cubrir las plataformas nativas de Android e iOS.

-   *Flutter (Dart):* Framework principal para la interfaz de usuario y la lógica de la aplicación.
-   *C++ y C:* Utilizados para la implementación de ciertas funcionalidades nativas y el uso de librerías de bajo nivel.
-   *CMake:* Sistema de compilación utilizado para gestionar el código nativo de las plataformas.
-   *Swift:* Empleado para el desarrollo nativo en la plataforma iOS.
-   *Almacenamiento Local:* Se utiliza una base de datos local para la persistencia de los datos de clientes, abonos y facturas.
-   *Generación de PDF:* Librería para crear y exportar las facturas en formato PDF.

## Capturas de Pantalla

| Vista de Clientes | Agregar Cliente | Detalles del Cliente | Historial de Facturas |
| :---: | :---: | :---: | :---: |
| ![Lista de Clientes](https://imgur.com/a/BD1loM2) | ![Agregar Cliente](https://imgur.com/a/AFy4JJ5) | ![Detalles del Cliente](https://imgur.com/a/qDzD9wl) | ![Historial de Facturas](https://imgur.com/a/TzqIez7) |
| Muestra la lista de clientes registrados, indicando quién tiene deuda. | Formulario para registrar un nuevo cliente con sus datos de compra. | Permite ver el detalle de un cliente y agregar abonos a su deuda. | Lista de las facturas generadas, guardadas localmente en PDF. |

## Cómo Empezar

Sigue estos pasos para tener una copia local del proyecto en funcionamiento.

### Prerrequisitos

-   Tener instalado [Flutter SDK](https://docs.flutter.dev/get-started/install).
-   Tener un emulador de Android/iOS o un dispositivo conectado.

### Instalación

1.  Clona el repositorio:

    bash
    git clone [https://github.com/tu-usuario/nombre-del-repositorio.git]([https://github.com/tu-usuario/nombre-del-repositorio.git](https://github.com/EdgarMontesMarquez/App-MEGASAL.git))
    

2.  Navega al directorio del proyecto:

    bash
    cd nombre-del-repositorio
    

3.  Instala las dependencias del proyecto:

    bash
    flutter pub get
    

4.  Ejecuta la aplicación en tu dispositivo o emulador:

    bash
    flutter run
    

---

*Nota:* Este proyecto es un ejemplo de una aplicación de gestión autónoma y eficiente, demostrando cómo se pueden manejar tareas comerciales importantes sin depender de una conexión constante a la red.
