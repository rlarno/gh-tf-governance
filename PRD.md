# Github repository to manage the governance of GHEC instance.

The repo will exist as a public (template) repository in a public GitHub organization, but the actual infrastructure will be deployed in a private repository within the enterprise account. This allows us to keep the code open and reusable while maintaining security and control over the actual deployment.

? is it best to fork the repo or to make the original a template repo and then create a new repo from the template?
> We will make the original a template repo and then create a new repo from the template for the actual deployment. This way we can keep the history clean and avoid confusion with forks.

Workflow:

1. The IT team will set up the GHEC instance using EMU and configure the SSO (Entra ID) and SCIM provisioning.
2. The IT team will create a GH Enterprise-level GitHub App with the necessary permissions to manage the GHEC instance and generate the private key for authentication.
3. The IT team will create a new organization in the GHEC instance to host the repository for managing the governance code.
4. The IT team will install the GitHub App on the enterprise account and the newly created organization. (required for the Terraform provider to work with app authentication, see ADR 0001)
5. The IT team will create a new repository from the template in the enterprise account and configure the Terraform code with the appropriate variables (e.g., GitHub App credentials, organization names).

6. The IT team will use this repository to create and manage the Organizations and delegate Organization Admin permissions to the appropriate teams.
7. The IT team will create and link the Admin Teams and the other teams to the Idp groups.
8. The IT team will link the Admin Teams to the appropriate Organizations with Organization Admin permissions.
9. The IT team will use the repository to manage the lifecycle of the organizations and teams, ensuring that the governance model is maintained and that the appropriate permissions are in place.

10. The Organisation Admins will use their permissions to manage the repositories and teams within their respective organizations, following the governance policies defined by the IT team.

# References

https://docs.github.com/en/enterprise-cloud@latest/apps/using-github-apps/installing-a-github-app-on-your-enterprise


cd r:\gh-tf-governance\gh-tf-governance\enterprise

* Load the private key into the env var

  $env:TF_VAR_github_app_pem_file = Get-Content -Raw "R:\gh-tf-governance\ghec-governance-ent.2026-03-10.private-key.pem"

terraform init
terraform plan
terraform apply