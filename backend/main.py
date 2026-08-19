import os
from typing import Optional
import httpx
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

load_dotenv()

HA_URL = os.getenv("HOME_ASSISTANT_URL", "http://192.168.1.100:8123").rstrip("/")
HA_TOKEN = os.getenv("HOME_ASSISTANT_TOKEN", "")
DEMO_MODE = os.getenv("DEMO_MODE", "true").lower() == "true"

app = FastAPI(title="Casa Oscar API", version="0.2.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # Restringir en producción
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

ROOMS = [
    {"id":"sala","name":"Sala","floor":"Planta Baja","icon":"living"},
    {"id":"cocina","name":"Cocina","floor":"Planta Baja","icon":"kitchen"},
    {"id":"terraza","name":"Terraza","floor":"Planta Baja","icon":"deck"},
    {"id":"recamara","name":"Recámara Principal","floor":"Planta Alta","icon":"bed"},
]

DEVICES = [
    {"entity_id":"light.sala_principal","name":"Luz principal","room":"Sala","type":"light","state":"on","brightness":78},
    {"entity_id":"light.sala_ambiental","name":"Luz ambiental","room":"Sala","type":"light","state":"off","brightness":25},
    {"entity_id":"climate.sala","name":"Clima","room":"Sala","type":"climate","state":"cool","temperature":24},
    {"entity_id":"cover.persiana_sala","name":"Persiana","room":"Sala","type":"cover","state":"closed","position":0},
    {"entity_id":"media_player.tv_sala","name":"TV Sala","room":"Sala","type":"media_player","state":"off"},
    {"entity_id":"light.cocina","name":"Luz Cocina","room":"Cocina","type":"light","state":"off","brightness":100},
    {"entity_id":"switch.cafetera","name":"Cafetera","room":"Cocina","type":"switch","state":"off"},
    {"entity_id":"light.terraza","name":"Luz Terraza","room":"Terraza","type":"light","state":"off","brightness":60},
    {"entity_id":"camera.terraza","name":"Cámara Terraza","room":"Terraza","type":"camera","state":"streaming"},
    {"entity_id":"light.recamara","name":"Luz Recámara","room":"Recámara Principal","type":"light","state":"off","brightness":35},
    {"entity_id":"climate.recamara","name":"Clima Recámara","room":"Recámara Principal","type":"climate","state":"cool","temperature":22},
    {"entity_id":"cover.persiana_recamara","name":"Persiana","room":"Recámara Principal","type":"cover","state":"closed","position":0},
]

ENERGY = {
    "instant_kw": 3.82,
    "today_kwh": 18.6,
    "month_kwh": 412.4,
    "month_cost_mxn": 1385.20,
    "solar_kw": 0.0,
    "grid_kw": 3.82,
}

SCENES = [
    {"id":"llegar","name":"Llegar a casa","icon":"home","description":"Enciende sala y cocina, clima a 23°C, abre persiana de sala"},
    {"id":"salir","name":"Salir de casa","icon":"car","description":"Apaga todas las luces, enchufes y TV, cierra persianas"},
    {"id":"cine","name":"Cine","icon":"movie","description":"Cierra persiana de sala, atenúa luces, enciende TV"},
    {"id":"buenas_noches","name":"Buenas noches","icon":"moon","description":"Apaga luces, clima nocturno 20°C y cierra persianas"},
]

# Efectos que aplica cada escena sobre los dispositivos en modo demo.
# En modo real (Home Assistant) esto lo resuelve la escena configurada en HA.
SCENE_EFFECTS = {
    "llegar": [
        {"entity_id":"light.sala_principal","state":"on","brightness":80},
        {"entity_id":"light.cocina","state":"on","brightness":70},
        {"entity_id":"climate.sala","state":"cool","temperature":23},
        {"entity_id":"cover.persiana_sala","state":"open","position":100},
    ],
    "salir": [
        {"entity_id":"light.sala_principal","state":"off"},
        {"entity_id":"light.sala_ambiental","state":"off"},
        {"entity_id":"light.cocina","state":"off"},
        {"entity_id":"light.terraza","state":"off"},
        {"entity_id":"light.recamara","state":"off"},
        {"entity_id":"switch.cafetera","state":"off"},
        {"entity_id":"media_player.tv_sala","state":"off"},
        {"entity_id":"cover.persiana_sala","state":"closed","position":0},
        {"entity_id":"cover.persiana_recamara","state":"closed","position":0},
    ],
    "cine": [
        {"entity_id":"cover.persiana_sala","state":"closed","position":0},
        {"entity_id":"light.sala_principal","state":"off"},
        {"entity_id":"light.sala_ambiental","state":"on","brightness":15},
        {"entity_id":"media_player.tv_sala","state":"on"},
    ],
    "buenas_noches": [
        {"entity_id":"light.sala_principal","state":"off"},
        {"entity_id":"light.sala_ambiental","state":"off"},
        {"entity_id":"light.cocina","state":"off"},
        {"entity_id":"light.terraza","state":"off"},
        {"entity_id":"light.recamara","state":"off"},
        {"entity_id":"climate.recamara","state":"cool","temperature":20},
        {"entity_id":"cover.persiana_recamara","state":"closed","position":0},
        {"entity_id":"media_player.tv_sala","state":"off"},
    ],
}

class ServiceCommand(BaseModel):
    entity_id: str
    domain: str
    service: str
    data: Optional[dict] = None

def headers():
    if not HA_TOKEN:
        raise HTTPException(500, "HOME_ASSISTANT_TOKEN no configurado")
    return {"Authorization": f"Bearer {HA_TOKEN}", "Content-Type": "application/json"}

async def ha_template(template: str) -> str:
    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.post(f"{HA_URL}/api/template", headers=headers(), json={"template": template})
    if r.status_code != 200:
        raise HTTPException(r.status_code, r.text)
    return r.text

async def entity_areas() -> dict:
    """entity_id -> nombre de Área asignada en Home Assistant (vacío si no tiene)."""
    text = await ha_template(
        "{% for s in states %}{{ s.entity_id }}|{{ area_name(s.entity_id) or '' }}\n{% endfor %}"
    )
    result = {}
    for line in text.strip().splitlines():
        if "|" in line:
            entity_id, area = line.split("|", 1)
            if area:
                result[entity_id] = area
    return result

async def ha_area_names() -> list:
    text = await ha_template("{% for a in areas() %}{{ area_name(a) }}\n{% endfor %}")
    return [line.strip() for line in text.strip().splitlines() if line.strip()]

@app.get("/")
async def root():
    return {"name":"Casa Oscar API","version":"0.2.0","demo_mode":DEMO_MODE}

@app.get("/api/rooms")
async def rooms():
    device_list = await devices()
    if DEMO_MODE:
        room_meta = {r["name"]: r for r in ROOMS}
    else:
        room_meta = {
            name: {"id": name.lower().replace(" ", "_"), "name": name, "floor": "", "icon": "room"}
            for name in await ha_area_names()
        }
    result = []
    for name, meta in room_meta.items():
        room_devices = [d for d in device_list if d.get("room") == name]
        count = len(room_devices)
        active = sum(1 for d in room_devices if d.get("state") in ("on","cool","streaming","open"))
        result.append({**meta, "device_count":count, "active_count":active})
    return result

@app.get("/api/devices")
async def devices(room: Optional[str] = None):
    if DEMO_MODE:
        return [d for d in DEVICES if room is None or d["room"] == room]
    areas = await entity_areas()
    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.get(f"{HA_URL}/api/states", headers=headers())
    if r.status_code != 200:
        raise HTTPException(r.status_code, r.text)
    allowed = {"light","switch","climate","cover","lock","camera","sensor","media_player"}
    result = []
    for s in r.json():
        domain = s["entity_id"].split(".")[0]
        if domain not in allowed:
            continue
        a = s.get("attributes", {})
        room_name = areas.get(s["entity_id"], "Sin asignar")
        if room is not None and room_name != room:
            continue
        result.append({
            "entity_id":s["entity_id"],
            "name":a.get("friendly_name", s["entity_id"]),
            "room":room_name,
            "type":domain,
            "state":s.get("state"),
            "temperature":a.get("temperature"),
            "brightness":a.get("brightness"),
            "position":a.get("current_position"),
        })
    return result

@app.get("/api/scenes")
async def scenes():
    return SCENES

@app.get("/api/energy")
async def energy():
    return ENERGY

@app.post("/api/service")
async def service(cmd: ServiceCommand):
    if DEMO_MODE:
        target = next((d for d in DEVICES if d["entity_id"] == cmd.entity_id), None)
        if target:
            if cmd.service == "turn_on": target["state"] = "on"
            elif cmd.service == "turn_off": target["state"] = "off"
            elif cmd.service == "open_cover":
                target["state"], target["position"] = "open", 100
            elif cmd.service == "close_cover":
                target["state"], target["position"] = "closed", 0
            elif cmd.service == "set_cover_position":
                p = int((cmd.data or {}).get("position", 0))
                target["position"] = p
                target["state"] = "open" if p > 0 else "closed"
            elif cmd.service == "set_temperature":
                target["temperature"] = float((cmd.data or {}).get("temperature", target.get("temperature",24)))
            elif cmd.service == "turn_on" and target["type"] == "media_player":
                target["state"]="on"
        return {"ok":True,"device":target}

    payload = {"entity_id": cmd.entity_id}
    if cmd.data: payload.update(cmd.data)
    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.post(
            f"{HA_URL}/api/services/{cmd.domain}/{cmd.service}",
            headers=headers(), json=payload
        )
    if r.status_code not in (200,201):
        raise HTTPException(r.status_code, r.text)
    return {"ok":True,"result":r.json()}

@app.post("/api/scenes/{scene_id}")
async def scene(scene_id: str):
    if DEMO_MODE:
        effects = SCENE_EFFECTS.get(scene_id)
        if effects is None:
            raise HTTPException(404, "Escena no encontrada")
        for eff in effects:
            target = next((d for d in DEVICES if d["entity_id"] == eff["entity_id"]), None)
            if not target:
                continue
            for key in ("state", "brightness", "temperature", "position"):
                if key in eff:
                    target[key] = eff[key]
        return {"ok":True,"scene":scene_id,"demo":True,"affected":len(effects)}
    entity = {
        "llegar":"scene.llegar_a_casa",
        "salir":"scene.salir_de_casa",
        "cine":"scene.cine",
        "buenas_noches":"scene.buenas_noches",
    }.get(scene_id)
    if not entity: raise HTTPException(404,"Escena no encontrada")
    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.post(
            f"{HA_URL}/api/services/scene/turn_on",
            headers=headers(), json={"entity_id":entity}
        )
    if r.status_code not in (200,201):
        raise HTTPException(r.status_code,r.text)
    return {"ok":True,"scene":scene_id}
