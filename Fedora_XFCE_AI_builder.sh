#!/bin/bash
# Fedora XFCE AI Workstation Auto-Provisioner 
set -e

echo "Starting AI Environment Setup for Fedora XFCE..."

# 1. Enable Repos & System Update
sudo dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf update -y

# 2. Hardware Driver & CDI Logic
GPU_TYPE=$(lspci | grep -i 'vga\|3d' | grep -Ei "nvidia|amd")

if [[ $GPU_TYPE == *"NVIDIA"* ]]; then
    echo "NVIDIA GPU Detected. Installing drivers..."
    # XFCE specific: we ensure the X11 CUDA libraries are explicitly present
    sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda libva-utils vdpauinfo
    
    # Setup NVIDIA Container Toolkit via COPR
    sudo dnf copr enable -y @ai-ml/nvidia-container-toolkit
    sudo dnf install -y nvidia-container-toolkit
    
    # Generate CDI specification for Podman
    sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
elif [[ $GPU_TYPE == *"AMD"* ]]; then
    echo "AMD GPU Detected. Installing ROCm stack..."
    sudo dnf install -y rocm-hip rocm-opencl
fi

# 3. Development Group
sudo dnf group install -y "AI/ML Development"
sudo dnf install -y nvtop podman

# 4. Initialize Ollama
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3.2

# 5. Open WebUI (Host Networking for X11 Stability)
if sudo podman container exists ai-webui; then
    sudo podman rm -f ai-webui
fi

# We add --security-opt label=disable to handle Fedora's SELinux on XFCE
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
echo "XFCE TIP: If the screen freezes during heavy inference,"
echo "press Ctrl+Alt+F2 and then Ctrl+Alt+F1 to reset the display."
echo "-------------------------------------------------------"
