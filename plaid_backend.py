# plaid_backend.py (updated with user auth and onboarding endpoints)
import os
from flask import Flask, request, jsonify
import requests
from dotenv import load_dotenv
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import Column, String, Float, DateTime
from sqlalchemy import ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime, timedelta
from plaid.model.link_token_create_request import LinkTokenCreateRequest
from plaid.model.link_token_create_request_user import LinkTokenCreateRequestUser
from plaid.model.products import Products
from plaid.model.country_code import CountryCode
from plaid.model.item_public_token_exchange_request import ItemPublicTokenExchangeRequest
from plaid.model.accounts_get_request import AccountsGetRequest
from plaid.api import plaid_api
from plaid.configuration import Configuration
from plaid.model.transactions_get_request import TransactionsGetRequest
from plaid.model.transactions_get_request_options import TransactionsGetRequestOptions
from plaid.model.transactions_get_response import TransactionsGetResponse
from plaid.model.accounts_balance_get_request import AccountsBalanceGetRequest
import plaid
from plaid.api_client import ApiClient
from plaid import Environment
import traceback
from flask_bcrypt import Bcrypt
import jwt
from functools import wraps

# Load environment variables from .env file
load_dotenv()

PLAID_CLIENT_ID = os.getenv("PLAID_CLIENT_ID")
PLAID_SECRET = os.getenv("PLAID_SECRET")
PLAID_ENV = os.getenv("PLAID_ENV", "Sandbox")
PLAID_REDIRECT_URI = os.getenv("PLAID_REDIRECT_URI", "")
JWT_SECRET = os.getenv("JWT_SECRET", "supersecretkey")

configuration = Configuration(
    host=getattr(Environment, PLAID_ENV),
    api_key={'clientId': PLAID_CLIENT_ID, 'secret': PLAID_SECRET}
)
api_client = plaid_api.PlaidApi(ApiClient(configuration))

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///budget_tracker.db"
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
db = SQLAlchemy(app)
bcrypt = Bcrypt(app)

# -------------------- MODELS --------------------
class User(db.Model):
    __tablename__ = "user"
    id = Column(String, primary_key=True)
    email = Column(String, unique=True)
    password_hash = Column(String)
    access_tokens = relationship("AccessToken", back_populates="user")
    categories = relationship("Category", back_populates="user")
    goals = relationship("Goal", back_populates="user")

class AccessToken(db.Model):
    __tablename__ = "access_token"
    id = Column(String, primary_key=True)
    token = Column(String, nullable=False)
    user_id = Column(String, ForeignKey('user.id'))
    user = relationship("User", back_populates="access_tokens")

class Account(db.Model):
    __tablename__ = "account"
    id = Column(String, primary_key=True)
    name = Column(String)
    type = Column(String)
    subtype = Column(String)
    mask = Column(String)
    official_name = Column(String)
    balance = Column(Float)

class Category(db.Model):
    __tablename__ = "category"
    id = Column(String, primary_key=True)
    user_id = Column(String, ForeignKey("user.id"))
    name = Column(String)
    budget = Column(Float)
    user = relationship("User", back_populates="categories")

class Goal(db.Model):
    __tablename__ = "goal"
    id = Column(String, primary_key=True)
    user_id = Column(String, ForeignKey("user.id"))
    name = Column(String)
    target_amount = Column(Float)
    deadline = Column(DateTime, nullable=True)
    user = relationship("User", back_populates="goals")

# -------------------- AUTH DECORATOR --------------------
def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get("Authorization")
        if not token or not token.startswith("Bearer "):
            return jsonify({"error": "Token missing"}), 401
        token = token[7:]
        try:
            data = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            current_user = User.query.get(data["user_id"])
            if not current_user:
                return jsonify({"error": "User not found"}), 401
        except Exception as e:
            return jsonify({"error": str(e)}), 401
        return f(current_user, *args, **kwargs)
    return decorated

# -------------------- ONBOARDING / AUTH ENDPOINTS --------------------
@app.route("/users/signup", methods=["POST"])
def signup():
    data = request.get_json(force=True)
    email = data.get("email")
    password = data.get("password")
    if not email or not password:
        return jsonify({"error": "Email and password required"}), 400
    if User.query.filter_by(email=email).first():
        return jsonify({"error": "Email already exists"}), 400
    password_hash = bcrypt.generate_password_hash(password).decode("utf-8")
    user = User(id=email, email=email, password_hash=password_hash)
    db.session.add(user)
    db.session.commit()
    token = jwt.encode({"user_id": user.id}, JWT_SECRET, algorithm="HS256")
    return jsonify({"token": token}), 201

@app.route("/users/signin", methods=["POST"])
def signin():
    data = request.get_json(force=True)
    email = data.get("email")
    password = data.get("password")
    user = User.query.filter_by(email=email).first()
    if not user or not bcrypt.check_password_hash(user.password_hash, password):
        return jsonify({"error": "Invalid credentials"}), 401
    token = jwt.encode({"user_id": user.id}, JWT_SECRET, algorithm="HS256")
    return jsonify({"token": token}), 200

@app.route("/categories", methods=["POST"])
@token_required
def save_categories(current_user):
    data = request.get_json(force=True)
    categories = data.get("categories", [])
    for c in categories:
        cat = Category(id=c.get("id") or os.urandom(8).hex(), user=current_user, name=c.get("name"), budget=c.get("budget"))
        db.session.merge(cat)
    db.session.commit()
    return jsonify({"message": "Categories saved"}), 200

@app.route("/goals", methods=["POST"])
@token_required
def save_goals(current_user):
    data = request.get_json(force=True)
    goals = data.get("goals", [])
    for g in goals:
        deadline = datetime.fromisoformat(g["deadline"]) if g.get("deadline") else None
        goal = Goal(id=g.get("id") or os.urandom(8).hex(), user=current_user, name=g.get("name"), target_amount=g.get("target_amount"), deadline=deadline)
        db.session.merge(goal)
    db.session.commit()
    return jsonify({"message": "Goals saved"}), 200

# -------------------- EXISTING PLAID ENDPOINTS --------------------
@app.route("/accounts/link", methods=["POST"])
def link_account():
    try:
        data = request.get_json(force=True)
        public_token = data.get("public_token")
        print("Received public_token:", public_token)

        if not public_token:
            return jsonify({"error": "Missing public_token"}), 400

        # Exchange public token for access token
        exchange_request = ItemPublicTokenExchangeRequest(
            public_token=public_token
        )
        exchange_response = api_client.item_public_token_exchange(exchange_request)
        access_token = exchange_response['access_token']
        if not access_token:
            return jsonify({"error": "Failed to exchange token"}), 400

        # Save access_token in DB for the user
        user_id = "unique-user-id"  # Replace with actual user session logic in production
        user = User.query.get(user_id)
        if not user:
            user = User(id=user_id)
            db.session.add(user)

        token_entry = AccessToken(id=access_token, token=access_token, user=user)
        db.session.merge(token_entry)
        db.session.commit()

        # Fetch accounts
        accounts_request = AccountsGetRequest(access_token=access_token)
        accounts_response = api_client.accounts_get(accounts_request)
        accounts = accounts_response['accounts']

        print("Fetched from Plaid:", accounts_response)
        print("Parsed accounts:", accounts)
        # Store accounts in DB
        for acc in accounts:
            print("Saving account:", acc["account_id"], acc.get("name"))
            db.session.merge(Account(
                id=acc["account_id"],
                name=acc.get("name"),
                type=acc.get("type").value if acc.get("type") else None,
                subtype=acc.get("subtype").value if acc.get("subtype") else None,
                mask=acc.get("mask"),
                official_name=acc.get("official_name"),
                balance=acc["balances"].get("available", 0.0)
            ))
        db.session.commit()

        print("DB path:", app.config["SQLALCHEMY_DATABASE_URI"])
        print("Accounts in DB:", Account.query.all())

        return jsonify({"message": "Accounts linked"}), 200
    except plaid.ApiException as e:
        return jsonify({"error": str(e)}), 500
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/accounts", methods=["POST"])
def get_accounts():
    access_token = request.json.get("access_token")
    response = requests.post(f"{PLAID_BASE_URL}/accounts/get", json={
        "client_id": PLAID_CLIENT_ID,
        "secret": PLAID_SECRET,
        "access_token": access_token
    })
    return jsonify(response.json()), response.status_code

@app.route("/accounts", methods=["GET"])
def list_accounts():
    accounts = Account.query.all()
    return jsonify({
        "accounts": [{
            "id": acc.id,
            "name": acc.name,
            "type": acc.type,
            "subtype": acc.subtype,
            "mask": acc.mask,
            "official_name": acc.official_name,
            "balance": acc.balance
        } for acc in accounts]
    })

# New route for Plaid Link token creation
@app.route("/link/token/create", methods=["POST"])
def create_link_token():
    user = LinkTokenCreateRequestUser(client_user_id="unique-user-id")
    request = LinkTokenCreateRequest(
        products=[Products("transactions")],
        client_name="Budget Tracker",
        country_codes=[CountryCode('US')],
        language='en',
        user=user
    )
    response = api_client.link_token_create(request)
    return jsonify(response.to_dict()), 200

@app.route("/plaid/link", methods=["GET"])
def plaid_link_page():
    # Create the link token first
    user = LinkTokenCreateRequestUser(client_user_id="unique-user-id")
    request = LinkTokenCreateRequest(
        products=[Products("transactions")],
        client_name="Budget Tracker",
        country_codes=[CountryCode('US')],
        language='en',
        user=user
    )
    response = api_client.link_token_create(request)
    link_token = response['link_token']

    # Serve HTML page with embedded Plaid Link
    html = f"""
    <!DOCTYPE html>
    <html>
    <head>
      <title>Link Your Account</title>
      <script src="https://cdn.plaid.com/link/v2/stable/link-initialize.js"></script>
      <script>
        function openPlaid() {{
          var linkHandler = Plaid.create({{
            token: '{link_token}',
            onSuccess: function(public_token, metadata) {{
              fetch('/accounts/link', {{
                method: 'POST',
                headers: {{
                  'Content-Type': 'application/json'
                }},
                body: JSON.stringify({{public_token: public_token}})
              }})
              .then(response => {{
                if(response.ok) {{
                  alert('Account linked successfully!');
                }} else {{
                  response.text().then(text => alert('Failed to link account: ' + text));
                }}
              }})
              .catch(error => {{
                alert('Error during token exchange: ' + error.message);
                console.error(error);
              }});
            }},
            onExit: function(err, metadata) {{
              if(err) {{
                alert('Link exited with error: ' + err.display_message);
              }}
            }}
          }});
          linkHandler.open();
        }}
      </script>
    </head>
    <body>
      <button onclick="openPlaid()">Link Your Account</button>
    </body>
    </html>
    """
    return html

@app.route("/transactions", methods=["GET"])
def get_transactions():
    try:
        user_id = "unique-user-id"  # Replace with session auth
        user = User.query.get(user_id)
        if not user or not user.access_tokens:
            return jsonify({"error": "User not linked"}), 400

        end_date = datetime.now().date()
        start_date = end_date - timedelta(days=30)
        all_transactions = []

        account_map = {acc.id: acc.name for acc in Account.query.all()}

        for token_entry in user.access_tokens:
            access_token = token_entry.token
            request = TransactionsGetRequest(
                access_token=access_token,
                start_date=start_date,
                end_date=end_date,
                options=TransactionsGetRequestOptions(count=100, offset=0)
            )
            response: TransactionsGetResponse = api_client.transactions_get(request)
            for t in response['transactions']:
                acc_id = t["account_id"]
                acc_name = account_map.get(acc_id)
                if not acc_name:
                    print(f"Missing account name for account_id: {acc_id}")
                all_transactions.append({
                    "name": t["name"],
                    "date": t["date"],
                    "amount": t["amount"],
                    "category": (
                        t["personal_finance_category"]["primary"]
                        if t.get("personal_finance_category") and t["personal_finance_category"].get("primary")
                        else "Uncategorized"
                    ),
                    "account_name": account_map.get(t["account_id"], "Unknown Account")
                })

        return jsonify(all_transactions), 200
    except plaid.ApiException as e:
        return jsonify({"error": str(e)}), 500
    except Exception as e:
        print("Failed to retrieve transactions")
        print("User lookup for user_id:", user_id)
        if user:
            print("User found:", user.id)
            print("AccessTokens:", user.access_tokens)
        else:
            print("User not found")
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500


@app.route("/accounts/refresh", methods=["POST"])
def refresh_account_balances():
    try:
        user_id = "unique-user-id"  # Replace with session user ID as needed
        user = User.query.get(user_id)
        if not user or not user.access_tokens:
            return jsonify({"error": "User not linked"}), 400

        for token_entry in user.access_tokens:
            access_token = token_entry.token
            balance_request = AccountsBalanceGetRequest(access_token=access_token)
            balance_response = api_client.accounts_balance_get(balance_request)
            accounts = balance_response['accounts']

            for acc in accounts:
                account = Account.query.get(acc["account_id"])
                if account:
                    account.balance = acc["balances"].get("available", 0.0)
                    db.session.merge(account)

        db.session.commit()
        return jsonify({"message": "Balances refreshed"}), 200

    except plaid.ApiException as e:
        return jsonify({"error": str(e)}), 500
    except Exception as e:
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    with app.app_context():
        db.create_all()
        print("Database initialized. Tables:", db.metadata.tables.keys())
    app.run(host="0.0.0.0", port=5050, debug=True)
