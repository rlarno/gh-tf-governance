# ─── GitHub App Authentication ───────────────────────────────────

variable "github_app_id" {
  description = "The ID of the GitHub App installed on this organization"
  type        = string
}

variable "github_app_installation_id" {
  description = "The installation ID of the GitHub App on this organization"
  type        = string
}

variable "github_app_pem_file" {
  description = "The contents of the GitHub App private key PEM file"
  type        = string
  sensitive   = true
}

# ─── Organization ────────────────────────────────────────────────

variable "github_organization" {
  description = "Name of the GitHub Organization to manage"
  type        = string
}

# ─── Organization Settings ───────────────────────────────────────

variable "billing_email" {
  description = "Billing email address for the organization"
  type        = string
}

variable "company_name" {
  description = "Company name"
  type        = string
  default     = ""
}

variable "blog_url" {
  description = "Organization blog URL"
  type        = string
  default     = ""
}

variable "email" {
  description = "Public email address"
  type        = string
  default     = ""
}

variable "twitter_username" {
  description = "Twitter username"
  type        = string
  default     = ""
}

variable "location" {
  description = "Organization location"
  type        = string
  default     = ""
}

variable "organization_display_name" {
  description = "Display name for the organization"
  type        = string
  default     = ""
}

variable "description" {
  description = "Organization description"
  type        = string
  default     = ""
}

variable "has_organization_projects" {
  description = "Enable organization projects"
  type        = bool
  default     = true
}

variable "has_repository_projects" {
  description = "Enable repository projects"
  type        = bool
  default     = true
}

variable "default_repository_permission" {
  description = "Default permission for organization members (read, write, admin, none)"
  type        = string
  default     = "read"
  validation {
    condition     = contains(["read", "write", "admin", "none"], var.default_repository_permission)
    error_message = "Must be one of: read, write, admin, none."
  }
}

variable "members_can_create_repositories" {
  description = "Whether members can create repositories"
  type        = bool
  default     = true
}

variable "members_can_create_public_repositories" {
  description = "Whether members can create public repositories"
  type        = bool
  default     = false
}

variable "members_can_create_private_repositories" {
  description = "Whether members can create private repositories"
  type        = bool
  default     = true
}

variable "members_can_create_internal_repositories" {
  description = "Whether members can create internal repositories"
  type        = bool
  default     = true
}

variable "members_can_create_pages" {
  description = "Whether members can create pages"
  type        = bool
  default     = true
}

variable "members_can_create_public_pages" {
  description = "Whether members can create public pages"
  type        = bool
  default     = false
}

variable "members_can_create_private_pages" {
  description = "Whether members can create private pages"
  type        = bool
  default     = true
}

variable "members_can_fork_private_repositories" {
  description = "Whether members can fork private repositories"
  type        = bool
  default     = false
}

variable "web_commit_signoff_required" {
  description = "Whether web commits must be signed off"
  type        = bool
  default     = false
}

variable "advanced_security_enabled_for_new_repositories" {
  description = "Enable advanced security for new repositories"
  type        = bool
  default     = false
}

variable "dependabot_alerts_enabled_for_new_repositories" {
  description = "Enable Dependabot alerts for new repositories"
  type        = bool
  default     = true
}

variable "dependabot_security_updates_enabled_for_new_repositories" {
  description = "Enable Dependabot security updates for new repositories"
  type        = bool
  default     = true
}

variable "dependency_graph_enabled_for_new_repositories" {
  description = "Enable dependency graph for new repositories"
  type        = bool
  default     = true
}

variable "secret_scanning_enabled_for_new_repositories" {
  description = "Enable secret scanning for new repositories"
  type        = bool
  default     = false
}

variable "secret_scanning_push_protection_enabled_for_new_repositories" {
  description = "Enable secret scanning push protection for new repositories"
  type        = bool
  default     = false
}

# ─── Teams ───────────────────────────────────────────────────────

variable "teams" {
  description = "Map of teams to create. Members is an optional map of username => role (member or maintainer)."
  type = map(object({
    description = string
    privacy     = string
    members     = optional(map(string), {})
  }))
  default = {}
}

# ─── Members ─────────────────────────────────────────────────────

variable "members" {
  description = "Map of organization members (username => { role })"
  type = map(object({
    role = string
  }))
  default = {}
}

# ─── Repositories ────────────────────────────────────────────────

variable "repositories" {
  description = "Map of repositories to create"
  type = map(object({
    description            = optional(string, "")
    visibility             = optional(string, "internal")
    has_issues             = optional(bool, true)
    has_discussions        = optional(bool, false)
    has_projects           = optional(bool, true)
    has_wiki               = optional(bool, false)
    is_template            = optional(bool, false)
    auto_init              = optional(bool, true)
    allow_merge_commit     = optional(bool, true)
    allow_squash_merge     = optional(bool, true)
    allow_rebase_merge     = optional(bool, true)
    allow_auto_merge       = optional(bool, false)
    delete_branch_on_merge = optional(bool, true)
    vulnerability_alerts   = optional(bool, true)
    team_access            = optional(map(string), {})
  }))
  default = {}
}
