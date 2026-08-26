# finance dashboard

A Flutter dashboard for balances, recurring bills, and upcoming paydays. The
screen currently runs in clearly labeled demo mode so it can be previewed
without Plaid credentials.

## Plaid setup

Plaid Link must be initialized with a short-lived link token created by a
trusted server. Never put Plaid client secrets in this Flutter app.

The client boundary is in `lib/plaid_service.dart`. Start your backend with an
endpoint that accepts `POST /api/plaid/link-token` and returns:

```json
{ "link_token": "link-sandbox-..." }
```

Run Flutter with the backend URL:

```text
flutter run --dart-define=PLAID_API_BASE_URL=https://your-api.example.com
```

### Local FastAPI backend

From the repository root, create a Python environment and install the backend
dependencies:

```text
python -m venv .venv
.venv\\Scripts\\activate
pip install -r backend/requirements.txt
copy backend/.env.example backend/.env
```

Set `PLAID_CLIENT_ID` and `PLAID_SECRET` in `backend/.env`, then start the API:

```text
uvicorn backend.main:app --reload --port 8000
```

For an Android emulator, the Flutter app uses `http://10.0.2.2:8000`; for a
physical device, use the computer's LAN IP instead. Do not add backend secrets
to the Flutter `.env` file or ship them as Flutter assets.

The sample backend creates the token using Plaid's `/link/token/create` endpoint
and exchanges the resulting public token with `/item/public_token/exchange`.
Before production, replace its in-memory access-token dictionary with encrypted
database storage, add user authentication, restrict CORS, and add endpoints for
balances, transactions, and income. Plaid data access should be authorized and
refreshed server-side.
