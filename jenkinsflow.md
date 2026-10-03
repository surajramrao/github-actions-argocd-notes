                         SOURCE REPOSITORY
                              GitHub
                                 │
                 ┌───────────────┴───────────────┐
                 │                               │
          Feature branch                     PR → dev
                 │                               │
                 ▼                               ▼
          Jenkins CI                       Jenkins PR CI
                 │                               │
                 ├─ Maven test                   ├─ Maven test
                 ├─ Trivy FS                     ├─ Trivy FS
                 ├─ SonarQube                    ├─ SonarQube
                 └─ Quality Gate                  └─ Quality Gate
                                                     │
                                                     ▼
                                                Merge to dev
                                                     │
                                                     ▼
                                             JENKINS RELEASE
                                                     │
                              ┌──────────────────────┼─────────────────────┐
                              │                      │                     │
                         Maven package          Docker build         Trivy image
                              │                      │                     │
                              └──────────────────────┼─────────────────────┘
                                                     │
                                                     ▼
                                                   ECR
                                                     │
                                                     │ image tag
                                                     ▼
                                             GitOps Repository
                                                     │
                                      update DEV image reference
                                                     │
                                                     ▼
                                                  Argo CD
                                                     │
                                                     ▼
                                                  EKS DEV
                                                     │
                                                     ▼
                                             ZAP Baseline
                                                     │
                                                    PASS
                                                     │
                                                     ▼
                                        GitOps promotion PR
                                        DEV → STAGING
                                                     │
                                                  approval
                                                     │
                                                     ▼
                                             staging values
                                                     │
                                                     ▼
                                                  Argo CD
                                                     │
                                                     ▼
                                               EKS STAGING
                                                     │
                                                     ▼
                                               ZAP Full Scan
                                                     │
                                                    PASS
                                                     │
                                                     ▼
                                         GitOps promotion PR
                                        STAGING → PRODUCTION
                                                     │
                                                  approval
                                                     │
                                                     ▼
                                                prod values
                                                     │
                                                     ▼
                                                  Argo CD
                                                     │
                                                     ▼
                                                 EKS PROD


#real flow once feature is merged in dev/main---  

SCM (checkout scm)
 ↓
Maven Clean Package
 ↓
Trivy FS
 ↓
SonarQube
 ↓
Quality Gate
 ↓
Docker Build
 ↓
Trivy Image
 ↓
Push to ECR
 ↓
Update GitOps DEV
 ↓
wait for Dev deployment
 ↓
ZAP Baseline - passive scans
 ↓
pass/fail 
 ↓
Promote to Staging
 ↓
wait for Staging deployment
 ↓
ZAP Full - active scans
 ↓
if ZAP Full PASS
 ↓
create production promotion PR
 ↓
release manager approves
 ↓
merge GitOps PR
 ↓
Argo CD
 ↓
PROD



"We build once, publish one immutable image, and promote the same image through environments. 
Jenkins  handles CI, security validation and GitOps promotion. 
Argo CD handles Kubernetes deployment. 
Environment promotion is represented as Git changes, and production requires an explicit Git approval."

