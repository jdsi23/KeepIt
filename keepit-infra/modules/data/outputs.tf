output "items_table_name"     { value = aws_dynamodb_table.items.name }
output "reminders_table_name" { value = aws_dynamodb_table.reminders.name }
output "media_bucket"         { value = aws_s3_bucket.media.bucket }
