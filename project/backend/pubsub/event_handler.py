"""CrisisSync — Cloud Pub/Sub Event Handler"""
import base64, json, asyncio, logging, httpx
from google.cloud import firestore

logger = logging.getLogger("crisissync.pubsub")
db = firestore.AsyncClient()

EVENT_CONFIGS = {
    "smoke_sensor":   {"severity": "P1", "auto_triage": True},
    "heat_sensor":    {"severity": "P1", "auto_triage": True},
    "flood_sensor":   {"severity": "P1", "auto_triage": True},
    "sos_button":     {"severity": "P0", "auto_triage": True},
    "manual_report":  {"severity": None, "auto_triage": True},
    "cctv_threat":    {"severity": "P1", "auto_triage": True},
    "aed_removed":    {"severity": "P0", "auto_triage": True},
    "motion_anomaly": {"severity": "P2", "auto_triage": False},
}

async def handle_pubsub_event(payload: dict):
    try:
        data_b64 = payload.get("message", {}).get("data", "")
        event = json.loads(base64.b64decode(data_b64).decode("utf-8"))
        event_type = event.get("type", "manual_report")
        config = EVENT_CONFIGS.get(event_type, {"severity": "P2", "auto_triage": True})

        await db.collection("events").add({
            "type": event_type, "data": event,
            "received_at": firestore.SERVER_TIMESTAMP,
            "hotel_id": event.get("hotel_id"),
            "zone": event.get("zone"),
        })

        if config["auto_triage"]:
            async with httpx.AsyncClient() as client:
                await client.post("http://localhost:8000/api/v1/triage/analyze", json={
                    "description": event.get("description", event_type),
                    "location": event.get("zone", "Unknown"),
                    "reporter_type": event_type,
                    "hotel_id": event.get("hotel_id", ""),
                    "zone": event.get("zone"),
                }, timeout=10.0)

        logger.info(f"Handled {event_type} from {event.get('device_id','unknown')}")
    except Exception as e:
        logger.error(f"Pub/Sub handler error: {e}")
