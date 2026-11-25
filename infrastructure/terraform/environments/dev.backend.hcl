bucket         = "pesa-terraform-state-ACCOUNT_ID"
key            = "dev/terraform.tfstate"
region         = "af-south-1"
dynamodb_table = "pesa-terraform-locks"
encrypt        = true
