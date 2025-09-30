locals {
  name_prefix = "${var.project}-${var.env}"
  use_kms     = var.kms_key_arn != ""
}

module "data" {
  source      = "./modules/data"
  name_prefix = local.name_prefix
  region      = var.region
  kms_key_arn = var.kms_key_arn
}

module "push" {
  source      = "./modules/push"
  name_prefix = local.name_prefix
}

module "events" {
  source      = "./modules/events"
  name_prefix = local.name_prefix
  # Allow Scheduler to publish to your SNS push topic & invoke lambdas (future)
  sns_topic_arn = module.push.user_push_topic_arn
}

module "api" {
  source      = "./modules/api"
  name_prefix = local.name_prefix
  region      = var.region
  kms_key_arn = var.kms_key_arn
}

module "observability" {
  source      = "./modules/observability"
  name_prefix = local.name_prefix
  api_lambda_arn = module.api.lambda_arn
  dynamo_table_names = [
    module.data.items_table_name,
    module.data.reminders_table_name
  ]
}
