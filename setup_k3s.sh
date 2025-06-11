#!/bin/bash

set -e

USERNAME="k3suser"

# 1. Create user with no password and add to sudo
sudo adduser --disabled-password --gecos "" $USERNAME
sudo usermod -aG sudo $USERNAME

# 2. Allow passwordless sudo for the user
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$USERNAME

# 3. Install basic dependencies
sudo apt-get update
sudo apt-get install -y git curl bash-completion

# 4. Switch to the new user and run the rest
sudo -u $USERNAME bash <<EOF

# Set up home and environment
mkdir -p \$HOME/.kube

# 5. Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# 6. Install k3s (server) and let k3s setup kubeconfig
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik" sh -

EOF

# 7. Copy kubeconfig to user's home and fix ownership
sudo mkdir -p /home/$USERNAME/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/$USERNAME/.kube/config
sudo chown -R $USERNAME:$USERNAME /home/$USERNAME/.kube

# 8. Make KUBECONFIG and autocomplete persistent
sudo bash -c "cat <<'EOL' >> /home/$USERNAME/.bashrc

# Set KUBECONFIG
export KUBECONFIG=\$HOME/.kube/config

# kubectl completion
source <(kubectl completion bash)

# alias and autocomplete for 'k'
alias k=kubectl
complete -o default -F __start_kubectl k
EOL"

# 9. Ensure .bashrc is owned properly
sudo chown $USERNAME:$USERNAME /home/$USERNAME/.bashrc

echo "✅ Done. Login as '$USERNAME', run: kubectl get nodes or k get nodes"
