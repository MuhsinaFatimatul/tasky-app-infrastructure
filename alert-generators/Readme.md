# Alert Generators

## Get AWS Credentials

# Populate ~/.kube/config so kubectl targets the EKS cluster
aws eks update-kubeconfig --region <AWS_REGION> --name <EKS_CLUSTER_NAME>
```

## Login to ECR

# Get AWS account ID (used to form registry hostname)
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=<AWS_REGION>

# Authenticate Helm to ECR (Helm OCI support + ECR)
aws ecr get-login-password --region "${AWS_REGION}" \
  | helm registry login "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com" --username AWS --password-stdin

## Pull the Helm Chart from ACR

# If you pushed an OCI chart to ECR under repository "helm/tasky":
# If you pushed an OCI chart to ECR under repository "helm/tasky":
helm pull oci://"${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/helm/tasky" --version 0.2.0


## Install the Helm Chart

helm install tasky-release oci://"${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/helm/tasky" \
  --version 0.2.0 -f values.yml 


## (If you use public OCI registries or another chart repo, replace the registry URL accordingly.)

## Enabling EKS audit logging (so the audit events are available in CloudWatch)

eksctl utils update-cluster-logging \
  --cluster <EKS_CLUSTER_NAME> \
  --region <AWS_REGION> \
  --enable-types audit \
  --approve

### Detect Cluster Admin Bindings

aws eks update-cluster-config \
  --region <AWS_REGION> \
  --name <EKS_CLUSTER_NAME> \
  --logging '{"clusterLogging":[{"types":["audit"],"enabled":true}]}'

### Privileged Pod creation Policy Denied logs

#After enabling, control plane audit logs are delivered to CloudWatch under log groups for the cluster (e.g. /aws/eks/<cluster-name>/cluster or similar). Pod-level auditing may require configuring the cluster and log collector (fluentd, container insights) depending on your setup.
CloudWatch Logs Insights queries (approximate equivalents to your Kusto queries)

Note: pick the correct Log Group for your EKS audit logs (for control plane logs or your FluentD-delivered audit logs). Replace /aws/eks/<LOG-GROUP> below with the actual log group name in the CloudWatch Logs console.
Search for pod creation (matching a pod name)


# Run in CloudWatch Logs Insights against the EKS audit log group
fields @timestamp, @message
| filter @message like /"verb"\s*:\s*"create"/
  and @message like /tasky-release-tasky-f8947f85b-lxzb4/
  and @message like /"kind"\s*:\s*"Pod"/
| sort @timestamp desc
| limit 50


## Detect cluster-admin rolebindings being created/updated

fields @timestamp, @message
| filter (@message like /"verb"\s*:\s*"create"/ or @message like /"verb"\s*:\s*"update"/)
  and @message like /clusterrolebindings/i
  and @message like /cluster-admin/i
  and @message like /"responseStatus"/ and @message like /201/
| sort @timestamp desc
| limit 100

## Privileged Pod creation / admission denials (Gatekeeper / OPA / admission controller)

fields @timestamp, @message
| filter (@message like /gatekeeper/i or @message like /opa/i or @message like /admission/i)
  and @message like /denied/i
| sort @timestamp desc
| limit 200

## Simple recent kube-audit entries (top 5)

fields @timestamp, @message
| filter @message like /"audit.k8s.io"/ or @logStream like /kube-audit/ or @message like /"verb":/
| sort @timestamp desc
| limit 5

## Find create/update events where a Pod's container had privileged=true

fields @timestamp, @message
| filter (@message like /"verb"\s*:\s*"create"/ or @message like /"verb"\s*:\s*"update"/)
  and @message like /"objectRef".*"pods"/
  and @message like /"privileged"\s*:\s*true/
| sort @timestamp desc
| limit 100


## Search for a creation event for a specific pod name (nginx-privileged)
fields @timestamp, @message
| filter @message like /"verb"\s*:\s*"create"/ and @message like /nginx-privileged/
| sort @timestamp desc
| limit 100


