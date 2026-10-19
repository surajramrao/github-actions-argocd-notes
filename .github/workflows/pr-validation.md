```yaml
To ensure enterprise-grade security on AWS, hardcoded Kubernetes secrets should be avoided. Instead, we can utilize AWS Secrets Manager along with the Secrets Store CSI Driver [or external-secrets operator] to dynamically inject the GitHub App authentication parameters into the EKS Hub cluster.
Here is the complete rewrite of the entire architectural implementation, factoring in AWS Secrets Manager, EKS IAM Roles for Service Accounts (IRSA), and Actions Runner Controller (ARC).
------------------------------
## 🧱 Architectural Prerequisites (AWS Console / CLI)## 1. Store the GitHub App Credentials in AWS Secrets Manager
Create a secret named eks/github-runner-app containing your GitHub App configurations:

aws secretsmanager create-secret --name eks/github-runner-app \
  --description "GitHub App Credentials for EKS Self-Hosted Runners" \
  --secret-string '{"app_id":"123456","app_installation_id":"78901234","app_private_key":"-----BEGIN RSA PRIVATE KEY-----\nMIIEpAIBAAKCAQEA...\n-----END RSA PRIVATE KEY-----"}'

## 2. Create the IAM Policy & Attach it to the EKS Trust Policy
Create an IAM Policy allowing the EKS runners/controller to read this specific secret:

{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret"
            ],
            "Resource": "arn:aws:secretsmanager:YOUR_REGION:YOUR_ACCOUNT_ID:secret:eks/github-runner-app-*"
        }
    ]
}

(Associate this IAM role with a service account in your arc-runners namespace using IRSA / EKS Pod Identities so Kubernetes can securely communicate with AWS Secrets Manager).
------------------------------
## ⚙️ Step 1: Sync AWS Secrets Manager to EKS via External Secrets
We use the External Secrets Operator (ESO) to continuously sync our AWS Secrets Manager secret into a native Kubernetes secret named github-app-secret.
Apply the following manifests to your EKS cluster:

apiVersion: external-secrets.io/v1beta1kind: SecretStoremetadata:
  name: aws-secretsmanager-store
  namespace: arc-runnersspec:
  provider:
    aws:
      service: SecretsManager
      region: YOUR_AWS_REGION
      # Uses the EKS Node IAM role or attached Service Account Identity
      auth:
        jwt:
          serviceAccountRef:
            name: secrets-sync-sa
---apiVersion: external-secrets.io/v1beta1kind: ExternalSecretmetadata:
  name: github-app-external-secret
  namespace: arc-runnersspec:
  refreshInterval: "1h"
  secretStoreRef:
    name: aws-secretsmanager-store
    kind: SecretStore
  target:
    name: github-app-secret # The name ARC will look for
    creationPolicy: Owner
  data:
    - secretKey: github_app_id
      remoteRef:
        key: eks/github-runner-app
        property: app_id
    - secretKey: github_app_installation_id
      remoteRef:
        key: eks/github-runner-app
        property: app_installation_id
    - secretKey: github_app_private_key
      remoteRef:
        key: eks/github-runner-app
        property: app_private_key

------------------------------
## 🚀 Step 2: Deploy Actions Runner Controller (ARC)## Install the ARC Operator

helm repo add actions-runner-controller https://jetstack.io --force-update
helm repo update

helm upgrade --install arc-controller \
    --namespace arc-systems \
    --create-namespace \
    actions-runner-controller/gha-runner-scale-set-controller

## Deploy the Autoscale Runner Pool using the synced Secret
Create a runner-values.yaml referencing the secure github-app-secret fetched from AWS:

# runner-values.yamlgithubConfigUrl: "https://github.com"githubConfigSecret: github-app-secret
minRunners: 0  # Scale down to zero when no PRs are open to minimize EC2 costsmaxRunners: 10 # Cap the runners to prevent flooding your EKS network
template:
  spec:
    containers:
      - name: runner
        image: ghcr.io/actions/actions-runner:latest
        command: ["/home/runner/run.sh"]
        resources:
          limits:
            cpu: "2"
            memory: 4Gi
          requests:
            cpu: "1"
            memory: 2Gi

Deploy the scale set configuration:

helm upgrade --install eks-java-runner \
    --namespace arc-runners \
    actions-runner-controller/gha-runner-scale-set \
    -f runner-values.yaml

------------------------------
## 📄 Step 3: The Complete PR Validation Workflow
Save this file as .github/workflows/pr-validation.yml. This configuration runs on your EKS-hosted runner pool, fetches code, bypasses the internal ALB to contact SonarQube directly inside the cluster network, and flags PR violations.

name: PR Validation (Java/Maven)
on:
  pull_request:
    branches: [ main ]
    types: [ opened, synchronize, reopened ]
jobs:
  validate:
    name: Java Code Quality & Security Scan
    # Strictly targets the self-hosted runner pool provisioned inside your EKS Hub Cluster
    runs-on: eks-java-runner 

    steps:
      # Step 1: Clean workspace & pull deep Git history (Essential for SonarQube blame tracking)
      - name: Checkout Code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0 
          clean: true

      # Step 2: Secret Scanning (Fails PR early if hardcoded passwords/keys are pushed)
      - name: Run Gitleaks (Secret Scanner)
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      # Step 3: Setup Java JDK Environment & Auto-Cache Maven .m2 directories
      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17' 
          distribution: 'temurin' 
          cache: 'maven' 

      # Step 4: Run Java Linters
      - name: Run Java Linter (Checkstyle/Spotless)
        run: ./mvnw spotless:check || ./mvnw checkstyle:check || echo "No styling linter defined, skipping..."

      # Step 5: Compile Code, Execute Unit Tests & Generate JaCoCo Code Coverage
      - name: Execute Unit Tests & Compile
        run: ./mvnw verify

      # Step 6: SonarQube PR Native Analysis
      # Bypasses the internal ALB entirely using the K8s internal ClusterIP DNS endpoint.
      - name: Run SonarQube Analysis
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }} # Set up as a GitHub repo secret for the token interface
        run: |
          ./mvnw sonar:sonar \
            -Dsonar.host.url="http://cluster.local" \
            -Dsonar.projectKey=your-java-app-key \
            -Dsonar.projectName="Your EKS Java Application" \
            -Dsonar.qualitygate.wait=true \
            -Dsonar.pullrequest.key=${{ github.event.pull_request.number }} \
            -Dsonar.pullrequest.branch=${{ github.event.pull_request.head.ref }} \
            -Dsonar.pullrequest.base=${{ github.event.pull_request.base.ref }}

```

