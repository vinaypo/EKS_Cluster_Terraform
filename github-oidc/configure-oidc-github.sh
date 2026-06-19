#!/bin/bash
set -e

export OIDC_PROVIDER="token.actions.githubusercontent.com"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)


export GITHUB_ORG="vinaypo" # GitHub Org/Owner
export GITHUB_REPO="EKS_Cluster_Terraform"  # Repo you want to allow to use OIDC with AWS

# Create the OIDC provider
aws iam create-open-id-connect-provider \
  --url https://$OIDC_PROVIDER \
  --client-id-list sts.amazonaws.com \

# Create IAM ROle for GitHub Actions
aws iam create-role \
  --role-name GitHubActionsEKSDeployRole \
  --assume-role-policy-document file://trust-policy.json


# Attach the policy to the role
aws iam attach-role-policy \
  --role-name GitHubActionsEKSDeployRole \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess



