# GitHub Organization Governance with Terraform

Manage a GitHub organization — settings, teams, and members — using Infrastructure as Code (Terraform) with automated GitHub Actions workflows.

## What This Does

- **Configures organization settings** (permissions, policies, security defaults)
- **Manages teams and members** declaratively
- **Automates plan/apply** through GitHub Actions with PR-based reviews
- **Uses GitHub App authentication** — no personal access tokens, fully unattended, and SAML SSO–safe

> **Note** — This module manages an **existing** organization. Organization creation is a one-time enterprise admin task done through the GitHub UI (see [Why Not Create the Org via Terraform?](#why-not-create-the-org-via-terraform) for details).

## Prerequisites

1. **GitHub Enterprise Cloud** account with an **existing organization**
2. **Terraform** >= 1.0 and **Git** installed locally (for optional local testing)

## Setup Guide

### Step 1 — Create a GitHub App

1. Open your organization's app settings:
   `https://github.com/organizations/<org-name>/settings/apps/new`
   (or **Organization settings → Developer settings → GitHub Apps → New GitHub App**)
2. Fill in the basics:

   | Field | Value |
   |---|---|
   | **App name** | `Terraform Governance` (or any name you like) |
   | **Homepage URL** | Your repository URL (or any placeholder) |
   | **Webhook → Active** | **Uncheck** (no webhook needed) |

3. Under **Permissions**, grant:

   | Category | Permission | Access |
   |---|---|---|
   | Organization | Administration | **Read & write** |
   | Organization | Members | **Read & write** |

   No other permissions are needed.

4. Under **Where can this GitHub App be installed?**, select **Only on this account**.
5. Click **Create GitHub App**.
6. On the app page note the **App ID** (displayed near the top).
7. Scroll to **Private keys → Generate a private key** — a `.pem` file downloads. Keep it safe.

### Step 2 — Install the GitHub App

1. On the app settings page, click **Install App** (left sidebar).
2. Click **Install** next to your organization.
3. Choose **All repositories** (the app needs org-level access, not repo-level).
4. Click **Install**.
5. Note the **Installation ID** from the browser URL:
   `https://github.com/organizations/<org-name>/settings/installations/<installation_id>`

### Step 3 — Clone or Create This Repository

```bash
git clone https://github.com/YOUR-ORG/gh-tf-governance.git
cd gh-tf-governance
```

### Step 4 — Configure Organization Settings

All non-secret configuration lives in `terraform.auto.tfvars` (committed to Git).

| Layer | Location | Contents | Committed? |
|---|---|---|---|
| **Config** | `terraform.auto.tfvars` | App ID, Installation ID, org name, teams, members, policies | ✅ Yes |
| **Secret** | GitHub Actions secret | GitHub App private key (`github_app_pem_file`) | ❌ No |

Edit `terraform.auto.tfvars`:

```hcl
# GitHub App Authentication
github_app_id              = "123456"       # App ID from Step 1
github_app_installation_id = "78901234"     # Installation ID from Step 2

# Organization Identity
github_organization = "your-org-name"
billing_email       = "billing@example.com"

# Org display, policies, teams, members …
```

> **Important** — Never add `github_app_pem_file` (the private key) to any committed file.

### Step 5 — Add the GitHub Actions Secret

Go to **Repository Settings → Secrets and variables → Actions → New repository secret**:

| Secret name | Value |
|---|---|
| `GH_APP_PRIVATE_KEY` | Paste the **entire** contents of the `.pem` file (including the `-----BEGIN/END RSA PRIVATE KEY-----` lines) |

No repository **variables** are needed — everything else is in `terraform.auto.tfvars`.

### Step 6 — Configure Environment Protection (Recommended)

1. Go to **Repository Settings → Environments → New environment**
2. Name it `production`
3. Enable **Required reviewers** and add yourself or team leads
4. Save protection rules

This ensures Terraform Apply requires human approval before changing your organization.

### Step 7 — Local Testing (Optional)

```bash
terraform init
terraform fmt
terraform validate
terraform plan
```

For local runs, provide the private key via an environment variable:

```powershell
# PowerShell
$env:TF_VAR_github_app_pem_file = Get-Content -Raw "path/to/your-app.pem"
```

```bash
# Linux / macOS
export TF_VAR_github_app_pem_file="$(cat path/to/your-app.pem)"
```

Terraform auto-loads `terraform.auto.tfvars` for everything else (App ID, Installation ID, org config).

### Step 8 — Push and Create a Pull Request

1. Push your configuration:

   ```bash
   git add .
   git commit -m "Configure organization settings"
   git push origin main
   ```

2. For subsequent changes, use a branch:

   ```bash
   git checkout -b update-org-settings
   # Edit .tf or .auto.tfvars files
   git add .
   git commit -m "Update organization settings"
   git push origin update-org-settings
   ```

3. Open a Pull Request — the **Terraform Plan** workflow runs automatically and posts the plan as a PR comment.

### Step 9 — Apply Changes

1. Merge the PR to `main`.
2. The **Terraform Apply** workflow runs automatically.
3. If environment protection is configured, approve the deployment when prompted.
4. Terraform applies the declared settings, teams, and members to your organization.

## How It Works

### Why a GitHub App Instead of a PAT?

| | Personal Access Token | GitHub App |
|---|---|---|
| **SAML SSO** | Blocked until manually authorized per org | ✅ Bypasses SAML automatically |
| **Scope** | Tied to a personal user account | Scoped to the org installation |
| **Expiry** | Expires — requires manual renewal | Private key does not expire |
| **Audit trail** | Actions attributed to a person | Actions attributed to the app |
| **Permissions** | Broad OAuth scopes | Fine-grained per-resource permissions |

### Why Not Create the Org via Terraform?

The `github_enterprise_organization` resource requires **enterprise-level** permissions. GitHub App enterprise permissions are only available when the app is registered under the **enterprise account itself** (not under an organization). Even then, the Terraform GitHub provider accepts a single `installation_id`, and enterprise installations and organization installations are separate — you cannot span both in one provider block.

Since org creation is a **one-time** action, it is simpler and more reliable to create the org through the enterprise admin UI:

**Enterprise settings → Organizations → New organization**

After the org exists, this module handles all ongoing governance via an org-level GitHub App.

### Workflows

**Terraform Plan** (`.github/workflows/terraform-plan.yml`)

- Triggers on pull requests that modify `.tf` or `.auto.tfvars` files
- Runs `terraform plan` and posts the output as a PR comment
- Does **not** change anything

**Terraform Apply** (`.github/workflows/terraform-apply.yml`)

- Triggers on push to `main` (same file patterns) or manual dispatch
- Runs `terraform plan` then `terraform apply`
- Uses the `production` environment gate (if configured)
- Creates a GitHub issue on failure

### File Structure

```text
.
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml        # Runs plan on PRs
│       └── terraform-apply.yml       # Applies on merge to main
├── main.tf                           # Provider + all resources
├── variables.tf                      # Input variable definitions
├── outputs.tf                        # Output values
├── versions.tf                       # Terraform & provider versions
├── terraform.auto.tfvars             # Committed org config (no secrets)
├── .terraform.lock.hcl               # Provider lock file (committed)
├── .gitignore                        # Git ignore rules
└── README.md                         # This guide
```

## Common Customizations

### Adding a Team

Edit `terraform.auto.tfvars`:

```hcl
teams = {
  "engineering" = {
    description = "Engineering team"
    privacy     = "closed"    # visible to all org members
  }
  "security" = {
    description = "Security team"
    privacy     = "secret"    # visible only to team members
  }
}
```

### Adding Members

```hcl
members = {
  "octocat" = {
    role = "member"
  }
  "admin-user" = {
    role = "admin"
  }
}
```

### Enabling Security Features

```hcl
advanced_security_enabled_for_new_repositories               = true
dependabot_alerts_enabled_for_new_repositories               = true
secret_scanning_enabled_for_new_repositories                 = true
secret_scanning_push_protection_enabled_for_new_repositories = true
```

### Using a Remote State Backend

For team use, uncomment the `backend` block in `versions.tf`:

```hcl
backend "azurerm" {
  resource_group_name  = "terraform-state-rg"
  storage_account_name = "tfstatexxxxxx"
  container_name       = "tfstate"
  key                  = "github-org.tfstate"
}
```

Other backends (Terraform Cloud, S3, GCS) work the same way.

## Troubleshooting

### "this resource can only be used in the context of an organization"

The provider cannot reach the org via the REST API.

- Verify `github_app_installation_id` is correct.
- Confirm the GitHub App is installed on the **target organization**.
- Check the app has **Organization → Administration: Read & write**.

### "Could not negotiate an installation token"

The app credentials are invalid.

- `github_app_id` must match the App ID shown on the app settings page.
- `github_app_pem_file` must contain the **full** PEM including `-----BEGIN/END RSA PRIVATE KEY-----`.
- If you regenerated the private key, old keys are revoked — update the secret.

### "Resource protected by organization SAML enforcement"

This should **not** happen with GitHub App auth (apps bypass SAML). If it does:

- Confirm the provider is using `app_auth`, not a personal token.
- Verify the app is installed on the target organization.

### Plan Shows Unexpected Changes

Settings may have been changed manually in the GitHub UI. Terraform syncs them back to match your configuration on the next apply.

### "Resource not accessible by integration"

The GitHub App is missing a required permission. Update the app's permissions in the app settings page — the installation will prompt for re-approval.

## Security Best Practices

1. **Never commit the private key** — use GitHub Secrets only.
2. **Use environment protection** — require approval for production changes.
3. **Restrict app installation scope** — keep the app installed only on managed orgs.
4. **Review plans carefully** — always check the plan output before approving.
5. **Enable branch protection** — require PR reviews before merging to main.
6. **Regenerate keys if compromised** — revoke old keys in the app settings.
7. **Audit app activity** — review the organization audit log for app-initiated events.

## Resources

- [GitHub Terraform Provider — App Authentication](https://registry.terraform.io/providers/integrations/github/latest/docs#github-app-installation)
- [Creating a GitHub App](https://docs.github.com/en/apps/creating-github-apps/about-creating-github-apps/about-creating-github-apps)
- [Permissions Required for GitHub Apps](https://docs.github.com/en/rest/overview/permissions-required-for-github-apps)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform Documentation](https://www.terraform.io/docs)
