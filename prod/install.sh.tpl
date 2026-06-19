```bash
#!/bin/bash
set -e
set -u

#install aws cli
sudo apt-get update -y
sudo apt install unzip -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

#install kubectl
sudo apt-get update -y
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.34.6/2026-04-08/bin/linux/amd64/kubectl
sudo chmod +x ./kubectl
sudo mv kubectl /usr/local/bin/

#install eksctl
sudo apt-get update -y
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl  /usr/local/bin/
eksctl version

# #install terraform

sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt-get install terraform -y

# Intalling Helm
sudo snap install helm --classic

# install jq for parsing json in bash
sudo apt-get install -y jq

# ----------------------------
# GitHub Actions Runner setup
# ----------------------------

GH_PAT="${github_pat}"

RUNNER_TOKEN=$(curl -s -X POST \
  -H "Authorization: token $GH_PAT" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/vinaypo/EKS_Cluster_Terraform/actions/runners/registration-token \
  | jq -r .token)

if [ -z "$RUNNER_TOKEN" ] || [ "$RUNNER_TOKEN" = "null" ]; then
  echo "ERROR: Failed to get runner token"
  exit 1
fi

useradd -m -s /bin/bash ubuntu || true

mkdir -p /home/ubuntu/actions-runner
chown -R ubuntu:ubuntu /home/ubuntu/actions-runner

sudo -u ubuntu bash <<EOF
set -euxo pipefail

cd /home/ubuntu/actions-runner

curl -L -o actions-runner.tar.gz \
https://github.com/actions/runner/releases/download/v2.334.0/actions-runner-linux-x64-2.334.0.tar.gz

tar xzf actions-runner.tar.gz

./config.sh \
  --url https://github.com/vinaypo/EKS_Cluster_Terraform \
  --token "$RUNNER_TOKEN" \
  --name "$$(hostname)" \
  --labels self-hosted,eks,bastion \
  --unattended \
  --replace
EOF

cd /home/ubuntu/actions-runner

sudo ./svc.sh install ubuntu
sudo ./svc.sh start
sudo ./svc.sh status
```
