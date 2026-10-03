                         DEVELOPER
                             │
                             ▼
                          GitHub
                             │
                             ▼
                    GitHub Actions CI
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
           Maven          SonarQube        Trivy
              │              │              │
              └──────────────┼──────────────┘
                             ▼
                            ECR
                             │
                             ▼
                          Argo CD
                             │
                             ▼
                    ┌─────────────────┐
                    │       EKS       │
                    │                 │
                    │ Backend apps    │
                    │ Platform tools  │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
         CloudWatch       Prometheus      Datadog
              │              │              │
              └──────────────┼──────────────┘
                             │
                             ▼
                 ┌──────────────────────┐
                 │   AI DevOps Agent    │
                 │                      │
                 │ Amazon Bedrock       │
                 │ + AgentCore          │
                 └──────────┬───────────┘
                            │
                       MCP Gateway
                            │
          ┌─────────────────┼─────────────────┐
          ▼                 ▼                 ▼
       GitHub              AWS               EKS
       MCP/tools           tools             MCP
          │                 │                 │
          └─────────────────┼─────────────────┘
                            ▼
                     RCA / Investigation
                            │
                            ▼
                    Recommendation
                            │
                     Human Approval
                            │
                            ▼
                       Remediation


