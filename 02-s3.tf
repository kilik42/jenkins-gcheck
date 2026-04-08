# This Terraform configuration creates an S3 bucket configured for static website hosting, with public read access to the objects. It includes ownership controls and a sample index.html file.
resource "aws_s3_bucket" "frontend" {
  bucket_prefix = "jenkins-bucket-"
  force_destroy = true

  tags = {
    Name = "Jenkins Bucket"
  }
}

# Ownership controls to ensure the bucket owner has control over the objects
resource "aws_s3_bucket_ownership_controls" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Public access block to allow public read access for the website
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  # The following settings allow public access to the bucket for website hosting. Adjust these settings as needed for your security requirements.
  block_public_acls       = false # Allow public ACLs
  block_public_policy     = false # Allow public policies
  ignore_public_acls      = false # Do not ignore public ACLs
  restrict_public_buckets = false # Do not restrict public buckets
}

# Configure the bucket for static website hosting
resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }
}

# Upload a sample index.html file to the bucket
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "index.html"
  content_type = "text/html"
  content      = <<EOF
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Jenkins GCheck</title>
</head>
<body>
  <h1>Jenkins GCheck Deployment Successful</h1>
  <p>This bucket was provisioned by Terraform.</p>
  <p>Artifacts are uploaded into S3 folders as part of this deployment.</p>

</body>
</html>
EOF

  depends_on = [aws_s3_bucket_website_configuration.frontend]
}


# Set a bucket policy to allow public read access to the objects in the bucket
resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.frontend]
}
# UPLOAD ALL PNG IMAGES FROM LOCAL FOLDERS
# local file:  s3_objects/Audit Artifacts.png
# S3 object:   Audit Artifacts.png
resource "aws_s3_object" "images" {
  #
  for_each = fileset("${path.module}/s3_objects", "*.png")

  bucket = aws_s3_bucket.frontend.id
  key    = each.value
  source = "${path.module}/s3_objects/${each.value}"

  # This helps S3 know the files are images.
  content_type = "image/png"

  # This makes Terraform notice when the image file changes.
  etag = filemd5("${path.module}/s3_objects/${each.value}")

  depends_on = [aws_s3_bucket_website_configuration.frontend]
}


# OPTIONAL: UPLOAD TXT FILES TOO
# This uploads any .txt files from the same folder.
resource "aws_s3_object" "text_files" {
  for_each = fileset("${path.module}/s3_objects", "*.txt")

  bucket = aws_s3_bucket.frontend.id
  key    = each.value
  source = "${path.module}/s3_objects/${each.value}"

  content_type = "text/plain"
  etag         = filemd5("${path.module}/s3_objects/${each.value}")

  depends_on = [aws_s3_bucket_website_configuration.frontend]
}







# Output the bucket name and website URL
output "bucket_name" {
  value = aws_s3_bucket.frontend.bucket
}

# Output the website endpoint URL
output "website_url" {
  value = aws_s3_bucket_website_configuration.frontend.website_endpoint
}
