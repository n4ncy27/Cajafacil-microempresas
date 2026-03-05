# Caja Fácil - Microempresas

Aplicación móvil desarrollada en **Flutter** para la gestión de caja de microempresas. Permite registrar ingresos, compras, gastos, controlar inventario y generar reportes.

---

## Requisitos previos

Antes de empezar, necesitas instalar las siguientes herramientas en tu computador:

### 1. Flutter SDK

1. Ve a [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)
2. Selecciona tu sistema operativo (Windows, macOS o Linux)
3. Descarga e instala Flutter siguiendo las instrucciones
4. Agrega Flutter al PATH de tu sistema
5. Verifica la instalación abriendo una terminal (CMD o PowerShell) y ejecutando:

```bash
flutter doctor
```

### 2. Android Studio (necesario para el SDK de Android)

1. Descarga Android Studio desde [https://developer.android.com/studio](https://developer.android.com/studio)
2. Instálalo y ábrelo
3. Ve a **Tools > SDK Manager**
4. En la pestaña **SDK Tools**, marca **Android SDK Command-line Tools (latest)** y haz clic en **Apply**
5. Acepta las licencias de Android ejecutando en terminal:

```bash
flutter doctor --android-licenses
```

Acepta todo escribiendo `y` y presionando Enter.

### 3. Git

1. Descarga Git desde [https://git-scm.com/downloads](https://git-scm.com/downloads)
2. Instálalo con las opciones por defecto

### 4. VS Code (editor recomendado)

1. Descarga VS Code desde [https://code.visualstudio.com/](https://code.visualstudio.com/)
2. Instala las siguientes extensiones dentro de VS Code:
   - **Flutter** (de Dart Code)
   - **Dart** (de Dart Code)

---

## Clonar el proyecto

Abre una terminal y ejecuta:

```bash
git clone https://github.com/n4ncy27/Cajafacil-microempresas.git
```

Luego entra a la carpeta del proyecto:

```bash
cd Cajafacil-microempresas
```

---

## Instalar dependencias

Dentro de la carpeta del proyecto, ejecuta:

```bash
flutter pub get
```

Esto descarga todas las librerías que el proyecto necesita.

---

## Ejecutar la aplicación

### Opción 1: Desde la terminal (CMD / PowerShell)

1. Conecta tu celular Android por USB
2. Activa la **Depuración USB** en tu celular:
   - Ve a **Ajustes > Acerca del teléfono** y toca 7 veces el **Número de compilación**
   - Luego ve a **Ajustes > Opciones de desarrollador** y activa **Depuración USB**
3. Verifica que el dispositivo aparezca:

```bash
flutter devices
```

4. Ejecuta la app:

```bash
flutter run
```

### Opción 2: Desde VS Code (recomendada)

1. Abre la carpeta del proyecto en VS Code
2. Conecta tu celular Android por USB con depuración USB activada
3. En VS Code, selecciona tu dispositivo en la barra inferior
4. Presiona **F5** o ve a **Run > Start Debugging**
5. Cada vez que guardes un archivo (`Ctrl + S`), los cambios se aplican al instante (Hot Reload)

---

## Estructura del proyecto

```
lib/
├── main.dart                  # Punto de entrada de la app
├── splash_screen.dart         # Pantalla de carga con logo y animación
└── pages/
    ├── dashboard_page.dart    # Pantalla principal (Dashboard)
    ├── ingresos_page.dart     # Módulo de ingresos
    ├── compras_page.dart      # Módulo de compras
    ├── gastos_page.dart       # Módulo de gastos
    ├── inventario_page.dart   # Módulo de inventario
    └── reportes_page.dart     # Módulo de reportes
```

---

## Solución de problemas comunes

### Error: "Your project path contains non-ASCII characters"
Si la ruta de tu proyecto tiene tildes o caracteres especiales, crea un acceso directo sin tildes:

```bash
mklink /J C:\cajafacil "ruta\original\del\proyecto"
cd C:\cajafacil
flutter run
```

### Error: "cmdline-tools component is missing"
Abre Android Studio > Tools > SDK Manager > SDK Tools > marca **Android SDK Command-line Tools** > Apply.

### Los cambios no se aplican al instante
- Si usas terminal: presiona `r` mientras la app corre para hacer Hot Reload
- Si usas VS Code con la extensión Flutter: guarda el archivo con `Ctrl + S` y se aplica automáticamente

### Error: "No connected devices"
- Verifica que el cable USB funcione
- Activa la Depuración USB en el celular
- Ejecuta `flutter devices` para verificar

---

## Tecnologías

- [Flutter](https://flutter.dev/) 3.41+
- [Dart](https://dart.dev/)
- [Google Fonts](https://pub.dev/packages/google_fonts) (Montserrat)
