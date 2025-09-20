import os
import json
import boto3

rds = boto3.client("rds-data")

CLUSTER_ARN   = os.environ["CLUSTER_ARN"]     # Aurora Cluster ARN
DB_SECRET_ARN = os.environ["DB_SECRET_ARN"]   # DB認証用 Secret ARN (username/password入り)
DB_NAME       = os.environ.get("DB_NAME", "ouradb")

def handler(event, context):
    # デフォルトは直近7日分
    days = int(event.get("days", 7)) if isinstance(event, dict) else 7
    dtype = event.get("type", "all") if isinstance(event, dict) else "all"

    where_clause = f"summary_date >= (CURRENT_DATE - INTERVAL '{days} days')"
    params = []
    if dtype != "all":
        where_clause += " AND type = :tp"
        params.append({"name":"tp", "value":{"stringValue":dtype}})

    sql = f"""
        SELECT type, summary_date, payload->>'score' AS score
        FROM oura.daily_summary
        WHERE {where_clause}
        ORDER BY summary_date DESC, type
        LIMIT 50
    """

    resp = rds.execute_statement(
        resourceArn=CLUSTER_ARN,
        secretArn=DB_SECRET_ARN,
        database=DB_NAME,
        sql=sql,
        parameters=params
    )

    # Data API の戻り値をパース
    rows = []
    for record in resp.get("records", []):
        row = {}
        if len(record) > 0 and "stringValue" in record[0]:
            row["type"] = record[0]["stringValue"]
        if len(record) > 1 and "stringValue" in record[1]:
            row["summary_date"] = record[1]["stringValue"]
        if len(record) > 2:
            val = record[2].get("stringValue") or record[2].get("longValue")
            row["score"] = val
        rows.append(row)

    return {
        "count": len(rows),
        "rows": rows
    }
