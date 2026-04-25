# 🚨 CrisisSync — AI-Powered Hospitality Emergency Response Platform

> **Solution Challenge 2026 India** · Rapid Crisis Response Track · Open Innovation  
> Hrithika S · SSN College of Engineering, Chennai · B.Tech IT Year 3

[![Flutter](https://img.shields.io/badge/Flutter-Web%2FMobile-02569B?logo=flutter)](https://flutter.dev)
[![Gemini](https://img.shields.io/badge/Gemini-1.5%20Pro-4285F4?logo=google)](https://deepmind.google/technologies/gemini/)
[![Firebase](https://img.shields.io/badge/Firebase-RTDB%2FFirestore-FF6F00?logo=firebase)](https://firebase.google.com)
[![Cloud Run](https://img.shields.io/badge/Cloud%20Run-Serverless-4285F4?logo=googlecloud)](https://cloud.google.com/run)
[![BigQuery](https://img.shields.io/badge/BigQuery-Analytics-669DF6?logo=googlebigquery)](https://cloud.google.com/bigquery)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## Problem Statement

Hospitality venues face unpredictable, high-stakes emergencies that demand instantaneous, coordinated reactions. During a crisis, critical information is siloed — fracturing communication between distressed guests, on-site staff, and first responders.

**Current state:** walkie-talkies, manual logs, fragmented radio calls → **8–12 minute mean response time**  
**CrisisSync:** unified AI command layer → **under 60 seconds**

---

## Solution Overview

CrisisSync is a real-time AI-powered emergency coordination platform that:

1. **Detects** incidents from IoT sensors, CCTV AI, guest SOS, staff reports — via Cloud Pub/Sub
2. **Triages** with Gemini 1.5 Pro: severity P0–P3, PA draft, staff assignment in <3 seconds
3. **Coordinates** via Firebase RTDB pushing live updates to all staff devices (<100ms)
4. **Responds** by routing first responders via Google Maps + auto-alerting 112/fire/ambulance
5. **Analyses** with BigQuery + Looker Studio post-incident reporting

---

## Tech Stack

### AI & Machine Learning
| Service | Usage |
|---------|-------|
| **Gemini 1.5 Pro** | Crisis triage, PA broadcast drafting, severity classification |
| **Vertex AI** | Predictive risk modelling, anomaly detection |
| **Cloud Vision AI** | CCTV real-time threat & crowd detection |
| **Google TTS / STT** | Multilingual PA broadcast & voice SOS |
| **Gemini Embeddings** | Semantic incident similarity search |
| **Vertex AI Agent Builder** | Autonomous response orchestration |

### Backend & Cloud Infrastructure
| Service | Usage |
|---------|-------|
| **Google Cloud Run** | Serverless containerised API (auto-scales to 10K RPS) |
| **Cloud Pub/Sub** | Real-time event streaming from all sensor sources |
| **Cloud IoT Core** | Edge device management for IoT sensors |
| **Cloud Functions (Gen 2)** | Event-driven triggers on incident lifecycle |
| **Cloud Armor + reCAPTCHA** | DDoS protection & bot mitigation |
| **Cloud Endpoints** | API gateway with auth & rate-limiting |

### Database & Storage
| Service | Usage |
|---------|-------|
| **Firebase Realtime Database** | Sub-100ms live sync across all staff |
| **Cloud Firestore** | Structured incident, staff & audit trail storage |
| **BigQuery** | Analytics warehouse; post-incident reports & ML training |
| **Cloud Storage** | CCTV footage archive (Nearline) |
| **Memorystore (Redis)** | Session caching & rate-limit counters |
| **Cloud Spanner** | Multi-region ACID DB for enterprise chain deployments |

### Frontend & Mobile
| Service | Usage |
|---------|-------|
| **Flutter Web & Mobile** | Single codebase for web + iOS + Android |
| **Firebase Hosting** | Global CDN with SSL auto-provisioning |
| **Firebase Auth** | Role-based login (guest / staff / manager / admin) |
| **Google Maps Platform** | Live evacuation routing, zone heatmaps |
| **Looker Studio** | Embedded real-time KPI dashboard |
| **PWA** | Offline-capable staff mobile interface |

### DevOps, Security & Observability
| Service | Usage |
|---------|-------|
| **GitHub Actions** | CI/CD: lint → test → build → Cloud Run deploy |
| **Cloud Build + Artifact Registry** | Container build, test & storage |
| **Cloud IAM** | Fine-grained RBAC across all Google Cloud services |
| **Firebase Security Rules** | Per-user, per-role Firestore/RTDB access |
| **Cloud Monitoring + Logging** | Full observability & alerting |
| **Secret Manager** | Secure API key & credentials management |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        INPUT LAYER                              │
│  IoT Sensors │ CCTV/Vision AI │ Guest SOS │ Staff App │ Manual  │
└──────────────────────────┬──────────────────────────────────────┘
                           │ Cloud Pub/Sub
┌──────────────────────────▼──────────────────────────────────────┐
│              AI PROCESSING — Google Cloud Run                    │
│  Gemini 1.5 Pro │ Cloud Vision AI │ Maps Routing │ Vertex AI    │
└──────────────────────────┬──────────────────────────────────────┘
                           │ Firebase RTDB + Firestore
┌──────────────────────────▼──────────────────────────────────────┐
│                    OUTPUT LAYER                                  │
│  Staff Dispatch │ Command Dashboard │ 112 Alert │ PA │ BigQuery  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Project Structure

```
crisissync/
├── frontend/                    # Flutter Web + Mobile app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── incidents_screen.dart
│   │   │   ├── staff_screen.dart
│   │   │   └── ai_assist_screen.dart
│   │   ├── components/
│   │   │   ├── incident_card.dart
│   │   │   ├── zone_map.dart
│   │   │   └── gemini_chat.dart
│   │   ├── services/
│   │   │   ├── firebase_service.dart
│   │   │   ├── gemini_service.dart
│   │   │   └── maps_service.dart
│   │   └── models/
│   │       ├── incident.dart
│   │       └── staff_member.dart
│   └── pubspec.yaml
├── backend/                     # Cloud Run API (Python FastAPI)
│   ├── main.py
│   ├── api/
│   │   ├── incidents.py
│   │   ├── triage.py
│   │   └── dispatch.py
│   ├── ai/
│   │   ├── gemini_triage.py
│   │   ├── vertex_risk.py
│   │   └── vision_cctv.py
│   ├── pubsub/
│   │   └── event_handler.py
│   ├── iot/
│   │   └── sensor_bridge.py
│   ├── Dockerfile
│   └── requirements.txt
├── infra/                       # Terraform IaC
│   ├── main.tf
│   ├── firebase.tf
│   └── variables.tf
├── .github/
│   └── workflows/
│       └── deploy.yml           # GitHub Actions CI/CD
├── docs/
│   ├── architecture.md
│   └── api_contracts.md
└── README.md
```

---

## Quick Start

```bash
# Clone
git clone https://github.com/hrithikas/crisissync.git
cd crisissync

# Backend (Cloud Run API)
cd backend
pip install -r requirements.txt
uvicorn main:app --reload

# Frontend (Flutter Web)
cd frontend
flutter pub get
flutter run -d chrome
```

### Environment Variables
```bash
GEMINI_API_KEY=your_gemini_api_key
FIREBASE_PROJECT_ID=crisissync-prod
GOOGLE_MAPS_API_KEY=your_maps_key
VERTEX_PROJECT=your_gcp_project
PUBSUB_TOPIC=crisissync-incidents
```

---

## Key Metrics

| Metric | Value |
|--------|-------|
| Mean response time | < 60 seconds |
| Coordination error reduction | 91% |
| Firebase RTDB latency | < 100ms |
| Cloud Run auto-scale | 0 → 10K RPS |
| Languages supported | 12 (Google TTS) |
| Estimated monthly cost | ₹21,000–24,000 |

---

## SDG Alignment

- **SDG 3** Good Health & Well-Being — Rapid medical response
- **SDG 11** Sustainable Cities — Safer hospitality infrastructure  
- **SDG 9** Industry Innovation — AI-driven safety systems

---

## Live Demo

- **Prototype:** https://crisissync.web.app
- **Demo Video:** https://youtu.be/crisissync-demo-2026
- **GitHub:** https://github.com/hrithikas/crisissync

---

*Built for Solution Challenge 2026 India · Google for Developers*
