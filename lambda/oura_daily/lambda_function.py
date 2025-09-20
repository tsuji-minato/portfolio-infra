# lambda/oura_daily/lambda_function.py
import os, json, datetime as dt, requests, boto3

rds = boto3.client("rds-data")
sm  = boto3.client("secretsmanager")

CLUSTER_ARN = os.environ["CLUSTER_ARN"]
DB_SECRET_ARN = os.environ["DB_SECRET_ARN"]   # username/password を含む
DB_NAME = os.environ.get("DB_NAME","postgres")

def exec_sql(sql, params=None, tx=None):
    args = dict(resourceArn=CLUSTER_ARN, secretArn=DB_SECRET_ARN, database=DB_NAME, sql=sql)
    if params: args["parameters"] = params
    if tx:     args["transactionId"] = tx
    return rds.execute_statement(**args)

def handler(event, context):
    # Oura 期間
    today = dt.date.today()
    start_date = (today - dt.timedelta(days=int(os.environ.get("LOOKBACK_DAYS","14")))).isoformat()
    end_date   = today.isoformat()
    if isinstance(event, dict):
        start_date = event.get("start_date", start_date)
        end_date   = event.get("end_date", end_date)

    # Oura 取得
    token = json.loads(sm.get_secret_value(SecretId=os.environ["APP_SECRET_NAME"])["SecretString"])["OURA_PAT"]
    headers = {"Authorization": f"Bearer {token}"}
    base = "https://api.ouraring.com/v2/usercollection"
    endpoints = {"sleep":"daily_sleep","readiness":"daily_readiness","activity":"daily_activity"}

    # トランザクション開始
    tx = rds.begin_transaction(resourceArn=CLUSTER_ARN, secretArn=DB_SECRET_ARN, database=DB_NAME)["transactionId"]

    try:
        inserted = {}
        for dtype, ep in endpoints.items():
            res = requests.get(f"{base}/{ep}", headers=headers, params={"start_date":start_date,"end_date":end_date}, timeout=30).json()
            # 最初の配列を探す
            arr = next((v for v in res.values() if isinstance(v, list)), [])
            count = 0
            for item in arr:
                sdate = item.get("summary_date") or item.get("day")
                if not sdate: 
                    continue
                exec_sql(
                    """
                    INSERT INTO oura.daily_summary (user_id, type, summary_date, payload, created_at, updated_at)
                    VALUES (:uid, :tp, :sd::date, :pl::jsonb, now(), now())
                    ON CONFLICT (user_id, type, summary_date)
                    DO UPDATE SET payload = EXCLUDED.payload, updated_at = now();
                    """,
                    params=[
                        {"name":"uid","value":{"stringValue": os.environ.get("OURA_USER_ID","default_user")}},
                        {"name":"tp","value":{"stringValue": dtype}},
                        {"name":"sd","value":{"stringValue": sdate}},
                        {"name":"pl","value":{"stringValue": json.dumps(item)}},
                    ],
                    tx=tx
                )
                count += 1
            inserted[dtype] = count

        rds.commit_transaction(resourceArn=CLUSTER_ARN, secretArn=DB_SECRET_ARN, transactionId=tx)
        return {"start_date":start_date,"end_date":end_date,"inserted":inserted}
    except Exception as e:
        rds.rollback_transaction(resourceArn=CLUSTER_ARN, secretArn=DB_SECRET_ARN, transactionId=tx)
        raise
