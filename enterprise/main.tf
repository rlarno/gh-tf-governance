# ─── Provider ────────────────────────────────────────────────────
# Authenticates via a GitHub App registered under the enterprise.
# Enterprise-level apps bypass SAML SSO and can create organizations.

provider "github" {
  owner = var.enterprise_slug

  app_auth {
    id              = var.github_app_id
    installation_id = var.github_app_installation_id
    pem_file        = var.github_app_pem_file
  }
}

# ─── Enterprise Lookup ───────────────────────────────────────────

data "github_enterprise" "this" {
  slug = var.enterprise_slug
}

# ─── Organizations ───────────────────────────────────────────────
# Creates organizations under the enterprise.
# admin_logins assigns the initial org owners — these users form the
# org's admin team and can then manage the org via the org-level workflow.

resource "github_enterprise_organization" "orgs" {
  for_each = var.organizations

  enterprise_id = data.github_enterprise.this.id
  name          = each.key
  display_name  = each.value.display_name != "" ? each.value.display_name : each.key
  description   = each.value.description
  billing_email = each.value.billing_email
  admin_logins  = each.value.admin_logins

  lifecycle {
    ignore_changes = [display_name, description, billing_email]
  }
}
