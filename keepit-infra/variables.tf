variable "project" { type = string  default = "keepit" }
variable "owner"   { type = string  default = "james" }
variable "region"  { type = string  default = "us-east-1" }

# Will be provided by workspace or tfvars
variable "env"     { type = string }

# Optional: existing KMS key to use (else AWS managed)
variable "kms_key_arn" { type = string  default = "" }