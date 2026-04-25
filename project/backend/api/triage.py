"""
CrisisSync — Gemini 1.5 Pro Triage Engine
Classifies incident severity, drafts PA broadcast, assigns staff roles
"""
import google.generativeai as genai
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List
import os, json, re, time

router = APIRouter()
genai.configure(api_key=os.environ.get("GEMINI_API_KEY", ""))
model = genai.GenerativeModel("gemini-1.5-pro")

TRIAGE_PROMPT = """You are CrisisSync's AI triage engine for hospitality emergencies.
Given an incident report, respond with ONLY a valid JSON object:
{
  "severity": "P0|P1|P2|P3",
  "incident_type": "medical|fire|security|evacuation|flood|structural|other",
  "affected_zones": ["zone names"],
  "estimated_guests_affected": 0,
  "immediate_actions": ["action1", "action2"],
  "staff_roles_needed": ["Medical Officer", "Security", "Manager"],
  "pa_broadcast_draft": "calm PA announcement text under 50 words",
  "emergency_services": ["ambulance"],
  "aed_needed": false,
  "elevator_lockdown": false,
  "confidence": 0.95,
  "reasoning": "brief explanation"
}
P0=life threatening, P1=high risk, P2=moderate, P3=low risk. Respond ONLY with JSON."""

class IncidentReport(BaseModel):
    description: str
    location: str
    reporter_type: str
    hotel_id: str
    zone: Optional[str] = None
    additional_context: Optional[str] = None

class TriageResult(BaseModel):
    incident_id: str
    severity: str
    pa_broadcast: str
    immediate_actions: List[str]
    staff_needed: List[str]
    emergency_services: List[str]
    response_time_target_seconds: int
    raw_analysis: dict

@router.post("/analyze", response_model=TriageResult)
async def triage_incident(report: IncidentReport):
    """Run Gemini 1.5 Pro triage on an incoming incident report."""
    prompt = f"""Incident Report:
- Description: {report.description}
- Location: {report.location}
- Reported by: {report.reporter_type}
- Hotel Zone: {report.zone or 'Unknown'}
- Context: {report.additional_context or 'None'}
Analyze and respond with the JSON triage object."""

    try:
        response = model.generate_content(
            [TRIAGE_PROMPT, prompt],
            generation_config=genai.GenerationConfig(temperature=0.1, max_output_tokens=800)
        )
        raw = json.loads(re.sub(r"```json\n?|\n?```", "", response.text.strip()))
        targets = {"P0": 30, "P1": 60, "P2": 180, "P3": 600}
        return TriageResult(
            incident_id=f"INC-{int(time.time())}",
            severity=raw["severity"],
            pa_broadcast=raw["pa_broadcast_draft"],
            immediate_actions=raw["immediate_actions"],
            staff_needed=raw["staff_roles_needed"],
            emergency_services=raw.get("emergency_services", []),
            response_time_target_seconds=targets.get(raw["severity"], 180),
            raw_analysis=raw
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Triage failed: {str(e)}")

@router.post("/pa-translate")
async def translate_pa(text: str, languages: List[str] = ["ta", "hi", "te", "ml"]):
    """Translate PA broadcast to multiple Indian languages via Gemini."""
    prompt = f"""Translate this emergency PA to {', '.join(languages)}.
Keep it calm, clear, under 30 words per language.
Original: {text}
Respond with JSON: {{"translations": {{"lang_code": "translation"}}}}"""
    response = model.generate_content(prompt)
    return json.loads(re.sub(r"```json\n?|\n?```", "", response.text.strip()))
