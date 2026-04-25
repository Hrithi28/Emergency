terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "~> 5.0" }
  }
  backend "gcs" {
    bucket = "crisissync-tfstate"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ── Cloud Run — API Backend ──────────────────────────────────────────────────
resource "google_cloud_run_v2_service" "api" {
  name     = "crisissync-api"
  location = var.region

  template {
    containers {
      image = "gcr.io/${var.project_id}/crisissync-api:latest"
      resources {
        limits = { cpu = "2", memory = "1Gi" }
      }
      env {
        name  = "GEMINI_API_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.gemini_key.secret_id
            version = "latest"
          }
        }
      }
      env { name = "VERTEX_PROJECT", value = var.project_id }
      env { name = "FIREBASE_PROJECT_ID", value = var.project_id }
    }
    scaling { min_instance_count = 0, max_instance_count = 100 }
  }
}

resource "google_cloud_run_v2_service_iam_member" "public" {
  name   = google_cloud_run_v2_service.api.name
  role   = "roles/run.invoker"
  member = "allUsers"
}

# ── Cloud Pub/Sub — Event Streaming ─────────────────────────────────────────
resource "google_pubsub_topic" "incidents" {
  name = "crisissync-incidents"
  message_retention_duration = "86400s"
}

resource "google_pubsub_subscription" "api_push" {
  name  = "crisissync-api-push"
  topic = google_pubsub_topic.incidents.name

  push_config {
    push_endpoint = "${google_cloud_run_v2_service.api.uri}/pubsub/push"
    oidc_token {
      service_account_email = google_service_account.pubsub_invoker.email
    }
  }
  ack_deadline_seconds       = 20
  message_retention_duration = "86400s"
}

resource "google_pubsub_topic" "alerts" {
  name = "crisissync-alerts"
}

# ── BigQuery — Analytics Warehouse ──────────────────────────────────────────
resource "google_bigquery_dataset" "analytics" {
  dataset_id                  = "crisissync_analytics"
  friendly_name               = "CrisisSync Analytics"
  location                    = "US"
  delete_contents_on_destroy  = false
}

resource "google_bigquery_table" "incidents" {
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  table_id   = "incidents"
  schema     = file("${path.module}/schemas/incidents.json")
}

resource "google_bigquery_table" "response_metrics" {
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  table_id   = "response_metrics"
  schema     = file("${path.module}/schemas/response_metrics.json")
}

# ── Secret Manager ───────────────────────────────────────────────────────────
resource "google_secret_manager_secret" "gemini_key" {
  secret_id = "gemini-api-key"
  replication { auto {} }
}

resource "google_secret_manager_secret" "maps_key" {
  secret_id = "maps-api-key"
  replication { auto {} }
}

# ── Service Accounts & IAM ───────────────────────────────────────────────────
resource "google_service_account" "api_sa" {
  account_id   = "crisissync-api"
  display_name = "CrisisSync API Service Account"
}

resource "google_service_account" "pubsub_invoker" {
  account_id   = "crisissync-pubsub"
  display_name = "CrisisSync Pub/Sub Invoker"
}

resource "google_project_iam_member" "api_firestore" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.api_sa.email}"
}

resource "google_project_iam_member" "api_bigquery" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.api_sa.email}"
}

resource "google_project_iam_member" "api_storage" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.api_sa.email}"
}

# ── Cloud Storage — CCTV Archive ─────────────────────────────────────────────
resource "google_storage_bucket" "cctv_archive" {
  name          = "${var.project_id}-cctv-archive"
  location      = "ASIA-SOUTH1"
  storage_class = "NEARLINE"
  lifecycle_rule {
    condition { age = 90 }
    action    { type = "SetStorageClass", storage_class = "COLDLINE" }
  }
}

resource "google_storage_bucket" "media" {
  name     = "${var.project_id}-incident-media"
  location = "ASIA-SOUTH1"
}
