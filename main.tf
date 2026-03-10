# ─── Provider ────────────────────────────────────────────────────
# Authenticates via a GitHub App installed on the target organization.
# The app bypasses SAML SSO — no manual token authorization needed.

provider "github" {
  owner = var.github_organization

  app_auth {
    id              = var.github_app_id
    installation_id = var.github_app_installation_id
    pem_file        = var.github_app_pem_file
  }
}

# ─── Organization Settings ──────────────────────────────────────

resource "github_organization_settings" "org" {
  billing_email                                                = var.billing_email
  company                                                      = var.company_name
  blog                                                         = var.blog_url
  email                                                        = var.email
  twitter_username                                             = var.twitter_username
  location                                                     = var.location
  name                                                         = var.organization_display_name
  description                                                  = var.description
  has_organization_projects                                    = var.has_organization_projects
  has_repository_projects                                      = var.has_repository_projects
  default_repository_permission                                = var.default_repository_permission
  members_can_create_repositories                              = var.members_can_create_repositories
  members_can_create_public_repositories                       = var.members_can_create_public_repositories
  members_can_create_private_repositories                      = var.members_can_create_private_repositories
  members_can_create_internal_repositories                     = var.members_can_create_internal_repositories
  members_can_create_pages                                     = var.members_can_create_pages
  members_can_create_public_pages                              = var.members_can_create_public_pages
  members_can_create_private_pages                             = var.members_can_create_private_pages
  members_can_fork_private_repositories                        = var.members_can_fork_private_repositories
  web_commit_signoff_required                                  = var.web_commit_signoff_required
  advanced_security_enabled_for_new_repositories               = var.advanced_security_enabled_for_new_repositories
  dependabot_alerts_enabled_for_new_repositories               = var.dependabot_alerts_enabled_for_new_repositories
  dependabot_security_updates_enabled_for_new_repositories     = var.dependabot_security_updates_enabled_for_new_repositories
  dependency_graph_enabled_for_new_repositories                = var.dependency_graph_enabled_for_new_repositories
  secret_scanning_enabled_for_new_repositories                 = var.secret_scanning_enabled_for_new_repositories
  secret_scanning_push_protection_enabled_for_new_repositories = var.secret_scanning_push_protection_enabled_for_new_repositories
}

# ─── Teams ───────────────────────────────────────────────────────

resource "github_team" "teams" {
  for_each = var.teams

  name        = each.key
  description = each.value.description
  privacy     = each.value.privacy
}

# ─── Members ─────────────────────────────────────────────────────

resource "github_membership" "members" {
  for_each = var.members

  username = each.key
  role     = each.value.role
}
