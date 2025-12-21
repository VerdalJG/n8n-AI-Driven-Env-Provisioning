# n8n AI-Driven Environment Provisioning

This repository automates the creation of development environments for your projects using **n8n**, **GitHub Actions**, **Terraform**, **Ansible**, and **Docker**. Each dev environment is provisioned with a working **PostgreSQL database**, an **EC2 instance**, and an **S3 bucket** for cleanup, ensuring developers can focus on coding without worrying about infrastructure setup.

---

## Table of Contents

- [Getting Started](#getting-started)  
- [Creating a Development Environment](#creating-a-development-environment)  
  - [Step 1: Create an Issue](#step-1-create-an-issue)  
  - [Step 2: n8n Generates Code](#step-2-n8n-generates-code)  
  - [Step 3: GitHub Workflow Provisions Environment](#step-3-github-workflow-provisions-environment)  
- [Developer Workflow](#developer-workflow)  
- [Cleanup](#cleanup)  
- [Technical Overview](#technical-overview)  

---

## Getting Started

Before using this repository, ensure you have:

- A **GitHub account** with access to this repository.
- Permissions to create issues. Pull requests work but if you have permissions, pushing is easier.
- An **SSH key pair** for connecting to your EC2 instance.

### Generating an SSH Key

If you don’t already have an SSH key, generate one locally:

```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com" -f dev_key
```

Add the public key (`~/.ssh/id_rsa.pub`) to the GitHub issue when prompted.

---

## Creating a Development Environment

### Step 1: Create an Issue

1. Navigate to the **Issues** tab in this repository.
2. Click **New Issue** using the **Dev Environment Request** template.  
3. Provide the following in the template:

```markdown
- SSH Public Key:
<insert-your-public-ssh-key-here>

- Additional Requirements:
<optional: specify anything else you need>
```

> Note: The SSH public key allows the workflow to provision an EC2 instance you can access.

### Step 2: n8n Generates Code

Once the issue is created:

- **n8n** reads the issue and generates the necessary infrastructure and configuration files using:
  - Predefined **templates**.
  - **LangChain** for any dynamic logic or content generation.

The generated files are automatically committed back to the repository.

### Step 3: GitHub Workflow Provisions Environment

When n8n commits the files:

- A **GitHub Actions workflow** is triggered.
- The workflow provisions a dev environment:
  - **PostgreSQL database** initialized and ready.
  - **EC2 instance** deployed via Terraform.
  - **S3 bucket** created for automatic cleanup.
  
The EC2 instance runs **Ansible locally** to install the bare minimum:

- Nginx
- PostgreSQL client
- Docker

This ensures a consistent, minimal dev environment ready for your application.

---

## Developer Workflow

Once the environment is ready:

1. Clone the repository and create a **dev branch** for your issue:

```bash
git checkout -b dev/issue-<ISSUE_NUMBER>
```

2. Work on your code and commit changes.
3. Push your branch to GitHub:

```bash
git push origin dev/issue-<ISSUE_NUMBER>
```

4. Open a **Pull Request** against the main branch.
5. Once pushed or PR is opened:
   - A **Docker image** for your environment is automatically built.
   - A **container** runs on your EC2 VM, reflecting your changes.

---

## PostgreSQL Access

For each development environment, a PostgreSQL database is automatically provisioned. The database credentials follow a simple naming convention based on the issue number, which ensures uniqueness per environment:

```hcl
db_username = "n8n_dev_${var.issue_number}"
db_password = "n8n_dev_pass_${var.issue_number}"
```

- `db_username`: The database username is generated using the issue number.  
- `db_password`: The database password is similarly generated using the issue number.

> **Note:** This credential generation method is intended for test and development purposes only. In a production or more secure setup, credentials should not be hardcoded or predictable. A proper implementation would send the credentials securely to the developer, for example via email or a secrets management system.  

Developers can use these credentials to connect to the PostgreSQL instance provisioned in their dev environment.

---

## Cleanup

- **Automatic:** Closing the issue triggers GitHub Actions to clean up the environment.
  - EC2 instance terminated
  - S3 bucket cleared
  - Docker containers and images removed
- **No manual steps required**—developers don’t need to worry about cleanup.

---

## Technical Overview

- **Terraform** provisions cloud resources (EC2, S3).
- **Ansible** runs on the EC2 instance to install:
  - Nginx
  - PostgreSQL client
  - Docker
- **n8n** orchestrates the process:
  - Reads issue templates
  - Generates configuration and code files
  - Commits changes to the repo
- **GitHub Actions** automates:
  - Docker build & push
  - Container deployment on EC2
  - Environment cleanup on issue closure

This workflow ensures a fully automated, reproducible dev environment for every issue request.

---


