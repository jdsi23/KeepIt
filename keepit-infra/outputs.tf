output "health_url"        { value = module.api.health_url }
output "items_table"       { value = module.data.items_table_name }
output "reminders_table"   { value = module.data.reminders_table_name }
output "media_bucket"      { value = module.data.media_bucket }
output "push_topic_arn"    { value = module.push.user_push_topic_arn }
output "scheduler_role_arn"{ value = module.events.scheduler_role_arn }
