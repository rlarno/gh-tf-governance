# ─── GitHub App Authentication ───────────────────────────────────

variable "github_app_id" {
  description = "The numeric ID of the enterprise-level GitHub App"
  type        = string
}

variable "github_app_client_id" {
  description = "The client ID of the enterprise-level GitHub App (Iv23li…). Used by the workflow to auto-install the app on newly created organizations."
  type        = string
}

variable "github_app_installation_id" {
  description = "The installation ID of the enterprise-level GitHub App (the enterprise installation)"
  type        = string
}

variable "github_app_pem_file" {
  description = "The contents of the GitHub App private key PEM file"
  type        = string
  sensitive   = true
}

# ─── Enterprise ──────────────────────────────────────────────────

variable "enterprise_slug" {
  description = "The slug of the GitHub Enterprise Cloud account (visible in the URL: github.com/enterprises/<slug>)"
  type        = string
}

# ─── Organizations ───────────────────────────────────────────────

variable "organizations" {
  description = "Map of organizations to create under the enterprise. Each key is the org name."
  type = map(object({
    display_name  = optional(string, "")
    description   = optional(string, "")
    billing_email = string
    admin_logins  = list(string)
  }))
  default = {}
}
