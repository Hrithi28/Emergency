# CrisisSync — System Architecture

## Overview

CrisisSync is built on a cloud-native, event-driven architecture using Google Cloud Platform services. Every layer is designed for sub-second latency, auto-scaling, and zero single points of failure.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                          INPUT LAYER                                │
│                                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐  ┌────────┐ │
│  │   IoT    │  │ CCTV AI  │  │ Guest SOS│  │ Staff  │  │Manual  │ │
│  │ Sensors  │  │ Vision AI│  │   App    │  │Mobile  │  │Report  │ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └───┬────┘  └───┬────┘ │
└───────┼──────────────┼─────────────┼─────────────┼───────────┼──────┘
        │              │             │             │           │
        └──────────────┴─────────────┴─────────────┴───────────┘
                                     │
                          ┌──────────▼──────────┐
                          │   Cloud Pub/Sub      │
                          │   (Event Streaming)  │
                          │   crisissync-incidents│
                          └──────────┬───────────┘
                                     │
┌────────────────────────────────────▼────────────────────────────────┐
│                    AI PROCESSING — Google Cloud Run                  │
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────┐  ┌───────────┐ │
│  │ Gemini 1.5   │  │  Vertex AI   │  │  Maps API  │  │ Google    │ │
│  │ Triage Engine│  │  Risk Score  │  │  Routing   │  │ TTS/STT   │ │
│  └──────────────┘  └──────────────┘  └────────────┘  └───────────┘ │
│  ┌──────────────┐  ┌──────────────┐                                 │
│  │ Cloud Vision │  │ Vertex AI    │                                 │
│  │ CCTV Analyze │  │ Agent Builder│                                 │
│  └──────────────┘  └──────────────┘                                 │
└────────────────────────────────────┬────────────────────────────────┘
                                     │
             ┌───────────────────────┼───────────────────────┐
             │                       │                       │
   ┌─────────▼───────┐    ┌──────────▼──────┐    ┌──────────▼──────┐
   │  Firebase RTDB  │    │ Cloud Firestore  │    │    BigQuery     │
   │  (Live Sync     │    │ (Structured Data │    │  (Analytics     │
   │  <100ms latency)│    │  + Audit Trail)  │    │   Warehouse)    │
   └─────────┬───────┘    └─────────────────┘    └─────────────────┘
             │
┌────────────▼────────────────────────────────────────────────────────┐
│                          OUTPUT LAYER                                │
│                                                                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐  ┌────────┐ │
│  │  Staff   │  │ Command  │  │  112 /   │  │   PA   │  │Looker  │ │
│  │ Dispatch │  │Dashboard │  │Emergency │  │Broadcast│  │Studio  │ │
│  │  (FCM)   │  │(Flutter) │  │  Alert   │  │ (TTS)  │  │Reports │ │
│  └──────────┘  └──────────┘  └──────────┘  └────────┘  └────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Component Details

### Event Ingestion (Cloud Pub/Sub)
- **Topic:** `crisissync-incidents`
- **Retention:** 24 hours
- **Push subscription** to Cloud Run API endpoint
- Handles: IoT sensor readings, CCTV alerts, SOS signals, manual reports

### AI Processing (Cloud Run)
- **Runtime:** Python 3.12 / FastAPI
- **Scaling:** 0–100 instances, concurrency 1000
- **Region:** asia-south1 (Mumbai)
- **Latency target:** P95 < 3s for Gemini triage

### Gemini 1.5 Pro Triage Engine
- Input: incident description + location + context
- Output: severity (P0–P3), PA draft, staff roles, emergency services flag
- System prompt enforces JSON-only output
- Temperature: 0.1 (deterministic, safety-critical)

### Firebase Realtime Database
- Primary sync mechanism for live dashboard
- All staff devices subscribe to `hotels/{hotelId}/incidents`
- Sub-100ms push latency on write
- Security rules enforce role-based read/write

### BigQuery Analytics
- Incidents streamed via Firestore → BigQuery connector
- Tables: `incidents`, `response_metrics`, `staff_dispatch_log`, `pa_broadcasts`
- Looker Studio dashboard auto-refreshes every 30s

---

## Security Model

| Layer | Control |
|-------|---------|
| API   | Cloud Endpoints + Cloud Armor DDoS protection |
| Auth  | Firebase Auth with custom claims (role/hotel) |
| Data  | Firebase Security Rules + Firestore rules |
| Secrets | Cloud Secret Manager (Gemini key, Maps key) |
| Network | VPC + Cloud NAT for egress |
| Audit | Immutable Firestore audit collection |

---

## Deployment

All infrastructure is defined in Terraform (`infra/main.tf`).
CI/CD via GitHub Actions on every push to `main`.

```bash
# Deploy backend
cd infra && terraform init && terraform apply

# Deploy frontend
cd frontend && flutter build web && firebase deploy --only hosting
```

---

## Performance Targets

| Metric | Target | Current |
|--------|--------|---------|
| Detection → First Alert | < 5s | ~2.8s |
| Detection → Staff Dispatch | < 30s | ~18s |
| Detection → Responder On-Site | < 60s | ~52s |
| Firebase RTDB Latency | < 100ms | ~45ms |
| Gemini Triage Latency | < 3s | ~2.1s |
| Cloud Run Cold Start | < 1s | ~0.6s |
| Dashboard Update Frequency | < 1s | ~0.4s |
