# Create an S3 bucket for the frontend site.
# Using a prefix so Terraform generates a unique name.
resource "aws_s3_bucket" "frontend" {
  bucket_prefix = "jenkins-bucket-"
  force_destroy = true # Let Terraform delete the bucket even if it has files.

  tags = {
    Name = "Jenkins Bucket"
  }
}

# Make sure the bucket owner keeps control of uploaded objects.
resource "aws_s3_bucket_ownership_controls" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Allow this bucket to be publicly readable.
# Required for static website hosting — otherwise S3 blocks everything.
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Turn on static website hosting and point to index.html.
resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }
}

# Upload the main index.html file.
# This is the landing page for the site.
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "index.html"
  content_type = "text/html"

  content = <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Jenkins GCheck - Armageddon Repositories</title>
    <style>
        body { font-family: sans-serif; line-height: 1.6; padding: 20px; max-width: 800px; margin: auto; }
        h1 { color: #2c3e50; border-bottom: 2px solid #eee; }
        h2 { color: #34495e; margin-top: 30px; }
        .repo-link { background: #f4f4f4; padding: 10px; border-radius: 5px; display: block; word-break: break-all; }
        .status { color: green; font-weight: bold; }
    </style>
</head>
<body>
    <h1>Jenkins GCheck Deployment Successful</h1>
    <p class="status">✓ This bucket was provisioned by Marvin Evins</p>
    
    <hr>

    <h1>Armageddon Repositories</h1>

    <h2>T.K.O. (Tetsuzai Kube Ouroboros) – Armageddon Group Repo</h2>
    <a class="repo-link" href="https://github.com/jdpayne68/class-7-armageddon-tko-group">
        https://github.com/jdpayne68/class-7-armageddon-tko-group
    </a>

    <h2>Marvin Evins kilik42 Armageddon Labs Repo</h2>
    <a class="repo-link" href="https://github.com/kilik42/armageddon_labs_2026">
        https://github.com/kilik42/armageddon_labs_2026
    </a>

    <hr>
    <p><small>Artifacts and images are uploaded into S3 folders as part of this deployment.</small></p>
</body>
</html>
EOF

  depends_on = [aws_s3_bucket_website_configuration.frontend]
}

# Public read policy so the website can actually load files.
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

# Upload all PNG files from the local s3_objects folder.
# Terraform will re-upload only if the file changes (etag).
resource "aws_s3_object" "images" {
  for_each = fileset("${path.module}/s3_objects", "*.png")

  bucket       = aws_s3_bucket.frontend.id
  key          = each.value
  source       = "${path.module}/s3_objects/${each.value}"
  content_type = "image/png"
  etag         = filemd5("${path.module}/s3_objects/${each.value}")

  depends_on = [aws_s3_bucket_website_configuration.frontend]
}

# Same idea as above, but for .txt files.
resource "aws_s3_object" "text_files" {
  for_each = fileset("${path.module}/s3_objects", "*.txt")

  bucket       = aws_s3_bucket.frontend.id
  key          = each.value
  source       = "${path.module}/s3_objects/${each.value}"
  content_type = "text/plain"
  etag         = filemd5("${path.module}/s3_objects/${each.value}")

  depends_on = [aws_s3_bucket_website_configuration.frontend]
}

# Output the bucket name.
output "bucket_name" {
  value = aws_s3_bucket.frontend.bucket
}

# Output the website endpoint.
output "website_url" {
  value = aws_s3_bucket_website_configuration.frontend.website_endpoint
}
