import os, json, datetime, boto3, requests, psycopg2, psycopg2.extras as px

OURA = "https://api.ouraring.com/v2/usercollection"

def _sec(name):
    return boto3.client("secretsmanager").get_secret_value(SecretId=name)["SecretString"]

def _auth():
    return {"Authorization": f"Bearer {_sec('OURA_PAT')}"}

def _get(path, start, end):
    r = requests.get(f"{OURA}/{path}", headers=_auth(), params={"start_date": start, "end_date": end}, timeout=30)
    r.raise_for_status()
    return r.json().get("data", [])

def handler(event, context):
    jst = datetime.timezone(datetime.timedelta(hours=9))
    d = (datetime.datetime.now(tz=jst).date() - datetime.timedelta(days=1)).isoformat()

    s = (_get("daily_sleep", d, d) or [{}])[0]
    r = (_get("daily_readiness", d, d) or [{}])[0]
    a = (_get("daily_activity", d, d) or [{}])[0]

    row = {
        "date": d,
        "sleep_score":    s.get("score"),
        "sleep_duration": int(s["duration"]/60) if s.get("duration") else None,
        "sleep_eff":      s.get("efficiency"),
        "readiness_score": r.get("score"),
        "temp_dev":        r.get("temperature_deviation"),
        "rhr":             s.get("resting_heart_rate") or r.get("resting_heart_rate"),
        "hrv":             s.get("hrv_average"),
        "activity_score":  a.get("score"),
        "steps":           a.get("steps"),
        "calories":        a.get("cal_total"),
        "raw_json":        json.dumps({"sleep": s, "readiness": r, "activity": a})
    }

    conn = psycopg2.connect(_sec("AURORA_PG_URL"))
    conn.autocommit = True
    with conn, conn.cursor(cursor_factory=px.RealDictCursor) as cur:
        cur.execute("""
        CREATE TABLE IF NOT EXISTS oura_daily (
          date            date PRIMARY KEY,
          sleep_score     int,
          sleep_duration  int,
          sleep_eff       int,
          readiness_score int,
          temp_dev        numeric,
          rhr             int,
          hrv             int,
          activity_score  int,
          steps           int,
          calories        int,
          raw_json        jsonb
        );
        """)
        cur.execute("""
        INSERT INTO oura_daily
          (date, sleep_score, sleep_duration, sleep_eff, readiness_score, temp_dev,
           rhr, hrv, activity_score, steps, calories, raw_json)
        VALUES
          (%(date)s, %(sleep_score)s, %(sleep_duration)s, %(sleep_eff)s, %(readiness_score)s, %(temp_dev)s,
           %(rhr)s, %(hrv)s, %(activity_score)s, %(steps)s, %(calories)s, %(raw_json)s)
        ON CONFLICT (date) DO UPDATE SET
          sleep_score=EXCLUDED.sleep_score,
          sleep_duration=EXCLUDED.sleep_duration,
          sleep_eff=EXCLUDED.sleep_eff,
          readiness_score=EXCLUDED.readiness_score,
          temp_dev=EXCLUDED.temp_dev,
          rhr=EXCLUDED.rhr,
          hrv=EXCLUDED.hrv,
          activity_score=EXCLUDED.activity_score,
          steps=EXCLUDED.steps,
          calories=EXCLUDED.calories,
          raw_json=EXCLUDED.raw_json;
        """, row)
    conn.close()
    return {"ok": True, "upserted": d}
