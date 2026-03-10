# ╔══════════════════════════════════════════════════════════════════╗
# ║  Organization configuration                                    ║
# ║  This file IS committed to Git and auto-loaded by Terraform.   ║
# ║                                                                ║
# ║  The only secret injected via the workflow:                    ║
# ║    github_app_pem_file  (via TF_VAR_github_app_pem_file)       ║
# ║  DO NOT add the private key here.                              ║
# ╚══════════════════════════════════════════════════════════════════╝

# GitHub App Authentication
github_app_id              = "YOUR_APP_ID"
github_app_installation_id = "YOUR_INSTALLATION_ID"

# Organization Identity
github_organization = "rla-cf-gov02"
billing_email       = "billing@example.com"

# Organization Display Settings
company_name              = "Your Company Name"
organization_display_name = "Your Organization"
description               = "Organization managed with Terraform"
blog_url                  = ""
email                     = ""
twitter_username          = ""
location                  = ""

# Repository Settings
default_repository_permission            = "read"
members_can_create_repositories          = true
members_can_create_public_repositories   = false
members_can_create_private_repositories  = true
members_can_create_internal_repositories = true
members_can_fork_private_repositories    = false
web_commit_signoff_required              = false

# Projects
has_organization_projects = true
has_repository_projects   = true

# Pages
members_can_create_pages         = true
members_can_create_public_pages  = false
members_can_create_private_pages = true

# Security Settings
advanced_security_enabled_for_new_repositories               = false
dependabot_alerts_enabled_for_new_repositories               = true
dependabot_security_updates_enabled_for_new_repositories     = true
dependency_graph_enabled_for_new_repositories                = true
secret_scanning_enabled_for_new_repositories                 = false
secret_scanning_push_protection_enabled_for_new_repositories = false

# Teams
teams = {
  "engineering" = {
    description = "Engineering team"
    privacy     = "closed"
  }
  "devops" = {
    description = "DevOps and Infrastructure team"
    privacy     = "closed"
  }
  "admins" = {
    description = "Organization administrators"
    privacy     = "secret"
  }
}

# Members
# Note: Users must accept the invitation before they appear in the organization
members = {
  # "octocat" = {
  #   role = "member"
  # }
  # "admin-user" = {
  #   role = "admin"
  # }
}
