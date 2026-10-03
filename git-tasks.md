Repository Settings
 ├── Collaborators / Teams
 ├── Branch Protection Rules
 ├── Webhooks
 ├── Secrets and Variables
 ├── Deploy Keys
 ├── Actions / CI settings
 ├── Environments
 ├── Rulesets
 └── Security settings

added new line

ci validation
 ├── Check for required files (e.g., README, LICENSE)
 ├── Validate configuration files (e.g., YAML, JSON)
 ├── Run linters and formatters
 └── Ensure code adheres to style guidelines

pr validation
 ├── Check for required labels (e.g., bug, enhancement)
 ├── Validate PR title and description format
 ├── Ensure PR is linked to an issue (if applicable)
 └── Run automated tests on the PR branch

main merge validation
 ├── Ensure all required checks have passed
 ├── Verify that the PR has been approved by reviewers
 ├── Check for merge conflicts
 └── Confirm that the PR is up-to-date with the base branch

#Squash merge combines all commits from a feature branch into a single commit on main.

Daily, I monitor repository webhook and CI health, investigate failed Jenkins builds, review PR checks, manage branch protection or access requests when required, troubleshoot authentication issues, validate repository integration, and coordinate with developers on build failures or deployment-related changes.

1. Monitor Jenkins builds triggered from GitHub
2. Investigate failed CI pipelines
3. Fix webhook / SCM checkout issues
4. Handle credential/token failures
5. Review PR status check failures
6. Support developers with Git branching issues
7. Validate Dockerfile / pipeline changes
8. Manage repository permissions
9. Review security scan failures
10. Check main branch health

What if two developers merge simultaneously into main?
GitHub branch protection, required checks, and up-to-date branch requirements help prevent stale PRs from being merged. Jenkins validates the resulting main branch state, and the pipeline should be designed to handle serialized or concurrent deployments appropriately.

These are the exact style interviewers ask.

Q: How did you manage GitHub access?

We managed access through organization teams and repository permissions following least privilege. Developers received write access to required repositories, while production branch protection restricted direct changes to main.

Q: How did you integrate GitHub with Jenkins?

We configured GitHub webhooks and Jenkins GitHub Branch Source integration. Push and PR events triggered the appropriate multibranch jobs, and Jenkins published build status back to GitHub.

Q: How did you secure Jenkins-GitHub integration?

We used managed credentials such as GitHub App credentials, SSH deploy keys, or PATs depending on the integration. Credentials were stored in Jenkins Credentials, not in the repository or Jenkinsfile.

Q: How did you prevent bad code from reaching main?

We enforced PR reviews, required Jenkins status checks, branch protection, and restricted direct pushes. Only PRs satisfying the required checks could be merged.

Q: How did you troubleshoot GitHub-Jenkins webhook failures?

I checked webhook delivery status in GitHub, validated the Jenkins endpoint and ingress, reviewed Jenkins webhook and SCM logs, verified job triggers and branch filters, and finally checked credentials and repository permissions.

Q: How did you handle GitHub token expiry?

I generated or provisioned a replacement token, updated the Jenkins credential securely, tested SCM checkout/API access, and revoked the old token after successful validation.

Q: How did you handle a leaked GitHub secret?

I revoked it immediately, investigated audit logs, rotated the replacement credential, checked repository history and usage, and enabled preventive controls such as secret scanning.

"Explain how GitHub is used in your daily DevOps work."

Say:

"In our project, GitHub is the central source-code management platform integrated with Jenkins. Developers follow trunk-based development and work on short-lived feature branches. Every push triggers CI validation through GitHub webhooks, where Jenkins performs checkout, build, unit testing, SonarQube analysis, security scanning, and artifact creation where applicable. Developers then raise pull requests against main. We enforce branch protection, mandatory reviews, and required Jenkins status checks. Once the PR is approved and merged, the resulting push to main triggers the main pipeline, which builds or promotes the trusted artifact and deploys it to the required environment. From the DevOps side, I manage the GitHub-Jenkins integration, credentials, webhooks, repository permissions, branch protection, CI failures, access requests, and periodic security and configuration reviews."
