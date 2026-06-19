#!/bin/bash
set -e
# Create Iam role for the User to access the cluster.
aws iam create-role \
    --role-name EKSAdminRole \
    --assume-role-policy-document file://eks-admin-trust-policy.json
# Attach the policy to the role
aws iam attach-role-policy \
  --role-name EKSAdminRole \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

aws eks create-access-entry \
    --cluster-name prod-eks-cluster \
    --principal-arn arn:aws:iam::741448944841:role/EKSAdminRole

aws eks associate-access-policy \
    --cluster-name prod-eks-cluster \
    --principal-arn arn:aws:iam::741448944841:role/EKSAdminRole \
    --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
    --access-scope type=cluster

aws sts assume-role \
    --role-arn arn:aws:iam::741448944841:role/EKSAdminRole \
    --role-session-name eks-admin

aws eks update-kubeconfig \
    --name prod-eks-cluster \
    --region us-east-1
