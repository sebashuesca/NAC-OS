import json
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
