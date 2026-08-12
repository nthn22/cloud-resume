A serverless resume website built on AWS, fully defined as Infrastructure as Code and deployed through an automated CI/CD pipeline — my take on the Cloud Resume Challenge.

Live site: [d23rtileptlnbs.cloudfront.net]

Overview

This project started as a simple HTML resume and ended up being a full walk through the cloud/DevOps stack: static site hosting, a serverless backend, Infrastructure as Code, and a fully automated deployment pipeline with zero long-lived credentials. Every piece was built by hand in the AWS console first, then rebuilt from scratch as Terraform — so the code reflects an actual understanding of what each resource does, not a copy-pasted template.

Architecture
Browser
  │
  ▼
CloudFront (HTTPS, OAC)
  │
  ▼
S3 (private bucket — index.html, styles.css, counter.js)

counter.js
  │
  ▼
API Gateway (HTTP API, CORS enabled)
  │
  ▼
Lambda (Python) ──► DynamoDB (visitor count)
Frontend: static HTML/CSS/JS, served from a private S3 bucket through CloudFront
Security: the S3 bucket is fully private — Origin Access Control (OAC) ensures it can only be read by this specific CloudFront distribution, never accessed directly
Backend: a Python Lambda function increments a visitor count in DynamoDB on each page load, exposed via an HTTP API in API Gateway
Infrastructure as Code: every resource above — S3, CloudFront, OAC, DynamoDB, IAM, Lambda, API Gateway — is defined in Terraform and reproducible from a blank AWS account
CI/CD: GitHub Actions runs the Python test suite on every push; if tests pass, it authenticates to AWS via OIDC (no stored access keys) and deploys the Lambda code and frontend files automatically
Tech Stack
Layer	Tools
Frontend	HTML, CSS, JavaScript
Hosting / CDN	Amazon S3, Amazon CloudFront, Origin Access Control
Backend	AWS Lambda (Python), Amazon API Gateway (HTTP API), Amazon DynamoDB
IaC	Terraform
CI/CD	GitHub Actions, AWS OIDC federation
Testing	pytest, moto (mocked AWS for unit tests)
Repo Structure
.
├── frontend/          # index.html, styles.css, counter.js
├── backend/           # lambda_function.py, test_lambda_function.py
├── infra/             # Terraform: all AWS resources as code
└── .github/
    └── workflows/     # CI/CD pipeline definition
    
What This Project Demonstrates
Building the same infrastructure twice — once by hand in the console, once as Terraform — to actually understand what each resource does rather than templating blind
Debugging real issues end to end: a DynamoDB Decimal JSON-serialization bug caught via CloudWatch logs, and a subtle IAM OIDC trust-policy mismatch diagnosed by reading raw claims in AWS CloudTrail
Least-privilege IAM: the Lambda's execution role grants only dynamodb:UpdateItem on the one table it needs, nothing broader
A CI/CD pipeline secured with OIDC federation instead of long-lived AWS access keys stored as secrets
Automated testing with mocked AWS services (no real AWS calls, no cost, fully reproducible)

Running It Yourself
bash
cd infra
terraform init
terraform plan
terraform apply

Requires an AWS account, the AWS CLI configured, and Terraform installed. The frontend/ files are uploaded as part of the Terraform apply; from there, GitHub Actions handles ongoing deployments on every push to main.

Write-up

A full write-up of the build process, including the debugging journey, is available [here — link to blog post once written].
