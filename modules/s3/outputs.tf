output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.main.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.main.arn
}

output "bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "logging_bucket_name" {
  description = "Name of the S3 logging bucket (if enabled)"
  value       = try(aws_s3_bucket.logging[0].bucket, null)
}

output "logging_bucket_arn" {
  description = "ARN of the S3 logging bucket (if enabled)"
  value       = try(aws_s3_bucket.logging[0].arn, null)
}
