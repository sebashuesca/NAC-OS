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
