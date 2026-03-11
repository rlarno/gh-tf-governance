---
title: Enterprise Organization Creation Strategy
description: >-
  Records the decision history for creating GitHub Enterprise organizations
  via Terraform with GitHub App authentication, including the terraform_data
  workaround and the subsequent bootstrap-and-native-provider approach.
ms.date: 2026-03-11
ms.topic: concept
keywords:
  - terraform
  - github enterprise
  - architecture decision record
  - github app
  - workaround
---

## Status

Superseded by Option 5 (bootstrap org + native provider resource)

## Context and Problem Statement

The `integrations/github` Terraform provider (v6.x) offers a
`github_enterprise_organization` resource to create organizations within a
GitHub Enterprise Cloud account. Our governance model requires a single
enterprise-level GitHub App for authentication across both the enterprise tier
and all managed organizations.

When using `app_auth` with the enterprise-level app, `terraform apply` fails
with:

```text
PATCH /orgs/rla-cf-local01: 403 Resource not accessible by integration
```

The root cause lies in the provider's internal implementation. The `Create`
function uses the **GraphQL v4** API (`createEnterpriseOrganization` mutation)
to provision the organization, then immediately calls the **REST v3** API
(`PATCH /orgs/{org}`) to set `display_name` and `description`. The enterprise
app installation token is scoped to the enterprise, not the newly created
organization. Because no per-org app installation exists yet, the REST call
returns a 403. This is a classic chicken-and-egg problem: the organization must
exist before the app can be installed on it, but the provider tries to
configure it via org-scoped REST before the installation can happen.

The same issue affects the `Read` and `Update` functions, which also call
org-level REST endpoints.

## Decision Drivers

* The organization creation workflow must be fully automated (no manual steps)
* Authentication must use a single enterprise-level GitHub App (no PATs)
* SAML SSO enforcement on the enterprise prevents PAT-based workarounds
* The solution must be idempotent for safe re-runs
* Terraform state must track created organizations

## Considered Options

1. Use `github_enterprise_organization` with `lifecycle { ignore_changes = all }`
2. Omit `display_name` and `description` from the resource
3. Replace the resource with `terraform_data` + `local-exec` provisioner
4. Wait for an upstream provider fix
5. Bootstrap one org manually, install the app, then use the native provider resource

## Decision Outcome

Originally chosen: **Option 3** (`terraform_data` + `local-exec`). This was
validated and worked, but introduced a PowerShell dependency and lost Terraform
drift detection.

Superseded by: **Option 5** (bootstrap + native provider). If the provider's
`Read` function succeeds when the enterprise app is installed on the target
org, the native `github_enterprise_organization` resource can be used directly.
The first organization is created manually and imported; the enterprise-apply
workflow auto-installs the app on subsequent orgs immediately after
`terraform apply`.

### Consequences (Option 5)

Positive outcomes:

* Uses the native Terraform resource with full drift detection
* No external scripts or PowerShell dependency in the Terraform run
* Standard `terraform import` workflow for the bootstrap org
* The enterprise-apply workflow auto-installs the app on new orgs via the REST
  API (`POST /enterprises/{enterprise}/apps/organizations/{org}/installations`)
* Idempotent: the install call returns 409/422 for already-installed orgs

Negative outcomes:

* Requires one manual step: create the first governance org and install the
  app before Terraform can manage any organizations
* New orgs created by `terraform apply` may fail on the provider's `Read`
  function until the workflow's auto-install step completes (this is the
  hypothesis being tested)
* Destroying the resource does not remove the organization (GitHub does not
  support organization deletion via API)

### Consequences (Option 3, historical)

Positive outcomes:

* Organization creation and app installation happen in a single atomic step
* The provisioner script handles existing organizations gracefully
* Terraform state tracks each organization through `terraform_data.orgs`
* No dependency on upstream provider fixes

Negative outcomes:

* The provisioner requires PowerShell and depends on external scripts
* Terraform cannot detect drift on organization settings
* Future provider fixes make this workaround unnecessary, creating
  technical debt

## Analysis of Options

### Option 1: lifecycle ignore_changes = all

Adding `lifecycle { ignore_changes = all }` prevents Terraform from calling
`Read` or `Update` after initial creation. However, the `Create` function
itself calls `PATCH /orgs/{org}` to set display_name and description before
returning. The 403 occurs during creation, so `ignore_changes` does not help.

### Option 2: Omit display_name and description

Without `display_name` and `description`, the `Create` function skips the REST
`PATCH` call. This workaround is documented in upstream issue
[#2631](https://github.com/integrations/terraform-provider-github/issues/2631)
for PAT-based authentication. However, with `app_auth`, the `Read` function
also calls org-level REST endpoints to refresh state, causing the same 403 on
subsequent plans. This option works only with PAT authentication.

### Option 3: terraform_data + local-exec (chosen)

A `terraform_data` resource with `triggers_replace` set to the organization
name invokes a PowerShell script via `local-exec`. The script:

1. Generates a JWT from the app's private key
2. Exchanges it for an enterprise installation token
3. Creates the organization via the GraphQL `createEnterpriseOrganization`
   mutation (treating "already exists" errors as success)
4. Installs the enterprise app on the new organization via the REST API

This approach bypasses the provider entirely for the problematic operation
while keeping organization lifecycle visible in Terraform state.

### Option 5: Bootstrap org + native provider (current)

Create the first organization manually via the GitHub UI, install the
enterprise app on it, then import it into Terraform state. Subsequent
organizations are created by the native `github_enterprise_organization`
resource. The enterprise-apply workflow installs the app on each new org
immediately after `terraform apply`.

The key hypothesis: once the enterprise app is installed on an org, the
provider's `Read` function (which calls `GET /orgs/{org}` via REST) should
succeed because the app has an active org-level installation. If this holds,
the only gap is the brief window between org creation (GraphQL) and app
installation (workflow step). For the bootstrap org this is handled by manual
installation; for subsequent orgs, the workflow covers it.

If the hypothesis fails (the enterprise installation token still cannot call
org-level REST endpoints even with a per-org installation), fall back to
Option 3.

### Option 4: Wait for upstream fix

Three open issues track this problem:

* [#3109](https://github.com/integrations/terraform-provider-github/issues/3109)
  "Resource does not support GitHub App authentication" (Open/Triage)
* [#2886](https://github.com/integrations/terraform-provider-github/issues/2886)
  "Allow usage of enterprise app installation" (Open/Backlog)
* [#2631](https://github.com/integrations/terraform-provider-github/issues/2631)
  "Error 403 SAML Enforcement when creating org with PAT in EMU" (Open/Triage)

A collaborator on issue #2886 noted that a proper fix requires significant
refactoring: removing the `owner` requirement from provider configuration,
restructuring the GitHub client to support enterprise installations, and
realigning all enterprise resources. No pull request or timeline exists. Waiting
is not viable for our delivery schedule.

## More Information

* Provider source:
  [`resource_github_enterprise_organization.go`](https://github.com/integrations/terraform-provider-github/blob/main/github/resource_github_enterprise_organization.go)
* Enterprise tier configuration: [enterprise/main.tf](../../enterprise/main.tf)
* REST API for org app installation:
  `POST /enterprises/{enterprise}/apps/organizations/{org}/installations`
* Option 3 provisioner script was removed when superseded by Option 5
  (commit history retains it for reference)
