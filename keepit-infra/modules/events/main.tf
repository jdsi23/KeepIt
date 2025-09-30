# Role that EventBridge Scheduler will assume when firing targets
resource "aws_iam_role" "scheduler_target_role" {
  name = "${var.name_prefix}-scheduler-target-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect="Allow",
      Principal={ Service="scheduler.amazonaws.com" },
      Action="sts:AssumeRole"
    }]
  })
}

# Allow publish to the push topic; allow lambda invoke (future reminder lambda)
resource "aws_iam_role_policy" "scheduler_target" {
  name = "${var.name_prefix}-scheduler-target-policy"
  role = aws_iam_role.scheduler_target_role.id
  policy = jsonencode({
    Version="2012-10-17",
    Statement=[
      {
        Sid="PublishPush",
        Effect="Allow",
        Action=["sns:Publish"],
        Resource=var.sns_topic_arn
      },
      {
        Sid="InvokeLambda",
        Effect="Allow",
        Action=["lambda:InvokeFunction"],
        Resource="*"
      }
    ]
  })
}

output "scheduler_role_arn" { value = aws_iam_role.scheduler_target_role.arn }
