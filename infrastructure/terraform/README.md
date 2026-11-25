# Terraform — AWS (af-south-1)

One stack per environment (`dev`, `staging`, `prod`) with remote state.

```bash
terraform init -backend-config=environments/staging.backend.hcl
terraform plan  -var-file=environments/staging.tfvars -var image_tag=$GIT_SHA
terraform apply -var-file=environments/staging.tfvars -var image_tag=$GIT_SHA
```

What it creates: VPC (public / private / isolated subnets, NAT, flow logs), KMS key,
ElastiCache Redis (TLS + AUTH), private KMS-encrypted S3 bucket, Secrets Manager
secrets, ECR repositories (immutable tags, scan on push), ECS Fargate services
(`api`, `worker`, `admin`) with read-only root filesystems and dropped capabilities,
a public ALB + WAF for the API (admin paths blocked at the edge), an **internal**
ALB for the admin console, autoscaling and CloudWatch alarms.

MongoDB is **MongoDB Atlas** (dedicated M30+ in `af-south-1`, AWS PrivateLink,
encryption at rest with customer KMS, continuous backup with point-in-time
restore). It is provisioned by the platform team; its connection string is stored in
Secrets Manager and passed as `mongodb_uri_secret_arn`. Amazon DocumentDB is not
used because the app relies on aggregation operators (`$dateAdd`, `$stdDevPop`)
and multi-document transaction semantics that DocumentDB does not fully match.

Secret *values* are never in Terraform; set them with
`aws secretsmanager put-secret-value` (see `docs/DEPLOYMENT.md`).
