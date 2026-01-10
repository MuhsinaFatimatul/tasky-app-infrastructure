# Tasky App Deployment Guide

This guide explains how to deploy the Tasky App infrastructure and application to AWS.

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured with credentials
- Terraform >= 1.5.0
- kubectl CLI
- Helm 3
- Docker (for building images)

## Architecture Overview

The deployment includes:
- **EKS Cluster**: Kubernetes cluster for running the application
- **VPC**: Virtual Private Cloud with public and private subnets
- **ECR**: Container registry for Docker images
- **EC2 + MongoDB**: MongoDB database server on EC2
- **S3**: Backup storage for MongoDB
- **CloudWatch**: Logging and monitoring

## Deployment Steps

### 1. Infrastructure Deployment

The infrastructure is deployed using Terraform and GitHub Actions.

#### Manual Deployment

```bash
cd wiz

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

#### Automated Deployment via GitHub Actions

1. Configure the following GitHub Secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_REGION`

2. Push to the `main` branch:
   ```bash
   git push origin main
   ```

3. The GitHub Actions workflow will automatically:
   - Validate Terraform configuration
   - Run security scans (Checkov)
   - Deploy infrastructure to AWS

### 2. Build and Push Docker Image

After infrastructure is deployed, build and push the application image:

```bash
# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=us-east-1

# Login to ECR
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Build the Docker image
cd app
docker build -t tasky-app .

# Tag the image
docker tag tasky-app:latest ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/demo-ecr:latest

# Push to ECR
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/demo-ecr:latest
```

### 3. Configure kubectl for EKS

```bash
aws eks update-kubeconfig --region us-east-1 --name demo-eks
```

### 4. Deploy Application to Kubernetes

#### Option A: Using Kubernetes Manifests

```bash
# Update the secret with MongoDB connection string
# Get MongoDB EC2 public IP from Terraform output
MONGODB_IP=$(cd wiz && terraform output -raw mongodb_public_ip)

# Update k8s/secret.yaml with the MongoDB connection
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

#### Option B: Using Helm

```bash
# Get MongoDB IP
MONGODB_IP=$(cd wiz && terraform output -raw mongodb_public_ip)

# Install/upgrade the application
helm upgrade --install tasky-release ./helm/tasky \
  --set config.mongodbUri="mongodb://${MONGODB_IP}:27017/tasky" \
  --set image.repository="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/demo-ecr" \
  --namespace production --create-namespace
```

### 5. Verify Deployment

```bash
# Check pods
kubectl get pods -n production

# Check services
kubectl get svc -n production

# Get the LoadBalancer URL
kubectl get svc tasky-release-tasky -n production -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### 6. Test the Application

```bash
# Get the service endpoint
ENDPOINT=$(kubectl get svc tasky-release-tasky -n production -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Health check
curl http://${ENDPOINT}/health

# Create a task
curl -X POST http://${ENDPOINT}/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Task","description":"Testing deployment","priority":"high"}'

# Get all tasks
curl http://${ENDPOINT}/api/tasks
```

## Terraform Outputs

Important outputs from the Terraform deployment:

```bash
cd wiz
terraform output
```

Key outputs:
- `cluster_name`: EKS cluster name
- `cluster_endpoint`: EKS cluster endpoint
- `ecr_repository_url`: ECR repository URL
- `mongodb_public_ip`: MongoDB server public IP
- `s3_backup_bucket`: S3 bucket for MongoDB backups

## Monitoring and Logs

### Application Logs

```bash
# View application logs
kubectl logs -f -l app.kubernetes.io/name=tasky -n production
```

### MongoDB Logs

```bash
# SSH to MongoDB instance (get private key from Terraform state)
ssh -i mongodb-key.pem ubuntu@<MONGODB_IP>
sudo journalctl -u mongod -f
```

### CloudWatch Logs

View EKS cluster logs in AWS CloudWatch:
- Log group: `/aws/eks/demo-eks`

## Backup and Recovery

MongoDB backups are automatically configured to run every 2 hours via cron job on the EC2 instance. Backups are stored in the S3 bucket.

### Manual Backup

```bash
# SSH to MongoDB instance
ssh -i mongodb-key.pem ubuntu@<MONGODB_IP>

# Run backup script
sudo /home/ubuntu/backup_mongodb.sh
```

### Restore from Backup

```bash
# Download backup from S3
aws s3 cp s3://<backup-bucket>/backups/<backup-file>.tar.gz .

# Extract
tar -xzf <backup-file>.tar.gz

# Restore
mongorestore --dir=./mongodb_backup_<timestamp>
```

## Cleanup

To destroy all resources:

```bash
# Delete Kubernetes resources
helm uninstall tasky-release -n production
kubectl delete namespace production

# Destroy Terraform infrastructure
cd wiz
terraform destroy
```

## Troubleshooting

### Pods not starting

```bash
kubectl describe pod <pod-name> -n production
kubectl logs <pod-name> -n production
```

### Cannot connect to MongoDB

1. Check security group rules
2. Verify MongoDB is running: `systemctl status mongod`
3. Check MongoDB logs: `sudo journalctl -u mongod -f`

### ECR authentication issues

```bash
# Re-authenticate
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
```

## Security Considerations

- The MongoDB instance is configured with open security groups for demonstration purposes
- For production use:
  - Restrict MongoDB access to VPC CIDR only
  - Use AWS Secrets Manager for sensitive credentials
  - Enable encryption at rest and in transit
  - Implement network policies in Kubernetes
  - Use private EKS endpoint only
  - Enable pod security policies

## Next Steps

- Configure custom domain with Route53
- Set up SSL/TLS certificates
- Configure horizontal pod autoscaling
- Implement CI/CD pipeline for automatic deployments
- Add monitoring with Prometheus/Grafana
- Configure backup retention policies
