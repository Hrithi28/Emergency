"""
CrisisSync — IoT Sensor Bridge
Handles Cloud IoT Core device messages (smoke, heat, flood, AED sensors)
"""
from google.cloud import pubsub_v1, iot_v1
import json, logging, os
from datetime import datetime

logger = logging.getLogger("crisissync.iot")

publisher  = pubsub_v1.PublisherClient()
TOPIC_PATH = publisher.topic_path(
    os.environ.get("GCP_PROJECT", "crisissync-prod"),
    "crisissync-incidents"
)

SENSOR_THRESHOLDS = {
    "smoke":       {"ppm": 35,    "severity": "P1", "type": "fire"},
    "temperature": {"celsius": 60, "severity": "P1", "type": "fire"},
    "co":          {"ppm": 50,    "severity": "P0", "type": "medical"},
    "flood":       {"cm": 2,      "severity": "P1", "type": "flood"},
    "aed":         {"status": "removed", "severity": "P0", "type": "medical"},
    "door_force":  {"events": 3,  "severity": "P1", "type": "security"},
}

def process_sensor_reading(device_id: str, payload: dict) -> dict | None:
    """
    Evaluate a sensor reading against thresholds.
    Returns incident event dict if threshold exceeded, else None.
    """
    sensor_type = payload.get("sensor_type")
    value       = payload.get("value")
    hotel_id    = payload.get("hotel_id")
    zone        = payload.get("zone")

    if sensor_type not in SENSOR_THRESHOLDS:
        logger.warning(f"Unknown sensor type: {sensor_type}")
        return None

    cfg       = SENSOR_THRESHOLDS[sensor_type]
    threshold = list(cfg.values())[0]  # first numeric threshold

    triggered = (
        (sensor_type == "aed" and value == "removed") or
        (isinstance(value, (int, float)) and value >= threshold)
    )

    if not triggered:
        return None

    event = {
        "type": f"{sensor_type}_sensor",
        "incident_type": cfg["type"],
        "severity": cfg["severity"],
        "device_id": device_id,
        "hotel_id": hotel_id,
        "zone": zone,
        "value": value,
        "threshold": threshold,
        "description": f"{sensor_type.title()} sensor triggered at {zone}: value={value} (threshold={threshold})",
        "timestamp": datetime.utcnow().isoformat(),
    }

    # Publish to Cloud Pub/Sub
    future = publisher.publish(TOPIC_PATH, json.dumps(event).encode("utf-8"))
    logger.info(f"Published sensor event: {event['type']} from {device_id} — msg_id={future.result()}")
    return event

def register_device(hotel_id: str, device_id: str, device_type: str, zone: str) -> dict:
    """Register a new IoT sensor device with Cloud IoT Core."""
    client = iot_v1.DeviceManagerClient()
    parent = f"projects/{os.environ.get('GCP_PROJECT', 'crisissync-prod')}/locations/asia-south1/registries/crisissync-sensors"

    device = iot_v1.Device(
        id=device_id,
        metadata={
            "hotel_id": hotel_id,
            "device_type": device_type,
            "zone": zone,
            "registered_at": datetime.utcnow().isoformat(),
        }
    )
    response = client.create_device(parent=parent, device=device)
    logger.info(f"Registered device {device_id} for hotel {hotel_id}")
    return {"device_id": response.id, "status": "registered"}
