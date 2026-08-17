# Casa Oscar

App de domótica residencial: control de luces, clima, persianas, escenas y consumo energético desde una app Flutter (Android / iOS / Web), respaldada por un backend FastAPI que actúa como gateway hacia Home Assistant.

## Arquitectura

```
Flutter (app/) → FastAPI (backend/) → Home Assistant → Tuya / Matter / Zigbee / MQTT / Hikvision
```

La app nunca guarda el token de Home Assistant: el backend actúa como gateway de seguridad y abstracción. Ver [docs/arquitectura.txt](docs/arquitectura.txt) para el diagrama completo.

## Estructura

- `backend/` — API FastAPI (modo demo con datos simulados, o conectado a Home Assistant real)
- `app/` — App Flutter multiplataforma
- `docs/` — Notas de arquitectura

## Backend

```bash
cd backend
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Swagger: `http://127.0.0.1:8000/docs`

Por defecto corre en **modo demo** (`DEMO_MODE=true` en `.env`), con dispositivos simulados en memoria — no requiere Home Assistant para probarse.

### Conectar Home Assistant real

Edita `backend/.env`:

```env
HOME_ASSISTANT_URL=http://IP_HOME_ASSISTANT:8123
HOME_ASSISTANT_TOKEN=TOKEN_DE_LARGA_DURACION
DEMO_MODE=false
```

## App Flutter

```bash
cd app
flutter pub get
flutter run                    # emulador / Chrome
flutter run -d chrome          # vista previa rápida en navegador
```

Antes de correr en un celular real, cambia la IP del backend en `app/lib/main.dart`:

```dart
class Api {
  static const baseUrl = 'http://IP_DEL_SERVIDOR:8000';
}
```

## Escenas incluidas (modo demo)

| Escena | Efecto |
|---|---|
| Llegar a casa | Enciende luces de sala y cocina, clima a 23°C, abre persiana de sala |
| Salir de casa | Apaga todas las luces, enchufes y TV, cierra persianas |
| Cine | Cierra persiana de sala, atenúa luz ambiental, enciende TV |
| Buenas noches | Apaga luces, clima nocturno a 20°C, cierra persianas |

## Pendiente

- IP del backend configurable en la app (hoy está fija en el código)
- Compilar APK para Android / build para iOS
- Autenticación en la API
- Persistencia del ajuste de brillo en modo demo
- Acceso remoto (HTTPS / VPN)
