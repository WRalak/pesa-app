bucket         = "pesa-terraform-state-ACCOUNT_ID"
key            = "prod/terraform.tfstate"
region         = "af-south-1"
dynamodb_table = "pesa-terraform-locks"
encrypt        = true
