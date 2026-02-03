#!/bin/bash
dnf update -y
dnf install -y python3-pip
pip3 install flask pymysql boto3

# configure cloudwatch agent
dnf install -y amazon-cloudwatch-agent
cat >/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWC'
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/rdsapp.log",
                        "log_group_name": "${log_group}",
                        "log_stream_name": "{instance_id}"
                    }
                ]
            }
        }
    },
    "metrics": {
        "metrics_collected": {
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ]
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],  
                "resources": [
                    "/"
                ]          
            }
        }   
    }
}
CWC

systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# configure web app
mkdir -p /opt/rdsapp/static

echo "This is a test of the blah blah blah" > /opt/rdsapp/static/example.txt

cat >/opt/rdsapp/static/index.html <<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Static Page</title>
</head>
<body>
    <h1>This is a Heading</h1>
    <p>This is a paragraph.</p>
</body>
</html>
HTML
curl -o /opt/rdsapp/static/jquery.js https://code.jquery.com/jquery-3.7.1.min.js
curl -o /opt/rdsapp/static/bootstrap.css https://cdn.jsdelivr.net/npm/bootstrap@4.0.0/dist/css/bootstrap.min.css
cat >/opt/rdsapp/app.py <<'PY'
import json
import os
import boto3
import pymysql
from flask import Flask, request, make_response, send_file
import logging
from logging.handlers import RotatingFileHandler
from datetime import datetime, timezone
import uuid

# logging
handler = RotatingFileHandler('/var/log/rdsapp.log', maxBytes=10000, backupCount=3)
formatter = logging.Formatter('[%(asctime)s] %(levelname)s in %(module)s: %(message)s')
handler.setFormatter(formatter)
handler.setLevel(logging.INFO)
#logging.root.handlers = [handler] # this replaces the root loggers handler and will stop us from being able to use app.logger
logging.getLogger("werkzeug").addHandler(handler)
logging.getLogger("werkzeug").setLevel(logging.INFO)

REGION = os.environ.get("AWS_REGION", "us-east-1")
SECRET_ID = os.environ.get("SECRET_ID", "lab/rds/mysql")
PUBLISH_CUSTOM_METRIC = os.environ.get("PUBLISH_CUSTOM_METRIC", "true").lower() == "true"

secrets = boto3.client("secretsmanager", region_name=REGION)
cloudwatch = boto3.client("cloudwatch", region_name=REGION)

def record_db_connection_error():
    if not PUBLISH_CUSTOM_METRIC:
        return
    cloudwatch.put_metric_data(
        Namespace="Lab/RDSApp",
        MetricData=[
            {
                "MetricName": "DBConnectionErrors",
                "Value": 1,
                "Unit": "Count"
            }
        ]
    )

def get_db_creds():
    resp = secrets.get_secret_value(SecretId=SECRET_ID)
    s = json.loads(resp["SecretString"])
    # When you use "Credentials for RDS database", AWS usually stores:
    # username, password, host, port, dbname (sometimes)
    return s

def get_conn():
    c = get_db_creds()
    host = c["host"]
    user = c["username"]
    password = c["password"]
    port = int(c.get("port", 3306))
    try:
        db = c.get("dbname", "labdb")  # we'll create this if it doesn't exist
        return pymysql.connect(host=host, user=user, password=password, port=port, database=db, autocommit=True)
    except Exception as e:
        record_db_connection_error()
        raise e

app = Flask(__name__)
app.logger.addHandler(handler) # attach our custom logger to the logger flask actually uses and bypass root logger propogation
# propogation ctonrols if log records are passed up the logger heirarchy to parent loggers
# In Python logging, handlers don’t “float” — they must be attached to the logger that emits the log.
app.logger.setLevel(logging.INFO)
app.config["SEND_FILE_MAX_AGE_DEFAULT"] = 8600 # control browser caching for static files

@app.after_request
def log_response(response):
    app.logger.info(
        "PATH=%s STATUS=%s RESPONSE_HEADERS=%s REQUEST_HEADERS=%s",
        request.path,
        response.status_code,
        dict(response.headers),
        dict(request.headers),
    )
    return response

# override the default cache control header that flask uses for static content
#@app.after_request
#def add_static_cache_headers(response):
#    if request.path.startswith("/static"):
#        response.headers["Cache-Control"] = "public, max-age=8600, immutable"
#    return response

@app.route("/")
def home():
    return """
    <h2>EC2 → RDS Notes App</h2>
    <p>POST /add?note=hello</p>
    <p>GET /list</p>
    """

@app.route("/api/init")
def init_db():
    c = get_db_creds()
    host = c["host"]
    user = c["username"]
    password = c["password"]
    port = int(c.get("port", 3306))

    # connect without specifying a DB first
    conn = None
    try:
        conn = pymysql.connect(host=host, user=user, password=password, port=port, autocommit=True)
    except Exception as e:
        record_db_connection_error()
        return "Error connecting to RDS instance.", 500
    cur = conn.cursor()
    cur.execute("CREATE DATABASE IF NOT EXISTS labdb;")
    cur.execute("USE labdb;")
    cur.execute("""
        CREATE TABLE IF NOT EXISTS notes (
            id INT AUTO_INCREMENT PRIMARY KEY,
            note VARCHAR(255) NOT NULL
        );
    """)
    cur.close()
    conn.close()
    return "Initialized labdb + notes table."

@app.route("/api/add", methods=["POST", "GET"])
def add_note():
    note = request.args.get("note", "").strip()
    if not note:
        return "Missing note param. Try: /add?note=hello", 400
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("INSERT INTO notes(note) VALUES(%s);", (note,))
    cur.close()
    conn.close()
    return f"Inserted note: {note}"

@app.route("/api/list")
def list_notes():
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("SELECT id, note FROM notes ORDER BY id DESC;")
    rows = cur.fetchall()
    cur.close()
    conn.close()
    out = "<h3>Notes</h3><ul>"
    for r in rows:
        out += f"<li>{r[0]}: {r[1]}</li>"
    out += "</ul>"
    return out

@app.route("/api/public-feed")
def public_feed():
    server_time = datetime.now(timezone.utc)
    message = "Message of minute {}".format(server_time.minute)
    response = make_response(json.dumps({"server_time": server_time, "message": message}, default=str))
    response.headers["Cache-Control"] = "public, s-maxage=30, max-age=0"
    return response

@app.route("/api/user-feed")
def user_feed():
    server_time = datetime.now(timezone.utc)
    message = "Never cache so unique uuid is {}".format(uuid.uuid4())
    response = make_response(json.dumps({"server_time": server_time, "message": message}, default=str))
    response.headers["Cache-Control"] = "private, no-store"
    return response

@app.route("/static/index.html")
def static_index():
    response = send_file("static/index.html")
    response.set_etag("armageddon1")
    response.headers["Cache-Control"] = "public, max-age=30"
    return response

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
PY

cat >/etc/systemd/system/rdsapp.service <<'SERVICE'
[Unit]
Description=EC2 to RDS Notes App
After=network.target

[Service]
WorkingDirectory=/opt/rdsapp
Environment=SECRET_ID=${db_secret_name}
Environment=PUBLISH_CUSTOM_METRIC=${publish_custom_metric}
ExecStart=/usr/bin/python3 /opt/rdsapp/app.py
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable rdsapp
systemctl start rdsapp