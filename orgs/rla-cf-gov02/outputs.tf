output "organization_settings" {
  description = "Organization settings applied"
  value = {
    billing_email                   = github_organization_settings.this.billing_email
    company                         = github_organization_settings.this.company
    default_repository_permission   = github_organization_settings.this.default_repository_permission
    members_can_create_repositories = github_organization_settings.this.members_can_create_repositories
    has_organization_projects       = github_organization_settings.this.has_organization_projects
    has_repository_projects         = github_organization_settings.this.has_repository_projects
  }
}

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

output "repositories" {
  description = "Map of created repositories"
  value = {
    for repo_name, repo in github_repository.repos : repo_name => {
      full_name      = repo.full_name
      html_url       = repo.html_url
      default_branch = repo.default_branch
      visibility     = repo.visibility
    }
  }
}
