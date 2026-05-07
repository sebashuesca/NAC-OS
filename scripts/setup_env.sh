#!/bin/bash
echo "=== Iniciando configuración del entorno ==="
# Actualizar sistema
sudo dnf update -y

# Instalar Git, Docker y Python3
sudo dnf install -y git docker python3-pip

# Iniciar y habilitar Docker
sudo systemctl start docker
sudo systemctl enable docker

# Instalar AWS CLI (por si no viene preinstalado) y Boto3
pip3 install awscli boto3 --user

echo "=== Entorno configurado exitosamente ==="
