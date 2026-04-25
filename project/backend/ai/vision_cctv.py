"""
CrisisSync — Cloud Vision AI CCTV Analysis
Real-time threat detection and crowd density monitoring
"""
from google.cloud import vision
from google.cloud import storage
import base64, io, logging, os
from dataclasses import dataclass

logger = logging.getLogger("crisissync.vision")
client = vision.ImageAnnotatorClient()
gcs    = storage.Client()

THREAT_LABELS = {
    "fight", "brawl", "fire", "smoke", "flood", "crowd surge",
    "unconscious", "collapse", "weapon", "running crowd"
}

@dataclass
class CCTVAnalysisResult:
    camera_id: str
    zone: str
    threat_detected: bool
    threat_type: str | None
    crowd_density: float       # 0.0–1.0
    anomaly_score: float       # 0.0–1.0
    labels: list[str]
    safe_search: dict
    confidence: float

def analyze_frame(image_bytes: bytes, camera_id: str, zone: str) -> CCTVAnalysisResult:
    """Run Cloud Vision AI on a CCTV frame snapshot."""
    image = vision.Image(content=image_bytes)

    # Run label detection + safe search in parallel
    label_response      = client.label_detection(image=image, max_results=20)
    safe_search_response = client.safe_search_detection(image=image)

    labels = [l.description.lower() for l in label_response.label_annotations]
    safe   = safe_search_response.safe_search_annotation

    # Detect threats
    detected_threats = [l for l in labels if any(t in l for t in THREAT_LABELS)]
    threat_detected  = bool(detected_threats)
    threat_type      = detected_threats[0] if detected_threats else None

    # Crowd density heuristic from label confidences
    crowd_labels = [l for l in label_response.label_annotations if "crowd" in l.description.lower() or "people" in l.description.lower()]
    crowd_density = max((l.score for l in crowd_labels), default=0.0)

    # Anomaly score
    violence_score = {"VERY_LIKELY": 1.0, "LIKELY": 0.75, "POSSIBLE": 0.5, "UNLIKELY": 0.2, "VERY_UNLIKELY": 0.0}
    anomaly_score  = max(
        violence_score.get(str(safe.violence).split(".")[-1], 0.0),
        0.8 if threat_detected else 0.0
    )

    return CCTVAnalysisResult(
        camera_id=camera_id,
        zone=zone,
        threat_detected=threat_detected,
        threat_type=threat_type,
        crowd_density=crowd_density,
        anomaly_score=anomaly_score,
        labels=labels[:10],
        safe_search={"violence": str(safe.violence), "racy": str(safe.racy)},
        confidence=0.9 if threat_detected else 0.7,
    )

def analyze_from_gcs(gcs_uri: str, camera_id: str, zone: str) -> CCTVAnalysisResult:
    """Analyze a CCTV frame stored in Cloud Storage."""
    image = vision.Image(source=vision.ImageSource(gcs_image_uri=gcs_uri))
    return analyze_frame(
        client.label_detection(image=image).label_annotations[0].description.encode(),
        camera_id, zone
    )
