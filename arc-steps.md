Complete lifecycle of one CI job
1. GitHub Actions queues a job. The runs-on value matches a registered ARC runner scale set.
2. ARC Listener receives the job. It updates the desired number of ephemeral runners.
3. ARC creates a runner Pod. The Pod inherits your configured resource requests, limits, node selector, and tolerations.
4. Kubernetes attempts scheduling. If no existing node can accommodate the Pod, it remains Pending.
5. Karpenter provisions a Spot node. It selects an instance type that satisfies the Pod's resource and scheduling requirements.
6. The runner executes the job. It registers with GitHub and receives the job instructions.
7. The runner exits after the job. ARC removes the ephemeral runner Pod and its associated resources.
8. Karpenter consolidates capacity. When the node is no longer needed, it may terminate it according to NodePool disruption policies.