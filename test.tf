locals {
  access_analyzer_sf = ["${path.module}/${var.source_path_access_analyzer}/requirements.txt", "${path.module}/${var.source_path_access_analyzer}/access_analyzer_notification.py", "${path.module}/${var.source_path_access_analyzer}/__init__.py"]
}

resource "random_string" "random" {
  length  = 16
  special = false
}
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "vpc_log_bucket" {
  bucket        = "${var.env}-vpc-log-bucket-${lower(random_string.random.id)}"
  force_destroy = true
  acl           = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = var.s3_encryption_key
        sse_algorithm     = "aws:kms"
      }
    }
  }
  versioning {
    enabled = var.bucket_versioning
  }
  lifecycle {
    prevent_destroy = false
  }
  tags = {
    Name        = "${var.env}-vpc-log-bucket-${lower(random_string.random.id)}"
    Environment = "${var.env}"
    Department  = "CWP"
  }

}

resource "aws_s3_bucket_public_access_block" "vpc_bucket" {
  bucket = aws_s3_bucket.vpc_log_bucket.id
  # Block new public ACLs and uploading public objects
  block_public_acls = true
  # Retroactively remove public access granted through public ACLs
  ignore_public_acls = true
  # Block new public bucket policies
  block_public_policy = true
  # Retroactivley block public and cross-account access if bucket has public policies
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "lambda_bucket" {
  bucket = aws_s3_bucket.lambda_function_zip.id
  # Block new public ACLs and uploading public objects
  block_public_acls = true
  # Retroactively remove public access granted through public ACLs
  ignore_public_acls = true
  # Block new public bucket policies
  block_public_policy = true
  # Retroactivley block public and cross-account access if bucket has public policies
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "lambda_function_zip" {
  bucket        = "${var.env}-lambda-function-${lower(random_string.random.id)}"
  force_destroy = true
  acl           = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = var.s3_encryption_key
        sse_algorithm     = "aws:kms"
      }
    }
  }
  acceleration_status = "Enabled"
  versioning {
    enabled = false
  }
  lifecycle {
    prevent_destroy = false
  }
  tags = {
    Name        = "${var.env}-lambda-function-${lower(random_string.random.id)}"
    Environment = "${var.env}"
    Department  = "CWP"
  }

}

data "template_file" "access_analyzer_function_file" {
  count    = length(local.access_analyzer_sf)
  template = file(element(local.access_analyzer_sf, count.index))
}

resource "local_file" "access_analyzer_to_temp_dir" {
  count    = length(local.access_analyzer_sf)
  filename = "${path.module}/temp/access_analyzer_notification/access_analyzer_notification/${basename(element(local.access_analyzer_sf, count.index))}"
  content  = element(data.template_file.access_analyzer_function_file.*.rendered, count.index)
}

#Creating zip file and uploading to the desired output path
data "archive_file" "access_analyzer_lambda_functions_zip" {
  type        = "zip"
  source_dir  = "${path.module}/temp/access_analyzer_notification"
  output_path = "${path.module}/build/access_analyzer_notification.zip"
  depends_on = [
    local_file.access_analyzer_to_temp_dir,
  ]
}

resource "aws_s3_bucket_object" "access_analyzer_notification_zip" {
  bucket                 = aws_s3_bucket.lambda_function_zip.id
  key                    = "lambdas/access_analyzer_notification-${lower(random_string.random.id)}.zip"
  source                 = "${path.module}/build/access_analyzer_notification.zip"
  depends_on             = [data.archive_file.access_analyzer_lambda_functions_zip]
  server_side_encryption = "aws:kms"
  kms_key_id             = var.s3_encryption_key
}

resource "aws_s3_bucket_public_access_block" "neo4j-backup-np-shared" {
  bucket = aws_s3_bucket.neo4j-backup-np-shared.id
  # Block new public ACLs and uploading public objects
  block_public_acls = true
  # Retroactively remove public access granted through public ACLs
  ignore_public_acls = true
  # Block new public bucket policies
  block_public_policy = true
  # Retroactivley block public and cross-account access if bucket has public policies
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "neo4j-backup-np-shared" {
  bucket        = "${var.env}-neo4j-backup-np-shared-${lower(random_string.random.id)}"
  force_destroy = true
  acl           = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = var.s3_encryption_key
        sse_algorithm     = "aws:kms"
      }
    }
  }
  versioning {
    enabled = var.bucket_versioning
  }
  lifecycle {
    prevent_destroy = false
  }
  tags = {
    Name        = "${var.env}-neo4j-backup-np-shared-${lower(random_string.random.id)}"
    Environment = "${var.env}"
    Department  = "CWP"
  }
}
