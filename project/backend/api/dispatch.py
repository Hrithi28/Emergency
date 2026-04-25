"""CrisisSync — Staff Dispatch & Emergency Services API"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from google.cloud import firestore
import httpx, os

router = APIRouter()
db = firestore.AsyncClient()

class DispatchRequest(BaseModel):
    incident_id: str
    hotel_id: str
    staff_ids: List[str]
    zone: str
    priority: str

class EmergencyAlert(BaseModel):
    incident_id: str
    hotel_id: str
    services: List[str]  # ["ambulance", "fire", "police"]
    location_lat: float
    location_lng: float
    description: str
    guest_count: int

@router.post("/staff")
async def dispatch_staff(req: DispatchRequest):
    """Assign and notify staff members via Firebase RTDB."""
    assignments = []
    for staff_id in req.staff_ids:
        staff_ref = db.collection("staff").document(staff_id)
        staff_doc = await staff_ref.get()
        if not staff_doc.exists:
            continue
        await staff_ref.update({
            "status": "dispatched",
            "current_incident": req.incident_id,
            "assigned_zone": req.zone,
        })
        # Push FCM notification (simplified)
        assignments.append({"staff_id": staff_id, "status": "notified"})

    # Update incident with responders
    await db.collection("incidents").document(req.incident_id).update({
        "responders": req.staff_ids,
        "dispatch_time": firestore.SERVER_TIMESTAMP,
    })
    return {"dispatched": len(assignments), "assignments": assignments}

@router.post("/emergency-services")
async def alert_emergency_services(alert: EmergencyAlert):
    """Alert 112/ambulance/fire with GPS location and context."""
    # In production: integrate with ERSS (Emergency Response Support System) API
    alerts_sent = []
    for service in alert.services:
        alerts_sent.append({
            "service": service,
            "status": "alerted",
            "location": f"{alert.location_lat},{alert.location_lng}",
            "message": f"URGENT: {alert.description} | {alert.guest_count} guests affected | Hotel ID: {alert.hotel_id}",
            "reference": f"CS-{alert.incident_id}-{service[:3].upper()}"
        })
    return {"alerts_sent": len(alerts_sent), "details": alerts_sent}

@router.post("/pa-broadcast")
async def send_pa_broadcast(hotel_id: str, message: str, zones: List[str] = None):
    """Trigger PA system broadcast via hotel IoT bridge."""
    broadcast_record = {
        "hotel_id": hotel_id,
        "message": message,
        "zones": zones or ["all"],
        "timestamp": firestore.SERVER_TIMESTAMP,
        "status": "sent"
    }
    await db.collection("pa_broadcasts").add(broadcast_record)
    return {"status": "broadcast_sent", "zones": zones or ["all"]}
