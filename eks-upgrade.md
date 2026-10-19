```shell
Bro, honestly, yes, these are real DevOps upgrade activities, but the earlier answer made them sound more rigid and automatic than they really are. In an enterprise, the exact process depends on how EKS is managed, whether you use managed node groups or Karpenter, and how your team handles infrastructure changes.

Let me rewrite it the way you can understand it, explain it in an interview, and connect it to your Terraform + GitHub Actions + Argo CD + Datadog setup.

# 1. First, understand what you are upgrading

An EKS cluster upgrade is not just changing one version. There are three main layers.

1\. Control plane — AWS manages it

This is the Kubernetes API server and other control-plane components. You request a version upgrade; AWS performs the control-plane update.

2\. Worker nodes — your compute layer

These are EC2 instances running your application pods. You must ensure they run a compatible Kubernetes version and operating-system image.

3\. Add-ons and controllers

Examples: VPC CNI, CoreDNS, kube-proxy, AWS Load Balancer Controller and EBS CSI driver. Their compatibility must be checked, and upgrades performed where needed.

## 2. How a real DevOps engineer performs the upgrade

Suppose your EKS cluster is running Kubernetes `1.30` and you want to upgrade to `1.31`. These are example versions, not a recommendation to use them today.

The exact sequence must follow AWS's requirements for the current and target versions, including node version-skew rules.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.aws.amazon.com\&sz=32)

Amazon EKS

+1



### Step 1 — Check whether the cluster is ready

Before changing Terraform, I check:

- Current control-plane and worker-node versions.
- EKS Upgrade Insights for deprecated APIs and upgrade blockers.
- Compatibility of Helm charts, Argo CD, controllers and add-ons.
- Whether applications have enough replicas and healthy PodDisruptionBudgets.
- Whether enough EC2 capacity and subnet IP addresses are available.

For example:

```shell
aws eks describe-cluster \
  --name my-cluster \
  --query 'cluster.version'

kubectl get nodes
kubectl get pods -A
kubectl get pdb -A
```

Why? I need to identify potential problems before changing the production cluster. AWS recommends checking upgrade readiness and resolving relevant issues first.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.aws.amazon.com\&sz=32)

Amazon EKS

+1



### Step 2 — Upgrade the control plane using Terraform

I update the version in our Terraform configuration.

```
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "YOUR_VALIDATED_MODULE_VERSION"

  cluster_name    = "my-cluster"
  cluster_version = "1.31"

  # Other configuration remains here
}
```

Then I follow our GitHub Actions infrastructure pipeline:

1. Create a pull request.
2. Review the Terraform plan.
3. Obtain the required approval.
4. Run Terraform apply.
5. Verify the EKS control-plane upgrade.

AWS manages the control-plane infrastructure itself. Terraform is the tool we use to request and manage the version change.

Important: I don't blindly run `terraform apply -target` for every upgrade. I use the normal reviewed Terraform plan unless a specific staged operation is justified.

### Step 3 — Upgrade worker nodes

Now I deal with the EC2 instances that run the application pods.

If we use EKS Managed Node Groups, I check the node group's version, AMI and launch-template configuration. I then apply the required changes through Terraform.

EKS performs the managed node-group update according to its rollout settings. The process can drain old nodes and replace them, but the exact behavior depends on the update strategy and configuration.

Before doing this, I ensure:

- Sufficient capacity for replacement nodes.
- Healthy application replicas and suitable PDBs.
- Readiness probes and traffic handling work correctly.

I monitor the rollout:

```
kubectl get nodes -w
kubectl get pods -A -o wide
```

If we use Karpenter instead, I follow the configured node replacement and drift-management process. I do not assume Karpenter will replace every node immediately just because I changed a Terraform variable.

AWS explains the different responsibilities for managed node groups and Karpenter in its [EKS upgrade best practices](https://aws.github.io/aws-eks-best-practices/upgrades/?utm_source=chatgpt.com).&#x20;

[image](https://www.google.com/s2/favicons?domain=https://aws.github.io\&sz=32)

Amazon EKS

+1



### Step 4 — Upgrade add-ons and controllers

I check compatible versions for:

- VPC CNI — pod networking.
- CoreDNS — cluster DNS.
- kube-proxy — Kubernetes service networking.
- AWS Load Balancer Controller — ingress and load-balancer integration.
- EBS CSI driver — persistent storage integration.
- Cluster Autoscaler or Karpenter, depending on our setup.

I update the relevant Terraform configuration or GitOps-managed component configuration, depending on how each component is managed.

I don't upgrade everything to arbitrary latest versions. I select versions compatible with the target EKS version and our existing configuration. AWS-managed add-ons do not automatically all upgrade simply because the control plane version changes.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.aws.amazon.com\&sz=32)

Amazon EKS

+1



### Step 5 — Where does Argo CD fit?

This is important for your interview.

| Tool                             | Responsibility                                                                         |
| -------------------------------- | -------------------------------------------------------------------------------------- |
| Terraform through GitHub Actions | EKS cluster version, managed node groups, infrastructure and Terraform-managed add-ons |
| Argo CD                          | Application deployments, Helm releases and Kubernetes resources stored in Git          |
| Datadog                          | Monitoring cluster health, pod restarts, latency, errors and resource utilization      |

Argo CD is not the mechanism that upgrades the EKS control plane. However, before upgrading Kubernetes, I check that our Argo CD version and deployed applications support the target Kubernetes version.

If an application Helm chart or controller needs changes, we update and test those changes through the appropriate GitOps workflow.

### Step 6 — Verify and promote

After the upgrade, I check:

```
kubectl get nodes
kubectl get pods -A
kubectl get events -A --sort-by=.lastTimestamp
```

I also run application smoke tests and examine Datadog dashboards for latency, error rates, pod restarts and infrastructure issues.

If the dev environment is healthy, I proceed to stage and then production through the approved rollout process. If production health deteriorates, I stop further rollout and follow the incident and recovery plan. I never assume that downgrading the Terraform version automatically reverses an EKS upgrade.

## 3. Final interview answer — easy to remember

In our enterprise environment, we manage EKS infrastructure using Terraform through GitHub Actions, and we use Argo CD for application deployments.

When upgrading an EKS cluster, I first check the current control-plane and worker-node versions, EKS Upgrade Insights, deprecated APIs, add-on compatibility, application health and available capacity.

Then I prepare a Terraform change for the target Kubernetes version, review the plan and execute it through our approved pipeline. AWS manages the control-plane upgrade.

Next, I upgrade the worker nodes according to our compute architecture. For managed node groups, I use the Terraform-managed node-group configuration and AWS rolling-update mechanism. If we use Karpenter, I follow its configured node replacement process.

I also validate and update compatible versions of VPC CNI, CoreDNS, kube-proxy and other cluster components.

Throughout the process, Argo CD continues managing our GitOps workloads, and Datadog helps us monitor application and infrastructure health. Finally, I run smoke tests, verify node and pod readiness, and promote the tested change from dev to stage and production.

The goal is to minimize downtime and maintain service availability through controlled changes, sufficient capacity, health checks and a tested recovery plan.

One thing to remember, bro: Real DevOps engineers do not follow a blind, fixed sequence for every EKS cluster. They follow AWS's version-specific requirements, assess their architecture, make controlled changes through their infrastructure pipeline, and verify the result before moving forward.
```