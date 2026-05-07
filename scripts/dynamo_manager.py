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
