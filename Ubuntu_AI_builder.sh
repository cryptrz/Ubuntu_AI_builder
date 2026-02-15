#!/bin/bash
# Ubuntu AI Workstation
set -e

echo "Starting AI Environment Setup (v4.0)..."

# 1. Clean up broken sources first
sudo rm -f /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo rm -f /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

# 2. Update and Install Basics
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential git python3-pip nvtop curl wget docker.io gnupg2

# 3. Hardware Driver Logic
GPU_TYPE=$(lspci | grep -i 'vga\|3d' | grep -Ei "nvidia|amd")

if [[ $GPU_TYPE == *"NVIDIA"* ]]; then
    echo "NVIDIA GPU Detected. Fixing GPG keys and installing drivers..."
    sudo add-apt-repository ppa:graphics-drivers/ppa -y
    sudo apt update
    sudo ubuntu-drivers install
    
    # Download and store the key in the modern 'keyrings' location
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    
    # Add the repo with the 'signed-by' flag to link it directly to the key we just downloaded
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
      sed "s#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g" | \
      sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    
    sudo apt update
    sudo apt install -y nvidia-container-toolkit
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker
fi

# 4. Ollama (Engine)
echo "Installing Ollama..."
curl -fsSL https://ollama.com/install.sh | sh

echo "Waiting for Ollama server to initialize..."
sudo systemctl daemon-reload
sudo systemctl enable --now ollama

# Service Wait Loop
COUNT=0
while ! curl -s http://localhost:11434 > /dev/null; do
    echo "   ...waiting for Ollama ($((COUNT+1))/10)"
    sleep 3
    ((COUNT++))
    if [ $COUNT -ge 10 ]; then echo "Timeout"; exit 1; fi
done

# 5. Model & UI Provisioning
echo "Pulling Llama 3.2..."
ollama pull llama3.2

echo "Starting Open WebUI..."
sudo docker rm -f ai-webui 2>/dev/null || true
sudo docker run -d --network=host \
  -v open-webui:/app/backend/data \
  -e OLLAMA_BASE_URL=http://127.0.0.1:11434 \
  --name ai-webui \
  --restart always \
  ghcr.io/open-webui/open-webui:main

echo "ALL SYSTEMS GO! (If you run this script for the first time, reboot your PC to activate the drivers.)"
echo " UI: http://localhost:8080"
