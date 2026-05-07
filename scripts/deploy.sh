#!/bin/bash
# Este script se ejecutará automáticamente en la EC2
cd /home/ec2-user/app
# Detener contenedores anteriores
docker-compose down || true
# Cargar la nueva imagen y levantar el servicio
docker-compose up -d --build
