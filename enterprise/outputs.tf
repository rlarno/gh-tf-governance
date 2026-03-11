output "organizations" {
  description = "Map of organizations managed by this config"
  value = {
    for org_name, org in github_enterprise_organization.orgs : org_name => {
      name         = org.name
      display_name = org.display_name
    }
  }
}

# ─── Values consumed by the enterprise-apply workflow ────────────
# The workflow reads these after terraform apply to auto-install the
# enterprise GitHub App on each newly created organization.

output "enterprise_slug" {
  description = "Enterprise slug (passed through for workflow use)"
  value       = var.enterprise_slug
}

output "github_app_id" {
  description = "Numeric App ID (passed through for JWT generation)"
  value       = var.github_app_id
}

output "github_app_client_id" {
  description = "App Client ID (used in the install-on-org API call)"
  value       = var.github_app_client_id
}

output "github_app_installation_id" {
  description = "Enterprise installation ID (used to obtain an enterprise access token)"
  value       = var.github_app_installation_id
}

output "organization_names" {
  description = "List of organization names managed by this config"
  value       = keys(github_enterprise_organization.orgs)
}
