# ╔══════════════════════════════════════════════════════════════════╗
# ║  Enterprise configuration                                      ║
# ║  This file IS committed to Git and auto-loaded by Terraform.   ║
# ║                                                                ║
# ║  The only secret injected via the workflow:                    ║
# ║    github_app_pem_file  (via TF_VAR_github_app_pem_file)       ║
# ║  DO NOT add the private key here.                              ║
# ╚══════════════════════════════════════════════════════════════════╝

# GitHub App Authentication (single enterprise-level app for both tiers)
github_app_id              = "YOUR_ENT_APP_ID"
github_app_client_id       = "YOUR_ENT_APP_CLIENT_ID"
github_app_installation_id = "YOUR_ENT_APP_INSTALLATION_ID"

# Enterprise
enterprise_slug = "rla-cf-ent"

# ─── Organizations ───────────────────────────────────────────────
# Add a new block for each organization to create.
# admin_logins = the initial org owners (typically the org admin team).
# After creation, org admins manage the org via orgs/<org-name>/.

organizations = {
  "rla-cf-gov02" = {
    display_name  = "RLA CF Gov02"
    description   = "Governance organization"
    billing_email = "billing@example.com"
    admin_logins  = ["product-owner_rce"]
  }

  # "rla-cf-dev01" = {
  #   display_name  = "RLA CF Dev01"
  #   description   = "Development organization"
  #   billing_email = "billing@example.com"
  #   admin_logins  = ["dev-lead_rce"]
  # }
}
