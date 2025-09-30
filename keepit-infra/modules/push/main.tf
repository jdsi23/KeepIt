resource "aws_sns_topic" "user_push" {
  name = "${var.name_prefix}-user-push"
}

# (Phase 4 will add SNS PlatformApplications for APNs/FCM and permissions)
