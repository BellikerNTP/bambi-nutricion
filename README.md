# Proyecto Nutrición Hogar Bambi

Guía de instalación y ejecución del backend (FastAPI) y del frontend (Flutter) en un entorno local.

## 1. Requisitos previos

- **Sistema operativo**: Windows 10/11 (probado en Windows).
- **Software necesario**:
  - [Python 3.10+](https://www.python.org/downloads/) (recomendado 3.12).
  - [Flutter SDK](https://docs.flutter.dev/get-started/install) con soporte para *Windows desktop*.
  - Acceso a un clúster de **MongoDB Atlas** (o usar el mismo cluster del autor).
  - Opcional: `mongosh` instalado si vas a crear la base de datos desde cero.

Estructura relevante del repo:

- `backend/` → API en FastAPI (Python) + conexión a MongoDB.
- `Nutricion-flutter/` → Aplicación Flutter de escritorio (Inventario + Platos Servidos).
- `archivos-Mongo/` → Scripts para crear colecciones y datos iniciales en MongoDB.

---

## 2. Configurar la base de datos MongoDB

### 2.1. Usar un cluster existente

Si ya existe un cluster configurado para este proyecto, se necesita:

- Un **connection string** de MongoDB Atlas (`MONGODB_URI`).
- El nombre de la base de datos (por defecto `nutricion_hogar_bambi`).

Con esa información no es necesario ejecutar los scripts de creación; las colecciones y datos deberían existir previamente.

### 2.2. Crear un cluster nuevo (opcional)

Si quieres un clúster independiente:

1. Crea un cluster gratuito en MongoDB Atlas.
2. Crea un usuario con permisos para la base `nutricion_hogar_bambi`.
3. Copia el connection string (formato `mongodb+srv://usuario:password@cluster/...`).
4. Desde una terminal con `mongosh` instalado y autenticado, en la raíz del repo, ejecuta:

   ```bash
   mongosh < archivos-Mongo/00_crear_tablas.js
   mongosh < archivos-Mongo/01_sedes.js
   mongosh < archivos-Mongo/02_cargos.js
   mongosh < archivos-Mongo/03_productos.js
   mongosh < archivos-Mongo/04_inventario_historial.js
   mongosh < archivos-Mongo/05_platos_historial.js
   ```

Esto creará la estructura de colecciones y algunos datos de ejemplo.

---

## 3. Levantar el backend (FastAPI)

1. Abre una terminal en la carpeta `backend/`:

   ```bash
   cd backend
   ```

2. (Recomendado) Crea y activa un entorno virtual de Python, por ejemplo:

   ```bash
   python -m venv .venv
   .venv\Scripts\activate
   ```

3. Instala las dependencias de Python:

   ```bash
   pip install -r requirements.txt
   ```

4. Crea un archivo `.env` dentro de `backend/` con este contenido (ajusta el URI a tu cluster):

   ```env
   MONGODB_URI=mongodb+srv://usuario:password@tu-cluster.mongodb.net
   MONGODB_DB=nutricion_hogar_bambi
   ```

5. Levanta el servidor FastAPI con Uvicorn:

   ```bash
   uvicorn main:app --reload --port 8000
   ```

6. Verifica que responde:

   - Abre en el navegador: `http://localhost:8000/health` → debe devolver `{ "status": "ok" }`.
   - La documentación interactiva de la API está en `http://localhost:8000/docs`.

> Importante: el front Flutter asume que el backend corre en `http://localhost:8000`. Si usas otro host o puerto, deberás actualizarlo (ver sección 4.3).

---

## 4. Levantar el front (Flutter)

### 4.1. Instalar dependencias Flutter

1. Abre una terminal en la carpeta `Nutricion-flutter/`:

   ```bash
   cd Nutricion-flutter
   ```

2. Descarga las dependencias del proyecto Flutter:

   ```bash
   flutter pub get
   ```

3. Asegúrate de tener habilitado el soporte para aplicaciones de escritorio en Windows:

   ```bash
   flutter config --enable-windows-desktop
   ```

### 4.2. Ejecutar en modo desarrollo (Windows)

Con el backend ya corriendo en `http://localhost:8000`, desde `Nutricion-flutter/`:

```bash
flutter run -d windows
```

Esto abrirá la aplicación de escritorio con las secciones:

- **Inventario**: productos, transacciones y registro de nuevas transacciones.
- **Platos Servidos**: registro de platos por fecha/cargo/personas, selección de ingredientes disponibles e impacto sobre el stock.

### 4.3. Cambiar la URL del backend (si no es localhost)

Si el backend no corre en `http://localhost:8000` (por ejemplo, está en otra máquina o puerto), edita:

- `Nutricion-flutter/lib/app/api_client.dart`

Busca la línea:

```dart
static const String baseUrl = 'http://localhost:8000';
```

Y cámbiala a la URL correspondiente, por ejemplo:

```dart
static const String baseUrl = 'http://192.168.1.50:8000';
```

Guarda y vuelve a ejecutar `flutter run`.

### 4.4. Generar ejecutable para Windows (build de producción)

Si quieres construir un `.exe` para distribuir:

```bash
flutter build windows
```

El ejecutable quedará en:

- `Nutricion-flutter/build/windows/x64/runner/Release/`

Puedes copiar esa carpeta completa a otra máquina Windows (necesita solo las librerías de runtime estándar de Windows, no Flutter instalado).

---

## 5. Resumen rápido para tu compañero

1. **Clonar o descargar el repositorio completo**.
2. **Configurar MongoDB**:
   - Usar un cluster existente y configurar `MONGODB_URI` y `MONGODB_DB`.
   - O crear un cluster nuevo y ejecutar los scripts de `archivos-Mongo/`.
3. **Backend**:
   - `cd backend`
   - Crear `.env` con `MONGODB_URI` y `MONGODB_DB`.
   - `pip install -r requirements.txt`
   - `uvicorn main:app --reload --port 8000`
4. **Frontend Flutter**:
   - `cd Nutricion-flutter`
   - `flutter pub get`
   - `flutter run -d windows`

Con estos pasos la aplicación quedará operativa, utilizando el mismo inventario y registros de platos (si se apunta al mismo cluster de MongoDB) o una instancia de datos independiente (si se usa un cluster propio).
