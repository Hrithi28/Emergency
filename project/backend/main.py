"""
CrisisSync — Cloud Run API Backend
FastAPI application for incident management and Gemini AI triage
"""
from fastapi import FastAPI, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime
from api.incidents import router as incidents_router
from api.triage import router as triage_router
from api.dispatch import router as dispatch_router
from pubsub.event_handler import handle_pubsub_event
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("crisissync")

app = FastAPI(
    title="CrisisSync API",
    description="AI-powered hospitality emergency coordination backend",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://crisissync.web.app", "http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(incidents_router, prefix="/api/v1/incidents", tags=["incidents"])
app.include_router(triage_router,    prefix="/api/v1/triage",    tags=["triage"])
app.include_router(dispatch_router,  prefix="/api/v1/dispatch",  tags=["dispatch"])

@app.get("/health")
async def health():
    return {"status": "ok", "service": "CrisisSync API", "timestamp": datetime.utcnow().isoformat()}

@app.post("/pubsub/push")
async def pubsub_push(payload: dict, background_tasks: BackgroundTasks):
    """Receive events from Cloud Pub/Sub push subscription."""
    background_tasks.add_task(handle_pubsub_event, payload)
    return {"status": "accepted"}
