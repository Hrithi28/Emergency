variable "project_id" {
  description = "Google Cloud project ID"
  type        = string
  default     = "crisissync-prod"
}

variable "region" {
  description = "Google Cloud region"
  type        = string
  default     = "asia-south1"
}

variable "firebase_project" {
  description = "Firebase project ID (same as GCP project)"
  type        = string
  default     = "crisissync-prod"
}
