# plaid_backend.py
import os
from flask import Flask, request, jsonify
import requests
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

PLAID_CLIENT_ID = os.getenv("PLAID_CLIENT_ID")
PLAID_SECRET = os.getenv("PLAID_SECRET")
PLAID_ENV = os.getenv("PLAID_ENV", "sandbox")
PLAID_BASE_URL = f"https://{PLAID_ENV}.plaid.com"

app = Flask(__name__)

@app.route("/exchange_token", methods=["POST"])
def exchange_token():
    public_token = request.json.get("public_token")
    response = requests.post(f"{PLAID_BASE_URL}/item/public_token/exchange", json={
        "client_id": PLAID_CLIENT_ID,
        "secret": PLAID_SECRET,
        "public_token": public_token
    })
    return jsonify(response.json()), response.status_code

@app.route("/accounts", methods=["POST"])
def get_accounts():
    access_token = request.json.get("access_token")
    response = requests.post(f"{PLAID_BASE_URL}/accounts/get", json={
        "client_id": PLAID_CLIENT_ID,
        "secret": PLAID_SECRET,
        "access_token": access_token
    })
    return jsonify(response.json()), response.status_code

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=True)
