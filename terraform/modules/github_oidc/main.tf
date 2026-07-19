# OIDC provider + IAM role that lets GitHub Actions push images to ECR
# without long-lived AWS credentials. Scoped to this one repo and to
# ECR push actions on this app's two repositories only.

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # SHA1 fingerprints of every certificate in token.actions.githubusercontent.com's
  # actual current TLS chain (leaf, intermediate, cross-signed root), fetched
  # directly via openssl rather than trusted from memory or a tls_certificate
  # data source — both proved unreliable for this endpoint (GitHub now serves
  # a Let's Encrypt chain, not the older, widely-documented DigiCert one).
  # AWS allows up to 5 entries; including all three maximizes the chance of
  # matching whichever level AWS actually validates against.
  thumbprint_list = [
    "227203b5317f3818cab5b5ce596132bf36748c0e", # leaf: *.actions.githubusercontent.com
    "2d74d6dfd96eea55ad7baafa0d3c6552b2dadc37", # intermediate: Let's Encrypt YR2
    "ab9d0263244dd0326eb67015705a667e79cfe998", # cross-signed root: ISRG Root YR / X1
  ]

  tags = var.tags
}

locals {
  github_owner = split("/", var.github_repo)[0]
  github_name  = split("/", var.github_repo)[1]
}

data "aws_iam_policy_document" "github_actions_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    # AWS requires the trust policy to scope on "sub" (or "job_workflow_ref")
    # for GitHub's OIDC provider — a policy scoped only on the "repository"
    # claim below is rejected outright ("must evaluate ... sub ... which is
    # not scoped to all"). GitHub's current sub format embeds immutable
    # owner/repo IDs (repo:owner@<id>/repo@<id>:ref:...), not the plain
    # "owner/repo:*" shape most examples assume, hence the wildcards around
    # "@*" here rather than an exact repo-name match.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${local.github_owner}@*/${local.github_name}@*:*"]
    }
    # Belt-and-suspenders: also require the repository claim to match exactly.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:repository"
      values   = [var.github_repo]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.env}-patient-app-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "github_actions_ecr" {
  name = "${var.env}-patient-app-github-actions-ecr"
  role = aws_iam_role.github_actions.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = [var.ecr_backend_repo_arn, var.ecr_frontend_repo_arn]
      }
    ]
  })
}
