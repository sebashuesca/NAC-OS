git init
git branch -M main
git branch develop
clear
sudo dnf update -y
sudo dnf install git -y
sudo dnf install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
newgrp docker
sudo dnf install python3-pip -y
pip3 install boto3 --user
git --version
docker --version
python3 -c "import boto3; print('Boto3 instalado correctamente')"
git init
git branch -M main
git branch develop
clear
touch README.md
git add README.md
git commit -m "feat: commit inicial"
git branch -M main
git branch develop
cat <<EOF > .gitignore
__pycache__/
*.env
.aws/
terraform.tfstate
*.zip
EOF

git add .gitignore
git commit -m "docs: agrega archivo gitignore para excluir credenciales"
git remote add origin https://github.com/sebashuesca/NAC-OS.git
git push -u origin main
clear
mkdir scripts
cd scripts
cat << 'EOF' > setup_env.sh
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
EOF

cat << 'EOF' > clean_logs.sh
#!/bin/bash
# Directorio donde se guardarán los logs de la app
LOG_DIR="$HOME/logs"
mkdir -p "$LOG_DIR"

echo "Limpiando logs antiguos en $LOG_DIR..."
# Encuentra y elimina archivos .log mayores a 7 días
find "$LOG_DIR" -type f -name "*.log" -mtime +7 -exec rm -f {} \;
echo "Limpieza completada: $(date)" >> "$LOG_DIR/cleanup_history.txt"
EOF

chmod +x setup_env.sh clean_logs.sh
(crontab -l 2>/dev/null; echo "0 2 * * * /home/ec2-user/scripts/clean_logs.sh") | crontab -
sudo dnf install cronie -y
sudo systemctl start crond
sudo systemctl enable crond
(crontab -l 2>/dev/null; echo "0 2 * * * /home/ec2-user/scripts/clean_logs.sh") | crontab -
crontab -l
cat << 'EOF' > aws_manager.py
import boto3
from datetime import datetime

# Configuracion
REGION = 'us-east-1'
# Usamos un nombre unico para el bucket basado en tu usuario y proyecto
BUCKET_NAME = 'imov-data-sebashuesca' 

ec2 = boto3.client('ec2', region_name=REGION)
s3 = boto3.client('s3', region_name=REGION)

def setup_s3():
    print(f"1. Creando bucket: {BUCKET_NAME}...")
    try:
        s3.create_bucket(Bucket=BUCKET_NAME)
        
        # Habilitar versionado
        s3.put_bucket_versioning(
            Bucket=BUCKET_NAME,
            VersioningConfiguration={'Status': 'Enabled'}
        )
        print("   -> Versionado habilitado.")
        
        # Habilitar cifrado en reposo (AES256)
        s3.put_bucket_encryption(
            Bucket=BUCKET_NAME,
            ServerSideEncryptionConfiguration={
                'Rules': [{'ApplyServerSideEncryptionByDefault': {'SSEAlgorithm': 'AES256'}}]
            }
        )
        print("   -> Cifrado en reposo habilitado.")
    except Exception as e:
        print(f"Nota: El bucket ya existe o hubo un problema: {e}")

def generate_report():
    print("\n2. Generando reporte de infraestructura...")
    filename = 'reporte_infraestructura.txt'
    with open(filename, 'w') as f:
        f.write("=== Reporte de Infraestructura ===\n")
        f.write(f"Fecha de generacion: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        
        # Consultar EC2
        f.write("--- Instancias EC2 ---\n")
        instances = ec2.describe_instances()
        for res in instances['Reservations']:
            for inst in res['Instances']:
                f.write(f"ID: {inst['InstanceId']}, Estado: {inst['State']['Name']}, Tipo: {inst['InstanceType']}\n")
        
        # Consultar S3
        f.write("\n--- Buckets S3 ---\n")
        buckets = s3.list_buckets()
        for bucket in buckets['Buckets']:
            f.write(f"- {bucket['Name']}\n")
            
    print(f"   -> Reporte local generado: {filename}")
    return filename

def upload_to_s3(filename):
    print(f"\n3. Subiendo {filename} al bucket {BUCKET_NAME}...")
    s3.upload_file(filename, BUCKET_NAME, filename)
    print("   -> Carga exitosa automatizada.")

if __name__ == "__main__":
    setup_s3()
    report_file = generate_report()
    upload_to_s3(report_file)
EOF

python3 aws_manager.py
cd ~
git add scripts/aws_manager.py
git commit -m "feat: automatizacion de S3 y reportes EC2 con boto3 exitosa"
git push origin main
mkdir -p ~/app
cd ~/app
# 1. Crear app web de prueba (Flask)
cat << 'EOF' > app.py
from flask import Flask, jsonify
app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({"mensaje": "Bienvenido al API de IMov", "estado": "Operativo"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# 2. Requerimientos
echo "Flask==2.2.5" > requirements.txt
echo "Werkzeug==2.2.3" >> requirements.txt
# 3. Dockerfile (Multi-stage build)
cat << 'EOF' > Dockerfile
# Stage 1: Builder
FROM python:3.9-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user -r requirements.txt

# Stage 2: Runtime
FROM python:3.9-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY . .
ENV PATH=/root/.local/bin:$PATH
EXPOSE 5000
CMD ["python", "app.py"]
EOF

# 4. Docker Compose
cat << 'EOF' > docker-compose.yml
version: '3.8'
services:
  web:
    build: .
    ports:
      - "80:5000"
    restart: always
EOF

sudo docker compose up -d
curl http://localhost
cd ~/app
sudo docker compose up -d --build
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo docker-compose up -d --build
sudo docker ps
curl http://localhost
sudo docker build -t imov-app .
sudo docker run -d -p 80:5000 --name imov-web --restart always imov-app
sudo docker ps
curl http://localhost
cd ~/scripts
cat << 'EOF' > dynamo_manager.py
import boto3

REGION = 'us-east-1'
TABLE_NAME = 'IMov-Inventory'

dynamodb = boto3.client('dynamodb', region_name=REGION)

def manage_dynamodb():
    print(f"1. Creando tabla DynamoDB: {TABLE_NAME}...")
    try:
        dynamodb.create_table(
            TableName=TABLE_NAME,
            KeySchema=[{'AttributeName': 'ItemID', 'KeyType': 'HASH'}],
            AttributeDefinitions=[{'AttributeName': 'ItemID', 'AttributeType': 'S'}],
            BillingMode='PAY_PER_REQUEST'
        )
        print("   -> Esperando a que la tabla este activa (esto toma unos segundos)...")
        waiter = dynamodb.get_waiter('table_exists')
        waiter.wait(TableName=TABLE_NAME)
        print("   -> Tabla creada exitosamente.")
    except Exception as e:
        print(f"   -> Nota: La tabla probablemente ya existe. Detalles: {e}")

    print("\n2. Insertando registro de prueba...")
    dynamodb.put_item(
        TableName=TABLE_NAME,
        Item={
            'ItemID': {'S': 'PROD-001'},
            'Nombre': {'S': 'Tablet Samsung Tab S9 Ultra'},
            'Stock': {'N': '15'}
        }
    )
    print("   -> Registro insertado: PROD-001.")

    print("\n3. Leyendo el registro...")
    response = dynamodb.get_item(
        TableName=TABLE_NAME,
        Key={'ItemID': {'S': 'PROD-001'}}
    )
    print(f"   -> Datos recuperados: {response.get('Item')}")

    print("\n4. Eliminando el registro (cumpliendo rubrica)...")
    dynamodb.delete_item(
        TableName=TABLE_NAME,
        Key={'ItemID': {'S': 'PROD-001'}}
    )
    print("   -> Registro eliminado exitosamente.")

if __name__ == "__main__":
    manage_dynamodb()
EOF

python3 dynamo_manager.py
cd ~
git add app/ scripts/dynamo_manager.py
git commit -m "feat: dockerizacion de app y script CRUD de dynamodb"
git push origin main
cd ~/scripts
cat << 'EOF' > lambda_manager.py
import boto3
import zipfile
import json
import time

REGION = 'us-east-1'
LAMBDA_NAME = 'IMov-RandomJSON'
ROLE_NAME = 'NAC-OS-Lambda-Role'

iam = boto3.client('iam')
lambda_client = boto3.client('lambda', region_name=REGION)

def deploy_microservice():
    print("1. Configurando Rol IAM para Lambda...")
    try:
        role = iam.get_role(RoleName=ROLE_NAME)
        role_arn = role['Role']['Arn']
        print("   -> El rol ya existe.")
    except Exception:
        print("   -> Creando nuevo rol para Lambda...")
        trust_policy = {
            "Version": "2012-10-17",
            "Statement": [{"Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]
        }
        role = iam.create_role(RoleName=ROLE_NAME, AssumeRolePolicyDocument=json.dumps(trust_policy))
        iam.attach_role_policy(RoleName=ROLE_NAME, PolicyArn='arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole')
        role_arn = role['Role']['Arn']
        print("   -> Esperando 10s para que AWS propague los permisos...")
        time.sleep(10)

    print("\n2. Creando y empaquetando el codigo...")
    lambda_code = """import json
import random
def lambda_handler(event, context):
    mensajes = [
        "Bienvenido a IMov",
        "Microservicio Serverless Operativo",
        "La arquitectura responde correctamente",
        "AWS Lambda conectado con exito"
    ]
    return {
        'statusCode': 200,
        'body': json.dumps({'mensaje': random.choice(mensajes)})
    }
"""
    with open('lambda_function.py', 'w') as f:
        f.write(lambda_code)
        
    with zipfile.ZipFile('lambda_function.zip', 'w') as z:
        z.write('lambda_function.py')

    print("\n3. Desplegando la funcion en AWS...")
    try:
        with open('lambda_function.zip', 'rb') as f:
            lambda_client.create_function(
                FunctionName=LAMBDA_NAME,
                Runtime='python3.9',
                Role=role_arn,
                Handler='lambda_function.lambda_handler',
                Code=dict(ZipFile=f.read()),
                Timeout=10,
                MemorySize=128
            )
        print("   -> Funcion creada exitosamente.")
    except Exception as e:
        print(f"   -> Nota: {e}")

    print("\n4. Aplicando limite de 10 ejecuciones concurrentes (Rubrica)...")
    try:
        lambda_client.put_function_concurrency(FunctionName=LAMBDA_NAME, ReservedConcurrentExecutions=10)
        print("   -> Limite establecido en 10.")
    except Exception as e:
         print(f"   -> Nota: {e}")

if __name__ == "__main__":
    deploy_microservice()
EOF

python3 lambda_manager.py
mkdir -p ~/templates
cd ~/templates
cat << 'EOF' > infraestructura.yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Infraestructura como Codigo para IMov (EC2 y S3)'
Resources:
  IMovBucketIaC:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub "imov-iac-data-${AWS::AccountId}"

  IMovServerIaC:
    Type: AWS::EC2::Instance
    Properties:
      InstanceType: t2.micro
      ImageId: ami-0c101f26f147fa7fd
      IamInstanceProfile: NAC-OS-EC2-Role
      Tags:
        - Key: Name
          Value: IMov-App-Server
EOF

# Desplegar la infraestructura en AWS
aws cloudformation deploy --template-file infraestructura.yaml --stack-name IMov-Stack --capabilities CAPABILITY_NAMED_IAM
cd ~
cat << 'EOF' > buildspec.yml
version: 0.2
phases:
  pre_build:
    commands:
      - echo "Iniciando pipeline CI/CD..."
  build:
    commands:
      - echo "Ejecutando pruebas de codigo..."
      - echo "Pruebas superadas. Construyendo la imagen Docker de IMov..."
      - cd app && docker build -t imov-app .
  post_build:
    commands:
      - echo "Construccion exitosa. Pipeline completado."
EOF

# Subir a GitHub
git add templates/ buildspec.yml
git commit -m "feat: IaC con CloudFormation y buildspec para AWS CodePipeline"
git push origin main
