import json
import boto3
import psycopg2
import os

def lambda_handler(event, context):
    secret_name = os.environ['AURORA_PG_URL_SECRET_NAME']
    region_name = "us-east-1"  # Auroraと同じリージョン

    # Secrets ManagerからDB接続情報を取得
    session = boto3.session.Session()
    client = session.client(service_name='secretsmanager', region_name=region_name)
    secret_value = client.get_secret_value(SecretId=secret_name)
    secret = json.loads(secret_value['SecretString'])

    # DB接続情報
    host = secret['host']
    port = secret['port']
    dbname = secret['dbname']
    user = secret['username']
    password = secret['password']

    # PostgreSQLに接続
    try:
        conn = psycopg2.connect(
            host=host,
            port=port,
            dbname=dbname,
            user=user,
            password=password
        )
        cur = conn.cursor()
        cur.execute("SELECT * FROM your_table LIMIT 10;")  # ←ここはお好みで
        rows = cur.fetchall()
        columns = [desc[0] for desc in cur.description]  # カラム名取得
        result = [dict(zip(columns, row)) for row in rows]  # リスト[辞書]化
        
        cur.close()
        conn.close()
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps(result)
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'body': str(e)
        }
