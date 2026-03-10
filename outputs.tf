output "teams" {
  description = "Map of created teams"
  value = {
    for team_name, team in github_team.teams : team_name => {
      id   = team.id
      slug = team.slug
      name = team.name
    }
  }
}

output "members" {
  description = "Map of organization members"
  value = {
    for username, member in github_membership.members : username => {
      username = member.username
      role     = member.role
    }
  }
}

output "organization_settings" {
  description = "Organization settings applied"
  value = {
    billing_email                   = github_organization_settings.org.billing_email
    company                         = github_organization_settings.org.company
    default_repository_permission   = github_organization_settings.org.default_repository_permission
    members_can_create_repositories = github_organization_settings.org.members_can_create_repositories
    has_organization_projects       = github_organization_settings.org.has_organization_projects
    has_repository_projects         = github_organization_settings.org.has_repository_projects
  }
}
