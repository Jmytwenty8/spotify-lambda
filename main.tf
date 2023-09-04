provider "aws" {
  region = "ap-south-1"
}
resource "aws_lambda_function" "spotify-south-lambda" {

  filename = "${path.module}/node-spotify-lambda/upload.zip"
  function_name = "spotify-south-lambda"
  runtime="nodejs18.x"
  timeout = 100
  handler = "index.handler"
  role = aws_iam_role.lambda.arn

}
data "archive_file" "zip_nodejs_code" {
    type="zip"
    source_dir = "${path.module}/node-spotify-lambda"
    output_path = "${path.module}/node-spotify-lambda/upload.zip"
}
resource "aws_iam_role" "lambda" {
  name = "lambda_s3_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
resource "aws_iam_role_policy" "lambda" {
  name = "lambda_s3_policy"
  role = aws_iam_role.lambda.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
resource "aws_cloudwatch_event_rule" "spotify_cron_rule" {
  name = "spotify_cron_rule"
  schedule_expression = "cron(0 0 ? * 2 *)"
}

resource "aws_cloudwatch_event_target" "spotify_lambda_target" {
  rule = aws_cloudwatch_event_rule.spotify_cron_rule.name
  target_id = "spotify-south-lambda"
  arn = aws_lambda_function.spotify-south-lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_invoke_lambda" {
  function_name = "spotify-south-lambda"
  action = "lambda:InvokeFunction"
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.spotify_cron_rule.arn
  statement_id = "CloudWatchInvoke"
}