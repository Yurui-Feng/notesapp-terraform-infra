# NotesApp Infrastructure

This repository contains Terraform configurations for deploying the infrastructure required by NotesApp, a simple note-taking application. The setup includes configurations for both the backend and frontend components, each hosted on AWS ECS with Fargate, behind Application Load Balancers (ALBs) with HTTPS enabled.

## Directory Structure

```
/notesapp-infrastructure
    ├── backend
    │   ├── backend-service.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── terraform.tfvars
    ├── frontend
    │   ├── frontend-service.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── terraform.tfvars
    └── main.tf
```

- **Backend**: Contains Terraform configurations for the backend service, including ECS task definitions, service, and ALB.
- **Frontend**: Contains Terraform configurations for the frontend service, similar to the backend but tailored for the frontend's specific needs.
- **Shared**: (If applicable) Contains configurations for shared resources like VPCs, subnets, and security groups.

## Prerequisites

- AWS Account
- Terraform installed (v1.0.0 or higher recommended)
- AWS CLI configured

## Setup Instructions

1. **Initialize Terraform**:

Navigate to each environment directory (`backend` or `frontend`) and initialize Terraform:

```sh
cd backend
terraform init
```

Repeat for the `frontend` directory.

2. **Plan Terraform Changes**:

Review the changes Terraform will perform:

```sh
terraform plan
```

3. **Apply Terraform Changes**:

Apply the changes to create the infrastructure:

```sh
terraform apply
```

Repeat the `plan` and `apply` steps in the `frontend` directory.

## Security

Sensitive data like AWS credentials or other secrets should not be stored in `terraform.tfvars` files or within the repository. Use environment variables or a secure secret management service.

## License

This project is licensed under the MIT License - see the `LICENSE.md` file for details.