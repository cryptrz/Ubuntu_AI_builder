#!/bin/bash
# Fedora AI Workstation Auto-Provisioner (v2.0 - 2026)
# Targets: Fedora 43 / 44 / Rawhide

set -e # Exit on error

echo "Starting Idempotent Fedora AI Environment Setup..."

# 1. Enable Repos & System Update
sudo dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf update -y

# 2. Hardware Driver & Container Toolkit Logic
GPU_TYPE=$(lspci | grep -i 'vga\|3d' | grep -Ei "nvidia|amd")

if [[ $GPU_TYPE == *"NVIDIA"* ]]; then
    echo "NVIDIA GPU Detected. Installing drivers and CDI toolkit..."
    sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda
    
    # Install NVIDIA Container Toolkit (Fedora COPR is usually the most stable path)
    sudo dnf copr enable -y @ai-ml/nvidia-container-toolkit
    sudo dnf install -y nvidia-container-toolkit
    
    # Generate CDI specification (Crucial for Podman + NVIDIA)
    sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
elif [[ $GPU_TYPE == *"AMD"* ]]; then
    echo "AMD GPU Detected. Installing ROCm stack..."
    sudo dnf install -y rocm-hip rocm-opencl
fi

# 3. Install Fedora's AI/ML Development Group
echo "Installing AI/ML Toolchain..."
sudo dnf group install -y "AI/ML Development"
sudo dnf install -y nvtop podman

# 4. Ollama (Engine)
echo "Installing/Updating Ollama..."
curl -fsSL https://ollama.com/install.sh | sh

# 5. Model Pre-loading
echo "Pulling Llama 3.2..."
ollama pull llama3.2

# 6. Open WebUI (Interface) - Idempotent Logic
echo "Provisioning Open WebUI..."

# Remove existing container if it exists
if sudo podman container exists ai-webui; then
    echo "Existing container found. Replacing..."
    sudo podman rm -f ai-webui
fi

# Run with GPU access and Host Networking
# Note: --device nvidia.com/gpu=all is the standard for CDI in 2026
sudo podman run -d --network host \
  --device nvidia.com/gpu=all \
  --security-opt label=disable \
  -v open-webui:/app/backend/data \
  -e OLLAMA_BASE_URL=http://127.0.0.1:11434 \
  --name ai-webui \
  --restart always \
  ghcr.io/open-webui/open-webui:main

echo "Setup Complete!"
echo "-------------------------------------------------------"
echo "URL: http://localhost:8080"
echo "Check GPU: Run 'podman exec ai-webui nvidia-smi'"
echo "REBOOT now to finalize driver installation."
echo "-------------------------------------------------------"
