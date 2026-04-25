"""CrisisSync — Incidents CRUD API"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from google.cloud import firestore
from datetime import datetime
import uuid

router = APIRouter()
db = firestore.AsyncClient()

class IncidentCreate(BaseModel):
    type: str
    location: str
    description: str
    severity: str
    reporter_id: str
    hotel_id: str
    zone: Optional[str] = None

class IncidentUpdate(BaseModel):
    status: Optional[str] = None
    assignee: Optional[str] = None
    resolution_notes: Optional[str] = None

@router.get("/")
async def list_incidents(hotel_id: str, status: Optional[str] = None, limit: int = 50):
    query = db.collection("incidents").where("hotel_id", "==", hotel_id).limit(limit)
    if status:
        query = query.where("status", "==", status)
    docs = [doc.to_dict() | {"id": doc.id} async for doc in query.stream()]
    return {"incidents": docs, "count": len(docs)}

@router.post("/")
async def create_incident(data: IncidentCreate):
    incident = {
        **data.dict(),
        "id": f"INC-{uuid.uuid4().hex[:8].upper()}",
        "status": "active",
        "created_at": firestore.SERVER_TIMESTAMP,
        "updated_at": firestore.SERVER_TIMESTAMP,
        "responders": [],
        "timeline": [{"event": "Incident reported", "timestamp": datetime.utcnow().isoformat()}]
    }
    ref = db.collection("incidents").document(incident["id"])
    await ref.set(incident)
    return {"incident_id": incident["id"], "status": "created"}

@router.patch("/{incident_id}")
async def update_incident(incident_id: str, update: IncidentUpdate):
    ref = db.collection("incidents").document(incident_id)
    doc = await ref.get()
    if not doc.exists:
        raise HTTPException(status_code=404, detail="Incident not found")
    updates = {k: v for k, v in update.dict().items() if v is not None}
    updates["updated_at"] = firestore.SERVER_TIMESTAMP
    await ref.update(updates)
    return {"status": "updated"}

@router.post("/{incident_id}/resolve")
async def resolve_incident(incident_id: str, notes: str = ""):
    ref = db.collection("incidents").document(incident_id)
    await ref.update({
        "status": "resolved",
        "resolved_at": firestore.SERVER_TIMESTAMP,
        "resolution_notes": notes,
        "updated_at": firestore.SERVER_TIMESTAMP,
    })
    return {"status": "resolved"}
