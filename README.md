---
title: GitHub Organization Governance with Terraform
description: Manage GitHub Enterprise organizations, settings, teams, repositories, and members using IaC with a single enterprise-level GitHub App
---

## Overview

Manage GitHub Enterprise organizations, settings, teams, repositories, and members using Infrastructure as Code (Terraform) with automated GitHub Actions workflows — all powered by a **single enterprise-level GitHub App**.

## Architecture

This repository uses a **two-tier model** with separate responsibilities. Both tiers share the **same GitHub App**, each using a different installation of that app.

| Tier             | Who                | What                                           | Directory     | App Installation        |
|------------------|--------------------|-------------------------------------------------|---------------|-------------------------|
| **Enterprise**   | IT / Platform team | Create organizations, assign initial org owners | `enterprise/` | Enterprise installation |
| **Organization** | Org admin team     | Org settings, policies, teams, repos, members   | `orgs/<org>/` | Per-org installation    |

```text
.
├── enterprise/                         # Tier 1 — IT manages the enterprise
│   ├── main.tf                         #   Creates orgs + assigns admin_logins
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   └── enterprise.auto.tfvars          #   Enterprise config (committed)
│
├── orgs/                               # Tier 2 — Org admins manage each org
│   └── <org-name>/                     #   One directory per organization
│       ├── main.tf                     #     Settings, teams, repos, members
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       └── <org-name>.auto.tfvars      #     Org config (committed)
│
├── .github/workflows/
│   ├── enterprise-plan.yml             # Plan on PRs touching enterprise/
│   ├── enterprise-apply.yml            # Apply on merge — creates orgs + auto-installs app
│   ├── org-plan.yml                    # Plan on PRs touching orgs/
│   └── org-apply.yml                   # Apply on merge touching orgs/
│
├── docs/adr/                           # Architecture Decision Records
│   └── 0001-use-terraform-data-...md   #   Documents the provider limitation & history
│
├── .gitignore
└── README.md
```

### How the Two Tiers Connect

1. **IT** bootstraps the first governance organization manually and installs the enterprise app on it (one-time setup, see below).
2. **IT** adds subsequent orgs to `enterprise/enterprise.auto.tfvars` with `admin_logins`.
3. The enterprise workflow creates the org and **automatically installs the enterprise app on it**.
4. The workflow logs the new **per-org installation ID**.
5. An org admin creates `orgs/<org>/` with that installation ID in the `.auto.tfvars`.
6. The org workflow applies settings, teams, repos, and members using the per-org installation.

> **Key benefit** — no per-org GitHub App needs to be created. The single enterprise app is reused everywhere. Only the installation ID differs per org.

## Prerequisites

* **GitHub Enterprise Cloud** account — you must be an enterprise **owner** for the enterprise tier
* **Terraform** >= 1.0 and **Git** installed locally (for optional local testing)

---

## Setup Guide — Enterprise Tier (IT)

### Step 1 — Create the Enterprise GitHub App

1. Open your enterprise app settings:
   `https://github.com/enterprises/<slug>/settings/apps/new`
   (or **Enterprise settings → Developer settings → GitHub Apps → New GitHub App**)
2. Fill in the basics:

   | Field                | Value                                   |
   |----------------------|-----------------------------------------|
   | **App name**         | `Enterprise Governance`                 |
   | **Homepage URL**     | `https://github.com/enterprises/<slug>` |
   | **Webhook → Active** | **Uncheck**                             |

3. Under **Permissions**, grant:

   | Category     | Permission                                       | Access           |
   |--------------|--------------------------------------------------|------------------|
   | Enterprise   | Enterprise organisation installation repositories | **Read & write** |
   | Enterprise   | Enterprise organisation installations             | **Read & write** |
   | Enterprise   | Enterprise organisations                          | **Read & write** |
   | Organization | Administration                                    | **Read & write** |
   | Organization | Members                                           | **Read & write** |
   | Repository   | Administration                                    | **Read & write** |

   > The enterprise permissions allow the app to create organizations and install itself on them. The organization and repository permissions become active when the app is installed on an individual org.

4. Under **Where can this GitHub App be installed?**, select **Only on this account**.
5. Click **Create GitHub App**.
6. Note the **App ID** (numeric) and the **Client ID** (`Iv23li…`).
7. Scroll to **Private keys → Generate a private key** — save the `.pem` file securely.

### Step 2 — Install the App on the Enterprise

1. On the app page, select the created app.
2. Go to **Install App** → install on the **enterprise**.
3. Note the **Enterprise Installation ID** from the URL:
   `https://github.com/enterprises/<slug>/settings/installations/<installation_id>`

> This enterprise installation grants only enterprise-level permissions (create orgs, install apps). Organization and repository permissions are granted separately per org installation.

### Step 3 — Bootstrap the First Organization

The Terraform GitHub provider needs the enterprise app to be installed on each organization it manages. Because a brand-new org does not yet have that installation, you must create and configure the first organization manually.

1. Go to **Enterprise settings → Organizations → New organization**.
2. Create an organization named `<slug>-governance` (e.g. `rla-cf-ent-governance`). This is the governance seed organization.
3. Install the enterprise app on this org:
   * Open the app settings page → **Install App** → select the new organization → install with **All repositories**.
   * Alternatively, use the REST API:

     ```text
     POST /enterprises/{enterprise}/apps/organizations/{org}/installations
     Body: { "client_id": "<app-client-id>", "repository_selection": "all" }
     ```

4. Note the **per-org installation ID** from the URL:
   `https://github.com/organizations/<org>/settings/installations/<installation_id>`

> [!IMPORTANT]
> Subsequent organizations created via Terraform do **not** require this manual step. The enterprise-apply workflow auto-installs the app on each new org after `terraform apply` succeeds.

### Step 4 — Import the Bootstrap Org into Terraform

```bash
cd enterprise
terraform init

export TF_VAR_github_app_pem_file="$(cat path/to/enterprise-app.pem)"

terraform import 'github_enterprise_organization.orgs["<org-name>"]' <org-name>
terraform plan
```

PowerShell equivalent:

```powershell
Set-Location enterprise
terraform init

$env:TF_VAR_github_app_pem_file = Get-Content -Raw "path\to\enterprise-app.pem"

terraform import 'github_enterprise_organization.orgs["<org-name>"]' <org-name>
terraform plan
```

Verify that the plan shows no changes (or only expected drift). If it succeeds, the provider can read the org through the enterprise app's per-org installation.

### Step 5 — Add the Repository Secret

In this repository, go to **Settings → Secrets and variables → Actions** and create:

| Secret name           | Value                            |
|-----------------------|----------------------------------|
| `ENT_APP_PRIVATE_KEY` | Full contents of the `.pem` file |

This single secret is used by **all four workflows** (enterprise and org tiers).

### Step 6 — Configure the Enterprise Environment

1. Go to **Settings → Environments → New environment**
2. Name it `enterprise`
3. Enable **Required reviewers** — add IT team leads
4. Save

### Step 7 — Edit Enterprise Config

Edit `enterprise/enterprise.auto.tfvars`:

```hcl
github_app_id              = "123456"
github_app_client_id       = "Iv23liXXXXXXXXXXXXXX"
github_app_installation_id = "78901234"
enterprise_slug            = "rla-cf-ent"

organizations = {
  # Bootstrap org — created manually, imported into state
  "rla-cf-ent-governance" = {
    display_name  = "RLA CF Governance"
    description   = "Enterprise governance seed organization"
    billing_email = "billing@example.com"
    admin_logins  = ["platform-admin_rce"]
  }

  # Additional orgs — Terraform creates these
  "my-new-org" = {
    display_name  = "My New Org"
    description   = "Created via Terraform"
    billing_email = "billing@example.com"
    admin_logins  = ["alice", "bob"]
  }
}
```

### Step 8 — Push via PR

1. Create a branch, commit your changes, push, and open a PR.
2. The **Enterprise: Terraform Plan** workflow runs and posts the plan as a PR comment.
3. Merge to `main` — the **Enterprise: Terraform Apply** workflow:
   * Creates new organization(s) via the Terraform GitHub provider
   * Automatically installs the enterprise app on each org
   * Logs the **per-org installation ID** for each org in the workflow output

---

## Setup Guide — Organization Tier (Org Admins)

After IT creates your org and the enterprise workflow installs the app, follow these steps.

### Step 1 — Get the Org Installation ID

The enterprise-apply workflow prints the per-org installation ID in its log output. Ask IT for this value, or find it in the workflow run log:

```text
► Installing app on org: my-new-org
  ✅ Installed — org installation ID: 56789012
     Use this installation ID in orgs/my-new-org/my-new-org.auto.tfvars
```

Alternatively, the installation ID is visible at:
`https://github.com/organizations/<org-name>/settings/installations/<installation_id>`

### Step 2 — Configure the Org Environment

1. Go to **Settings → Environments → New environment**
2. Name it `org-<org-name>` (e.g. `org-rla-cf-gov02`)
3. Enable **Required reviewers** — add the org admin team
4. Save

### Step 3 — Create the Org Directory

Create the directory `orgs/<org-name>/` with the standard Terraform files. Copy from the existing `orgs/rla-cf-gov02/` template and update:

* `<org>.auto.tfvars` — set the **same App ID** as the enterprise tier, set the **org-specific installation ID** from Step 1, then configure settings, teams, and repos

### Step 4 — Edit Org Config

Edit `orgs/<org-name>/<org-name>.auto.tfvars`:

```hcl
# Same App ID as the enterprise tier — it is the same app
github_app_id              = "123456"
# Org-specific installation ID from the enterprise workflow output
github_app_installation_id = "56789012"
github_organization        = "my-new-org"
billing_email              = "billing@example.com"

teams = {
  "my-new-org_admin" = {
    description = "Organization administrators"
    privacy     = "secret"
    members = {
      "alice" = "maintainer"
      "bob"   = "maintainer"
    }
  }
  "developers" = {
    description = "Development team"
    privacy     = "closed"
    members     = {}
  }
}

repositories = {
  "my-service" = {
    description = "My microservice"
    visibility  = "internal"
    team_access = {
      "developers" = "push"
    }
  }
}
```

### Step 5 — Push via PR

1. Create a branch, commit, push, open a PR.
2. The **Org: Terraform Plan** workflow detects which org(s) changed and plans them individually.
3. Merge to `main` — the **Org: Terraform Apply** workflow applies to each changed org.

---

## How It Works

### Why One Enterprise App

A single enterprise-level GitHub App covers both tiers by using **two kinds of installation**:

| Installation target | What it can do                                    | Used by           |
|---------------------|---------------------------------------------------|--------------------|
| **Enterprise**      | Create organizations, install the app on new orgs | Enterprise tier    |
| **Per-org**         | Manage org settings, teams, repos, members        | Organization tier  |

Each installation has its own `installation_id` and independent rate limit. The enterprise installation is **not** granted access to organization or repository resources — that access is provided by the per-org installation.

The enterprise-apply workflow automates the per-org installation via the REST API:

```text
POST /enterprises/{enterprise}/apps/organizations/{org}/installations
```

This call is idempotent — if the app is already installed on an org, it is skipped.

### Why a GitHub App Instead of a PAT

|                  | Personal Access Token                     | GitHub App                            |
|------------------|-------------------------------------------|---------------------------------------|
| **SAML SSO**     | Blocked until manually authorized per org | Bypasses SAML automatically           |
| **Scope**        | Tied to a personal user account           | Scoped to enterprise or org           |
| **Expiry**       | Expires — requires manual renewal         | Private key does not expire           |
| **Audit trail**  | Actions attributed to a person            | Actions attributed to the app         |
| **Permissions**  | Broad OAuth scopes                        | Fine-grained per-resource permissions |

### Bootstrap Requirement

The GitHub Terraform provider's `github_enterprise_organization` resource creates organizations via the GraphQL API but reads and updates them via the REST API. The REST calls require the enterprise app to be **installed on the target org**. For a brand-new org this creates a chicken-and-egg situation: the org must exist before the app can be installed, but the provider needs the installation to read the org.

The solution: create the **first** organization manually, install the app on it, and import it into Terraform state. All subsequent orgs created via Terraform are handled by the workflow's auto-install step, which installs the app immediately after `terraform apply`.

For full details on this decision and the alternatives considered, see [docs/adr/0001-use-terraform-data-for-enterprise-org-creation.md](docs/adr/0001-use-terraform-data-for-enterprise-org-creation.md).

### Workflow Triggers

| Path changed     | Plan workflow         | Apply workflow          | Credentials used                                   |
|-------------------|-----------------------|--------------------------|-----------------------------------------------------|
| `enterprise/**`  | `enterprise-plan.yml` | `enterprise-apply.yml`   | `ENT_APP_PRIVATE_KEY` + enterprise installation ID  |
| `orgs/<org>/**`  | `org-plan.yml`        | `org-apply.yml`          | `ENT_APP_PRIVATE_KEY` + per-org installation ID     |

The org workflows use a **matrix strategy** — if a single PR changes multiple orgs, each org is planned/applied independently in parallel.

### Secrets

Only **one** repository secret is needed:

| Secret name           | Used by            | Value                            |
|-----------------------|--------------------|----------------------------------|
| `ENT_APP_PRIVATE_KEY` | All four workflows | Full contents of the `.pem` file |

The `github_app_id` and `github_app_installation_id` values are non-secret and stored in the committed `.auto.tfvars` files.

---

## Adding a New Organization

1. **IT** adds the org to `enterprise/enterprise.auto.tfvars` → merge PR → org is created.
2. The enterprise-apply workflow **auto-installs** the app on the new org and logs the per-org installation ID.
3. **IT** shares the per-org installation ID with the org admin.
4. **Org admin** creates `org-<org-name>` environment with required reviewers.
5. **Org admin** copies `orgs/rla-cf-gov02/` as a template → `orgs/<new-org>/`, sets the org installation ID and configures settings in `.auto.tfvars`.
6. Merge PR → org is configured.

---

## Local Testing

### Enterprise Tier

```bash
cd enterprise
terraform init
terraform fmt
terraform validate

# Provide the private key
export TF_VAR_github_app_pem_file="$(cat path/to/enterprise-app.pem)"
terraform plan
```

### Org Tier

```bash
cd orgs/rla-cf-gov02
terraform init
terraform fmt
terraform validate

# Same private key — it is the same app
export TF_VAR_github_app_pem_file="$(cat path/to/enterprise-app.pem)"
terraform plan
```

PowerShell equivalent:

```powershell
$env:TF_VAR_github_app_pem_file = Get-Content -Raw "path\to\enterprise-app.pem"
```

---

## Troubleshooting

### "Could not negotiate an installation token"

* `github_app_id` must match the numeric App ID on the app settings page.
* `github_app_installation_id` must match the correct installation: enterprise ID for the enterprise tier, per-org ID for the org tier.
* `github_app_pem_file` must contain the **full** PEM including `-----BEGIN/END RSA PRIVATE KEY-----`.
* If you regenerated the private key, old keys are revoked — update the `ENT_APP_PRIVATE_KEY` secret.

### "Resource protected by organization SAML enforcement"

This should **not** happen with GitHub App auth. Verify the provider is using `app_auth`, not a personal token.

### "Resource not accessible by integration" on terraform plan

The enterprise app is not installed on the target organization. Either:

* The org was just created and the workflow's auto-install step has not run yet.
* The app was removed from the org.

Reinstall the app on the org via **Enterprise settings → Developer settings → GitHub Apps → Install App → select the org**, or use the REST API.

### Enterprise Apply Succeeds but Org Plan Fails

* Verify the enterprise workflow installed the app on the org (check the workflow log for the installation ID).
* Verify the per-org installation ID in the org's `.auto.tfvars` matches the ID from the workflow log.

### "Install enterprise app" Step Reports Errors

* Verify the App Client ID (`Iv23li…`) in `enterprise.auto.tfvars` is correct.
* Verify the app has the **Enterprise organisation installations: Read & write** permission.
* The API may return `422` if the app is already installed — this is expected and skipped.

### Plan Shows Unexpected Changes

Settings may have been changed manually in the GitHub UI. Terraform syncs them back on the next apply.

---

## Security Best Practices

* **Never commit private keys** — use GitHub Secrets only.
* **Use environment protection** — require approval for both `enterprise` and `org-*` environments.
* **One app, scoped installations** — the enterprise installation can only manage enterprise-level resources; per-org installations can only manage their own org.
* **Review plans carefully** — always check the plan output before approving.
* **Enable branch protection** — require PR reviews before merging to main.
* **Regenerate keys if compromised** — revoke old keys in the app settings and update the single `ENT_APP_PRIVATE_KEY` secret.
* **Audit app activity** — review enterprise and org audit logs.

---

## Resources

* [GitHub Terraform Provider — App Authentication](https://registry.terraform.io/providers/integrations/github/latest/docs#github-app-installation)
* [Creating a GitHub App](https://docs.github.com/en/apps/creating-github-apps/about-creating-github-apps/about-creating-github-apps)
* [Installing a GitHub App on Your Enterprise](https://docs.github.com/en/enterprise-cloud@latest/apps/using-github-apps/installing-a-github-app-on-your-enterprise)
* [Automating Enterprise App Installations](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-github-apps-for-your-enterprise/automate-installations)
* [Enterprise Organization Resource](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/enterprise_organization)
* [Organization Settings Resource](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/organization_settings)
* [GitHub Actions Documentation](https://docs.github.com/en/actions)
