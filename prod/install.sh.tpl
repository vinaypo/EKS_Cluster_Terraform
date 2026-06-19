```bash
#!/bin/bash
set -euxo pipefail

# Install AWS CLI
apt-get update -y
apt-get install -y unzip jq

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip -o awscliv2.zip
./aws/install

# Install kubectl
curl -LO https://s3.us-west-2.amazonaws.com/amazon-eks/1.34.6/2026-04-08/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install eksctl
curl --silent --location \
"https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
| tar xz -C /tmp

mv /tmp/eksctl /usr/local/bin/

# Install Terraform
apt-get install -y gnupg software-properties-common

wget -O- https://apt.releases.hashicorp.com/gpg \
| gpg --dearmor \
| tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com \
$(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" \
| tee /etc/apt/sources.list.d/hashicorp.list

apt-get update
apt-get install -y terraform

# Install Helm
snap install helm --classic

# ----------------------------
# Install GitHub Actions Runner
# ----------------------------

GH_PAT="${github_pat}"

RUNNER_TOKEN=$(curl -s -X POST \
  -H "Authorization: token $GH_PAT" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/vinaypo/EKS_Cluster_Terraform/actions/runners/registration-token \
  | jq -r .token)

mkdir -p /home/ubuntu/actions-runner
chown -R ubuntu:ubuntu /home/ubuntu/actions-runner

sudo -u ubuntu bash <<EOF
cd /home/ubuntu/actions-runner

curl -L -o actions-runner-linux-x64-2.334.0.tar.gz \
https://github.com/actions/runner/releases/download/v2.334.0/actions-runner-linux-x64-2.334.0.tar.gz

tar xzf actions-runner-linux-x64-2.334.0.tar.gz

./config.sh \
  --url https://github.com/vinaypo/EKS_Cluster_Terraform \
  --token "$RUNNER_TOKEN" \
  --name "\$(hostname)" \
  --labels self-hosted,eks,bastion \
  --unattended \
  --replace
EOF

cd /home/ubuntu/actions-runner
sudo ./svc.sh install ubuntu
sudo ./svc.sh start
sudo ./svc.sh status
```
