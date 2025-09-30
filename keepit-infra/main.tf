locals {
  name_prefix = "${var.project}-${var.env}"
}

module "data" {
  source      = "./modules/data"
  name_prefix = local.name_prefix
  region      = var.region
}

module "push" {
  source      = "./modules/push"
  name_prefix = local.name_prefix
}

module "events" {
  source        = "./modules/events"
  name_prefix   = local.name_prefix
  sns_topic_arn = module.push.user_push_topic_arn
}

module "api" {
  source      = "./modules/api"
  name_prefix = local.name_prefix
  region      = var.region
}

module "observability" {
  source             = "./modules/observability"
  name_prefix        = local.name_prefix
  api_lambda_arn     = module.api.lambda_arn
  dynamo_table_names = [
    module.data.items_table_name,
    module.data.reminders_table_name
  ]
}
