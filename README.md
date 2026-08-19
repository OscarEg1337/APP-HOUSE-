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

Al abrir la app por primera vez en un dispositivo, pide la IP del backend en una pantalla de ajustes (se guarda con `shared_preferences`, no hace falta tocar código). Usa la IP de red local de la máquina donde corre el backend, ej. `http://192.168.1.95:8000`.

## Desplegar en un iPhone físico (requisitos de la Mac)

Para compilar e instalar la app en un iPhone (no simulador) necesitas:

- **Xcode compatible con la versión de iOS del dispositivo.** Apple no deja usar un Xcode viejo con un iPhone más nuevo que el SDK que trae ese Xcode. Xcode 15.2, por ejemplo, solo soporta hasta iOS 17.2 — un iPhone con iOS 26.x necesita un Xcode mucho más reciente.
- **macOS lo bastante nuevo para correr ese Xcode.** La App Store no ofrece un Xcode más nuevo si el macOS del equipo no lo soporta. Un Mac viejo (ej. MacBook Pro 2017, `MacBookPro14,1`) tiene un tope de macOS que Apple ya no sube — en ese caso ni actualizando macOS al máximo se garantiza tener un Xcode compatible con un iPhone reciente.
- **CocoaPods** (`sudo gem install cocoapods` o `brew install cocoapods`). En macOS reciente esto es casi instantáneo. En macOS viejo sin binarios precompilados (bottles) de Homebrew, `brew install cocoapods` puede intentar compilar LLVM/Rust/Ruby desde cero (varias horas) — si pasa eso, usa en su lugar el Ruby portátil que trae Homebrew:
  ```bash
  gem install cocoapods --install-dir ~/.gem/portable-cocoapods --bindir ~/.gem/portable-cocoapods/bin \
    -- --with-ruby=/usr/local/Homebrew/Library/Homebrew/vendor/portable-ruby/*/bin/ruby
  ```
  (instala en segundos, sin tocar el Ruby del sistema).
- **Tu Apple ID agregado en Xcode** (Xcode → Settings → Accounts) con el "Personal Team" seleccionado en Signing & Capabilities del target Runner (firma gratuita — la app instalada expira cada 7 días y hay que reinstalar; para evitarlo se necesita cuenta de Apple Developer de pago).
- **Modo Desarrollador activado en el iPhone** (Ajustes → Privacidad y seguridad → Modo Desarrollador) — solo aparece esa opción después de que una Mac intente conectarse al dispositivo por primera vez.

Con todo eso: `cd app && flutter run -d <device-id>` (ver el id con `flutter devices`).

## Migrar Home Assistant a otro equipo

**Home Assistant no vive en este repositorio** — es un servicio aparte con su propia configuración y base de datos (carpeta `~/homeassistant-config` en la máquina donde corre). El backend solo necesita poder *alcanzarlo por red* (misma WiFi, o una VPN tipo Tailscale); no importa en qué máquina se compile o corra la app Flutter.

Para mover Home Assistant a otro equipo:

1. En el HA actual: **Ajustes → Sistema → Copias de seguridad** → crear un backup completo (`.tar` con config, integraciones e historial).
2. Instalar Home Assistant en el equipo nuevo (mismo método de instalación que se usó originalmente).
3. Restaurar desde ese backup en el primer arranque.

**Importante:** si hay un dongle USB (Zigbee/Z-Wave), es hardware físico — el backup no lo mueve, hay que conectarlo físicamente al equipo nuevo. Los dispositivos WiFi/Tuya no tienen ese problema (dependen de la cuenta cloud, no del dongle).

## Escenas incluidas (modo demo)

| Escena | Efecto |
|---|---|
| Llegar a casa | Enciende luces de sala y cocina, clima a 23°C, abre persiana de sala |
| Salir de casa | Apaga todas las luces, enchufes y TV, cierra persianas |
| Cine | Cierra persiana de sala, atenúa luz ambiental, enciende TV |
| Buenas noches | Apaga luces, clima nocturno a 20°C, cierra persianas |

## Pendiente

- Compilar APK para Android / build para iOS (bloqueado en Mac vieja — ver "Desplegar en un iPhone físico" arriba)
- Backend corriendo en un equipo siempre encendido (hoy corre manual en una laptop de desarrollo)
- Autenticación en la API
- Persistencia del ajuste de brillo en modo demo
- Acceso remoto (Tailscale ya instalado del lado del usuario, falta integrarlo al flujo)
