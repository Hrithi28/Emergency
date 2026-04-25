"""
CrisisSync — Vertex AI Predictive Risk Scoring
Predicts incident probability from live hotel state signals
"""
from google.cloud import aiplatform
from datetime import datetime
import os, logging

logger = logging.getLogger("crisissync.vertex")

aiplatform.init(
    project=os.environ.get("VERTEX_PROJECT", "crisissync-prod"),
    location="asia-south1"
)

RISK_FEATURES = [
    "hour_of_day",          # 0-1 normalized
    "day_of_week",          # 0-1 normalized
    "occupancy_rate",       # 0.0-1.0
    "event_in_progress",    # 0 or 1
    "weather_code",         # 0-10 severity
    "alcohol_service",      # 0 or 1
    "hours_since_incident", # capped at 24, normalized
    "staff_ratio",          # staff/guests ratio
    "cctv_anomaly_score",   # 0.0-1.0 from Vision AI
]

def compute_features(hotel_state: dict) -> list[float]:
    now = datetime.now()
    return [
        now.hour / 24.0,
        now.weekday() / 6.0,
        float(hotel_state.get("occupancy_rate", 0.7)),
        float(bool(hotel_state.get("event_in_progress", False))),
        float(hotel_state.get("weather_severity", 0)) / 10.0,
        float(bool(hotel_state.get("alcohol_service", False))),
        min(float(hotel_state.get("hours_since_last_incident", 24)), 24.0) / 24.0,
        float(hotel_state.get("staff_ratio", 0.15)),
        float(hotel_state.get("cctv_anomaly_score", 0.0)),
    ]

ZONE_RISK_MULTIPLIERS = {
    "bar":          1.7,
    "pool":         1.5,
    "banquet":      1.4,
    "restaurant":   1.3,
    "parking":      1.25,
    "lobby":        1.1,
    "gym":          0.9,
    "rooms":        0.85,
    "office":       0.6,
}

def get_zone_risk_scores(hotel_state: dict) -> dict[str, float]:
    """
    Returns risk probability 0-1 for each hotel zone.
    Uses rule-based scoring as Vertex AI fallback.
    In production, call deployed Vertex AI endpoint.
    """
    features = compute_features(hotel_state)

    base_risk = (
        0.25 * features[0] +   # time of day
        0.20 * features[2] +   # occupancy
        0.20 * features[3] +   # event in progress
        0.15 * features[5] +   # alcohol service
        0.10 * features[7] +   # staff ratio (inverse)
        0.10 * features[8]     # CCTV anomaly score
    )

    zones = hotel_state.get("zones", list(ZONE_RISK_MULTIPLIERS.keys()))
    return {
        zone: round(min(base_risk * ZONE_RISK_MULTIPLIERS.get(zone, 1.0), 1.0), 3)
        for zone in zones
    }

def flag_high_risk_zones(hotel_state: dict, threshold: float = 0.6) -> list[dict]:
    scores = get_zone_risk_scores(hotel_state)
    flagged = [
        {"zone": z, "risk_score": s, "alert_level": "HIGH" if s > 0.8 else "MEDIUM"}
        for z, s in scores.items() if s >= threshold
    ]
    return sorted(flagged, key=lambda x: x["risk_score"], reverse=True)
