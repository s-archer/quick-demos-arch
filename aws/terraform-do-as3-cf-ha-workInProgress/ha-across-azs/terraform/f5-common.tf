
resource "random_string" "password" {
  length  = 10
  special = false
}

data "aws_ami" "f5_ami" {
  most_recent = true
  owners      = ["679593333241"]

  filter {
    name   = "name"
    values = [var.f5_ami_search_name]
  }
}

# Create S3 bucket for Cloud Failover Extension (CFE)
resource "aws_s3_bucket" "arch_cfe" {
  bucket        = "arch-cfe-bucket"
  acl           = "private"
  force_destroy = true

  tags = {
    Name                    = "arch-cfe-bucket"
    Environment             = "Dev"
    f5_cloud_failover_label = "mydeployment"
  }
}

# Create IAM for CFE (Cloud Failover Extension)

resource "aws_iam_role_policy" "cfe" {
  name = "${var.prefix}-f5-cfe-policy"
  role = aws_iam_role.cfe.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeAddresses",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeNetworkInterfaceAttribute",
                "ec2:DescribeRouteTables",
                "s3:ListAllMyBuckets",
                "ec2:AssociateAddress",
                "ec2:DisassociateAddress",
                "ec2:AssignPrivateIpAddresses",
                "ec2:UnassignPrivateIpAddresses"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "sts:AssumeRole"
            ],
            "Resource": "arn:aws:iam:::role/*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "ec2:CreateRoute",
                "ec2:ReplaceRoute"
            ],
            "Resource": "arn:aws:ec2:*:498142139943:route-table/*",
            "Condition": {
                "StringEquals": {
                    "ec2:ResourceTag/Name": "f5_cloud_failover_label"
                }
            },
            "Effect": "Allow"
        },
        {
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketTagging"
            ],
            "Resource": "arn:aws:s3:::*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "sts:AssumeRole"
            ],
            "Resource": [
                "arn:aws:iam:::role/*",
                "arn:aws:s3:::*/*"
            ],
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_role" "cfe" {
  name = "${var.prefix}-f5-cfe-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17", 
    "Statement": [
        {
            "Action": "sts:AssumeRole", 
            "Effect": "Allow", 
            "Principal": {
                "Service": "ec2.amazonaws.com"
            }
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "cfe" {
  name = "${var.prefix}-cfe"
  role = aws_iam_role.cfe.name
}

