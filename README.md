# Tasky App

A cloud-native task management application deployed on AWS EKS with MongoDB backend.

## Overview

This repository contains:
- **Application**: RESTful API built with Node.js and Express
- **Infrastructure**: Terraform configuration for AWS (EKS, VPC, ECR, MongoDB)
- **Deployment**: Kubernetes manifests and Helm charts
- **CI/CD**: GitHub Actions workflows for automated deployment

## Features

- ✅ Task creation, update, and deletion
- ✅ Task prioritization (low, medium, high)
- ✅ Due date tracking
- ✅ Completion status
- ✅ RESTful API
- ✅ MongoDB backend
- ✅ Containerized deployment
- ✅ Kubernetes orchestration
- ✅ Automated backups
- ✅ Health monitoring

## Quick Start

### Prerequisites

- AWS Account
- AWS CLI configured
- Terraform >= 1.5.0
- kubectl
- Helm 3
- Docker

### Deploy Infrastructure

```bash
cd wiz
terraform init
terraform apply
```

### Deploy Application

```bash
# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name demo-eks

# Deploy using Helm
helm upgrade --install tasky-release ./helm/tasky \
  --namespace production --create-namespace
```

For detailed deployment instructions, see [DEPLOYMENT.md](DEPLOYMENT.md).

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      AWS Cloud                          │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │                 EKS Cluster                      │  │
│  │                                                  │  │
│  │  ┌─────────────┐      ┌─────────────┐          │  │
│  │  │  Tasky App  │      │  Tasky App  │          │  │
│  │  │   Pod 1     │      │   Pod 2     │          │  │
│  │  └─────────────┘      └─────────────┘          │  │
│  │                                                  │  │
│  │  ┌──────────────────────────────────────────┐  │  │
│  │  │         LoadBalancer Service             │  │  │
│  │  └──────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────┐      ┌──────────────┐               │
│  │   MongoDB    │      │     ECR      │               │
│  │   (EC2)      │      │  (Registry)  │               │
│  └──────────────┘      └──────────────┘               │
│         │                                              │
│         │ Backups                                      │
│         ▼                                              │
│  ┌──────────────┐                                      │
│  │      S3      │                                      │
│  │   (Backups)  │                                      │
│  └──────────────┘                                      │
└─────────────────────────────────────────────────────────┘
```

## Repository Structure

```
.
├── app/                    # Application source code
│   ├── server.js          # Express server
│   ├── package.json       # Node.js dependencies
│   ├── Dockerfile         # Container image definition
│   └── README.md          # Application documentation
├── wiz/                   # Terraform infrastructure
│   ├── main.tf           # EKS, VPC configuration
│   ├── vm.tf             # MongoDB EC2 instance
│   ├── iam.tf            # IAM roles and policies
│   ├── variable.tf       # Input variables
│   ├── output.tf         # Output values
│   └── scripts/          # Installation scripts
│       ├── install_mongodb.sh
│       └── backup_mongodb.sh
├── k8s/                   # Kubernetes manifests
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   └── secret.yaml
├── helm/                  # Helm charts
│   └── tasky/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── .github/workflows/     # CI/CD pipelines
│   ├── deploy.yml        # Terraform deployment
│   └── devops-workflow.yml
├── alert-generators/      # Security testing tools
└── DEPLOYMENT.md         # Deployment guide
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/api/tasks` | Get all tasks |
| GET | `/api/tasks/:id` | Get a specific task |
| POST | `/api/tasks` | Create a new task |
| PUT | `/api/tasks/:id` | Update a task |
| DELETE | `/api/tasks/:id` | Delete a task |
| GET | `/api/tasks/status/:completed` | Get tasks by status |

## Example Usage

```bash
# Create a task
curl -X POST http://<loadbalancer-url>/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Deploy to production",
    "description": "Deploy tasky-app to AWS EKS",
    "priority": "high",
    "dueDate": "2024-12-31"
  }'

# Get all tasks
curl http://<loadbalancer-url>/api/tasks

# Update a task
curl -X PUT http://<loadbalancer-url>/api/tasks/<task-id> \
  -H "Content-Type: application/json" \
  -d '{"completed": true}'

# Delete a task
curl -X DELETE http://<loadbalancer-url>/api/tasks/<task-id>
```

## CI/CD Pipeline

The repository includes automated CI/CD using GitHub Actions:

1. **On Pull Request**: 
   - Terraform format check
   - Terraform validation
   - Security scan (Checkov)
   - Terraform plan

2. **On Push to Main**:
   - All PR checks
   - Terraform apply (infrastructure deployment)

### Required GitHub Secrets

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`

## Security

- Container security scanning with Checkov
- IAM roles with least privilege
- Encrypted EBS volumes
- S3 bucket encryption
- VPC isolation
- Security groups
- Pod security contexts
- Non-root containers

See [DEPLOYMENT.md](DEPLOYMENT.md) for security best practices.

## Monitoring

- **CloudWatch Logs**: EKS cluster and application logs
- **Health Checks**: Kubernetes liveness and readiness probes
- **Metrics**: CPU and memory usage tracking

## Backup Strategy

- Automated MongoDB backups every 2 hours
- Backups stored in S3 with versioning
- 30-day retention policy

## Development

### Local Development

```bash
cd app
npm install
npm run dev
```

### Build Docker Image

```bash
cd app
docker build -t tasky-app .
docker run -p 3000:3000 -e MONGODB_URI=mongodb://localhost:27017/tasky tasky-app
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT

## Support

For issues and questions, please open a GitHub issue.

## Related Documentation

- [Deployment Guide](DEPLOYMENT.md)
- [Application README](app/README.md)
- [Alert Generators](alert-generators/Readme.md)
