# ─── Provider ────────────────────────────────────────────────────
# Authenticates via a GitHub App installed on this organization.
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

resource "github_organization_settings" "this" {
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

# ─── Team Memberships ───────────────────────────────────────────

locals {
  # Flatten the teams × members map into a list of { team, username, role } tuples
  team_memberships = merge([
    for team_name, team in var.teams : {
      for username, role in coalesce(team.members, {}) :
      "${team_name}:${username}" => {
        team_id  = github_team.teams[team_name].id
        username = username
        role     = role
      }
    }
  ]...)
}

resource "github_team_membership" "memberships" {
  for_each = local.team_memberships

  team_id  = each.value.team_id
  username = each.value.username
  role     = each.value.role
}

# ─── Members ─────────────────────────────────────────────────────

resource "github_membership" "members" {
  for_each = var.members

  username = each.key
  role     = each.value.role
}

# ─── Repositories ────────────────────────────────────────────────

resource "github_repository" "repos" {
  for_each = var.repositories

  name        = each.key
  description = each.value.description
  visibility  = each.value.visibility

  has_issues      = each.value.has_issues
  has_discussions = each.value.has_discussions
  has_projects    = each.value.has_projects
  has_wiki        = each.value.has_wiki
  is_template     = each.value.is_template
  auto_init       = each.value.auto_init

  allow_merge_commit     = each.value.allow_merge_commit
  allow_squash_merge     = each.value.allow_squash_merge
  allow_rebase_merge     = each.value.allow_rebase_merge
  allow_auto_merge       = each.value.allow_auto_merge
  delete_branch_on_merge = each.value.delete_branch_on_merge

  vulnerability_alerts = each.value.vulnerability_alerts
}

# ─── Team Repository Access ─────────────────────────────────────

locals {
  # Flatten the repositories × team_access map into individual assignments
  team_repo_access = merge([
    for repo_name, repo in var.repositories : {
      for team_name, permission in coalesce(repo.team_access, {}) :
      "${repo_name}:${team_name}" => {
        repository = github_repository.repos[repo_name].name
        team_id    = github_team.teams[team_name].id
        permission = permission
      }
    } if repo.team_access != null
  ]...)
}

resource "github_team_repository" "access" {
  for_each = local.team_repo_access

  team_id    = each.value.team_id
  repository = each.value.repository
  permission = each.value.permission
}
