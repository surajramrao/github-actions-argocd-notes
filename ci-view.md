
🛠️ The CI Repository Workflows (Application Repo)

You are 100% correct here. You have two traditional pipeline YAMLs:
• pr-ci.yml (Triggers on Pull Requests):
	• Runs lints, unit tests, and security scans.
	• Does not push images or update configs. It just validates the code.
• main-ci.yml (Triggers on Merge to Main):
	• Builds the actual production Docker image.
	• Pushes it to your registry (e.g., Docker Hub, ECR).
	• The Hand-off: The final step runs a script that clones your Config Repo, updates the image tag, and pushes/PRs that change to the Config Repo.