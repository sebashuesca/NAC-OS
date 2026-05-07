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
